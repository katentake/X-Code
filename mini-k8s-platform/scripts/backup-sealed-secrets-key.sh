#!/usr/bin/env bash
set -euo pipefail

# 备份 sealed-secrets-controller 自动生成的私钥。
# 用法: ./backup-sealed-secrets-key.sh
# 详见 mini-k8s-platform/docs/sealed-secrets-key-management.md

OUT="sealed-secrets-master-key-backup.yaml"

kubectl get secret -n kube-system \
  -l sealedsecrets.bitnami.com/sealed-secrets-key \
  -o yaml > "$OUT"

echo "✅ 私钥已备份到 $OUT"
echo "⚠️  该文件已在 .gitignore 中，绝不要提交到 Git。"
echo "⚠️  请立刻把它移到密码管理器或离线加密存储中，然后从本机删除明文副本。"
