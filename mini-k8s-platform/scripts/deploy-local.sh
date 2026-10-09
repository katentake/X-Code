#!/usr/bin/env bash
set -euo pipefail

# One-command local deploy: Minikube + local images + Helm chart.
# Uses plain Kubernetes Secrets (secrets.enabled=true), so it needs neither Argo CD
# nor the Sealed Secrets controller. For the GitOps path, see ../README.md.
#
# Usage: mini-k8s-platform/scripts/deploy-local.sh
# Optional env: PAYMENT_API_KEY (defaults to a dummy local key)

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CHART="$REPO_ROOT/mini-k8s-platform/deploy/apps/mini-app/charts/backend"
RELEASE="mini-production-platform"   # order-service's REDIS_HOST expects this release name
NAMESPACE="production"
ORDER_IMAGE="mini-order:v1.0.4"
PAYMENT_IMAGE="mini-payment:v1.0.0"

for cmd in minikube kubectl helm docker openssl; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "Missing required tool: $cmd"; exit 1; }
done

echo "==> Starting Minikube"
minikube status >/dev/null 2>&1 || minikube start --cpus=4 --memory=6g
minikube addons enable ingress
minikube addons enable metrics-server   # HPA needs CPU metrics

echo "==> Building images inside Minikube's Docker daemon (chart uses imagePullPolicy: Never)"
eval "$(minikube docker-env)"
docker build -t "$ORDER_IMAGE" "$REPO_ROOT/online-payment/order-service"
docker build -t "$PAYMENT_IMAGE" "$REPO_ROOT/online-payment/payment-service"

# Reuse the existing Postgres password on re-runs: the database keeps the password
# it was initialised with on its PVC, so generating a new one would break auth.
PG_PASSWORD="$(kubectl -n "$NAMESPACE" get secret postgres-secret \
  -o jsonpath='{.data.POSTGRES_PASSWORD}' 2>/dev/null | base64 --decode || true)"
PG_PASSWORD="${PG_PASSWORD:-$(openssl rand -hex 16)}"

echo "==> Installing Helm release $RELEASE into namespace $NAMESPACE"
helm upgrade --install "$RELEASE" "$CHART" \
  --namespace "$NAMESPACE" --create-namespace \
  --set secrets.enabled=true \
  --set secrets.postgres.user=app \
  --set-string secrets.postgres.password="$PG_PASSWORD" \
  --set-string secrets.payment.apiKey="${PAYMENT_API_KEY:-local-dummy-key}" \
  --set order.image="$ORDER_IMAGE" \
  --set payment.image="$PAYMENT_IMAGE"

echo "==> Waiting for workloads"
kubectl -n "$NAMESPACE" rollout status statefulset/postgres-db --timeout=180s
kubectl -n "$NAMESPACE" rollout status deployment/payment-service --timeout=180s
kubectl -n "$NAMESPACE" rollout status deployment/order-service --timeout=180s

cat <<EOF

Deployed. Try it:
  kubectl -n $NAMESPACE port-forward svc/order-service 8081:80 &
  kubectl -n $NAMESPACE port-forward svc/payment-service 8082:80 &
  curl localhost:8081/health          # order service + DB connectivity
  curl -X POST localhost:8081/        # create an order (writes to Postgres)
  curl localhost:8082/pay             # payment service
EOF
