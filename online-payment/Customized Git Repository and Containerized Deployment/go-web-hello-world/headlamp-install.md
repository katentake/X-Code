# Headlamp Installation & Auth
1. Deploy: kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/headlamp/main/kubernetes-headlamp.yaml
2. Service: Patched to NodePort 31081 in kube-system namespace.
3. RBAC: Created 'headlamp-admin' ServiceAccount and bound to 'cluster-admin'.
4. Token: Generated via 'kubectl create token headlamp-admin -n kube-system'.
5. Access: Port forwarded 31081 in VirtualBox, accessed via https://localhost:31081.

---
### Note on TLS/SSL (Troubleshooting)
Headlamp serves traffic over HTTPS by default on port 4466. When accessing via https://localhost:31081, browsers will show a certificate warning due to the self-signed cert. This is expected in a local dev environment.

**How to proceed:**
1. Click **"Advanced"** -> **"Proceed to localhost (unsafe)"**.
2. If the "Proceed" button is missing (Chrome HSTS), type `thisisunsafe` directly on your keyboard while the page is focused, and it will bypass the warning automatically.
---