# SRE Hands-on Project Deliverables

This repository contains the completion of all tasks for the SRE interview project, including system administration, containerization, Kubernetes orchestration, and environment persistence.

## 📋 Task Summary & Navigation

| Task | Description | Status |
| :--- | :--- | :--- |
| **Task 1-2** | Ubuntu System Upgrade & Docker Engine Installation | ✅ Done |
| **Task 3-4** | Gogs Deployment & Repository Initialization | ✅ Done |
| **Task 5** | Single Node Kubernetes (Kind) Setup | ✅ Done |
| **Task 6-7** | Golang Web App Development & Docker Optimization (<10MB) | ✅ Done |
| **Task 8-9** | K8s Deployment & Headlamp Dashboard Integration | ✅ Done |
| **Task 10** | **Final Environment Persistence & Docker Hub Push** | ✅ Done |

---

## 🛠 Technical Implementation Details

### 1. Kubernetes Cluster & Application Deployment
- **Infrastructure**: Managed via `kind`. Cluster configuration is stored in `kubeconfig`.
- **Go Application**:
    - **Optimized Image**: `go-app:optimized` (Size: ~7MB), built using multi-stage builds.
    - **K8s Service**: Exposed via NodePort `31080`.
    - **Fixes**: Resolved OTEL DNS resolution issues by setting `OTEL_TRACES_EXPORTER: "none"` in `deployment.yaml`.

### 2. Kubernetes Dashboard (Headlamp)
Headlamp is deployed in the `kube-system` namespace.
- **Service Type**: NodePort `31081`.
- **Internal Port**: 4466 (HTTPS).
- **Access Strategy**: Due to `kind` network isolation, accessed via:
  ```bash
  kubectl port-forward -n kube-system svc/headlamp 31081:4466 --address 0.0.0.0

Auth: RBAC configured with headlamp-admin ServiceAccount. Token generated via kubectl create token.

3. Task 10: Gogs Persistence & Migration (Final Delivery)
The goal was to create a "single-command" recovery image containing all configurations and git data.

Step 1: Data Extraction
Identified the Gogs persistence layer via docker inspect and backed up the host bind-mount:
sudo cp -r /root/gogs/data/* ~/go-web-hello-world/gogs-data-backup/

Step 2: Custom Image Construction
Created a specialized Dockerfile.gogs to bake the data into the image:
FROM gogs/gogs:latest
COPY gogs-data-backup/ /data/
RUN chown -R git:git /data

Step 3: Registry Submission
Image Tag: katentake521/gogs:v0.1

Docker Hub: katentake521/gogs

🚀 How to Run the Environment
To review my work, simply run the following command on any machine with Docker installed:
docker run -d --name gogs-final \
  -p 3100:3000 \
  -p 2222:22 \
  katentake521/gogs:v0.1

Access Information:

URL: http://localhost:3100

Credentials: Username: root | Password: 123456

Contents: You will find the demo/go-web-hello-world repository with all manifests, Dockerfiles, and documentation.

📝 Troubleshooting & Notes
SSL Issues: Headlamp uses self-signed certs. If Chrome blocks access, type thisisunsafe on the warning page to proceed.

Port Forwarding: In the local kind environment, kubectl port-forward is used as the primary ingress method for the VM host.

Verification Success:
Confirmed by running docker run without any volume mounts; the container successfully loaded all pre-existing users and repositories from the internal /data layer.

### Testing: remove the old image and pull and ran image from docker hub:
docker run -d \
  --name gogs-final \
  -p 3100:3000 \
  -p 10022:22 \
  katentake521/gogs:v0.1

### test port 10022 connection status:
ssh -p 10022 git@localhost

### docker hub image path:
https://hub.docker.com/repository/docker/katentake521/gogs/tags/v0.1/sha256-f988bac0a276d26ea076ee923f1789575f535a640a3845f9b1df21da1059935d