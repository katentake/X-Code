# Sealed Secrets：加密密钥管理

## 密钥是怎么来的

`sealed-secrets-controller` 首次启动时会自动生成一个 RSA 密钥对，私钥以
`Secret` 的形式保存在它自己所在的命名空间（`kube-system`），带有标签
`sealedsecrets.bitnami.com/sealed-secrets-key=active`。

- `kubeseal` 只需要**公钥**就能加密（`kubeseal --fetch-cert` 或直接连控制器）。
- 只有集群里的控制器持有对应的**私钥**，才能把 `SealedSecret` 还原成真正的 `Secret`。
- 因此加密后的 `SealedSecret` YAML 可以安全提交到 Git —— 没有私钥，密文没有任何意义。

## 真正的风险：私钥从未离开集群

这个私钥**只存在于集群里**。如果控制器所在的命名空间被删除、集群被重建、或者
存储卷丢失，而你没有单独备份过这个私钥，后果是：

> 所有已经加密提交到 Git 的 `SealedSecret` 会永久无法解密，必须逐个用新密钥重新加密。

这就是目前这套配置缺的一环——控制器装上了，但没人备份过它的私钥。

## 修复：备份私钥（一次性 + 定期）

控制器装好、Pod 就绪后执行：

```bash
mini-k8s-platform/scripts/backup-sealed-secrets-key.sh
```

它会把私钥 Secret 导出到 `sealed-secrets-master-key-backup.yaml`。**这个文件已经在
根目录 `.gitignore` 里**，绝对不要手动 `git add -f` 它。把它加密后放进密码管理器
（1Password/Bitwarden 的文件附件均可）或离线保管的地方，不要留在这台机器的明文磁盘上。

建议：

- 每次控制器版本升级、或怀疑私钥可能已泄露时，重新执行一次备份。
- 至少保留两份离线拷贝（比如密码管理器 + 一份加密 U 盘），避免单点丢失。

## 恢复：集群重建后找回旧密钥

如果集群需要重建，在重新部署 `sealed-secrets-controller` **之前**：

```bash
kubectl apply -f sealed-secrets-master-key-backup.yaml
kubectl delete pod -n kube-system -l app.kubernetes.io/name=sealed-secrets
```

控制器重启时会发现命名空间里已经有一个标记为 `active` 的密钥 Secret，直接复用它，
而不是生成新的一把——这样所有历史上加密提交到 Git 的 `SealedSecret` 依然能正常解密。

如果没有备份就重建了集群，唯一的出路是：删除所有旧的 `SealedSecret` 清单，用新密钥
（`scripts/seal-secrets.sh`）把明文重新加密一遍，再提交。

## 密钥轮换

控制器默认每 30 天自动生成一把新的 active 密钥，但会保留旧密钥用于解密用旧密钥加密
过的 `SealedSecret`（除非手动删除旧密钥 Secret）。正常情况下不需要手动干预；只有在
明确怀疑私钥泄露时，才需要参考官方文档强制轮换并重新加密所有 Secret：
https://github.com/bitnami-labs/sealed-secrets#secret-rotation
