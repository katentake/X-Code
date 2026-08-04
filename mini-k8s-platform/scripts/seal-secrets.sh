#!/usr/bin/env bash
set -euo pipefail

# 把明文 Secret 模板加密成可以安全提交到 Git 的 SealedSecret。
#
# 前提:
#   1. sealed-secrets-controller 已经通过 mini-k8s-platform/argocd/sealed-secrets-app.yaml 装好并 Ready
#   2. 已安装 kubeseal CLI: https://github.com/bitnami-labs/sealed-secrets#installation
#   3. 本地存在明文源文件（从未提交到 Git，已在 .gitignore 里）:
#        online-payment/postgres/k8s/secret.yaml
#        online-payment/payment-service/k8s/secret.yaml
#
# 用法:
#   ./seal-secrets.sh default        # 独立 manifest 走 kubectl apply 的场景（namespace: default）
#   ./seal-secrets.sh production     # Helm chart 经 Argo CD 部署的场景（argo-app.yaml 里的目标 namespace）

NAMESPACE="${1:?用法: $0 <namespace>，例如 default 或 production}"
CONTROLLER_NAMESPACE="kube-system"
CONTROLLER_NAME="sealed-secrets-controller"

command -v kubeseal >/dev/null 2>&1 || {
  echo "请先安装 kubeseal CLI: https://github.com/bitnami-labs/sealed-secrets#installation"
  exit 1
}

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PG_SRC="$REPO_ROOT/online-payment/postgres/k8s/secret.yaml"
PAY_SRC="$REPO_ROOT/online-payment/payment-service/k8s/secret.yaml"

for f in "$PG_SRC" "$PAY_SRC"; do
  [ -f "$f" ] || { echo "找不到 $f —— 需要先本地创建明文 Secret 模板（不要提交）"; exit 1; }
done

TMP_PG="$(mktemp)"
TMP_PAY="$(mktemp)"
trap 'rm -f "$TMP_PG" "$TMP_PAY"' EXIT

sed "s/namespace: default/namespace: ${NAMESPACE}/" "$PG_SRC" > "$TMP_PG"
sed "s/namespace: default/namespace: ${NAMESPACE}/" "$PAY_SRC" > "$TMP_PAY"

kubeseal --controller-namespace "$CONTROLLER_NAMESPACE" --controller-name "$CONTROLLER_NAME" \
  --format yaml < "$TMP_PG" > "sealed-postgres-secret.${NAMESPACE}.yaml"

kubeseal --controller-namespace "$CONTROLLER_NAMESPACE" --controller-name "$CONTROLLER_NAME" \
  --format yaml < "$TMP_PAY" > "sealed-payment-secret.${NAMESPACE}.yaml"

cat <<EOF

✅ 生成完毕:
   sealed-postgres-secret.${NAMESPACE}.yaml
   sealed-payment-secret.${NAMESPACE}.yaml

接下来把里面 spec.encryptedData 的内容，分别贴到:
  - namespace=default   -> online-payment/postgres/k8s/sealed-secret.yaml
                            online-payment/payment-service/k8s/sealed-secret.yaml
  - namespace=production -> mini-k8s-platform/deploy/apps/mini-app/charts/backend/templates/sealed-secrets.yaml

替换掉里面的 REPLACE_WITH_KUBESEAL_OUTPUT 占位符，然后就可以提交到 Git 了。
用完可以删掉这两个临时生成的 sealed-*.${NAMESPACE}.yaml 文件。
EOF
