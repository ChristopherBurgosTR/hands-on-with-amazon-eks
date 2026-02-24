# kubectl and eksctl Command Reference – Logging & Troubleshooting

A single reference for all **kubectl** and **eksctl** commands used in this repo, plus recommended commands for **logging** and **troubleshooting** so you can track and debug your EKS cluster and workloads.

> **Namespace for app pods:** Always use `-n development` when describing or logging the front-end and other app pods (front-end, inventory-api, renting-api, resource-api, clients-api).

---

## Quick reference: goals → commands

| Goal | Command |
|------|---------|
| List pods in development | `kubectl get pods -n development` |
| Why is this pod Pending? | `kubectl describe pod <POD_NAME> -n development` → read **Events** at the bottom |
| App logs (pod already Running) | `kubectl logs -n development <POD_NAME>` |
| Nodes cordoned? | `kubectl get nodes` → if **SchedulingDisabled**, run `kubectl uncordon <NODE_NAME>` |
| Restart a deployment | `kubectl rollout restart deployment/<DEPLOY_NAME> -n development` |

---

## 1. Logging (viewing application and system logs)

These commands are **not** in the repo today but you should use them for debugging. Add them to your workflow.

| Command | Purpose |
|--------|---------|
| `kubectl logs -n <namespace> <pod-name>` | View logs for a single pod (e.g. `development`, `kube-system`). |
| `kubectl logs -n <namespace> <pod-name> -f` | Stream logs (follow) for a pod. |
| `kubectl logs -n <namespace> deployment/<deployment-name>` | Logs from the current pod(s) of a deployment. |
| `kubectl logs -n <namespace> <pod-name> -c <container-name>` | Logs from a specific container in a pod (e.g. app vs sidecar). |
| `kubectl logs -n <namespace> <pod-name> --previous` | Logs from the previous (crashed) container instance. |

**Examples for this project:**

```bash
# App logs in development
kubectl logs -n development deployment/front-end-development-acg-front-end -f
kubectl logs -n development deployment/inventory-api-development-acg-inventory-api -f

# System / controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller -f
kubectl logs -n kube-system -l k8s-app=aws-node  # VPC CNI (aws-node)
```

---

## 2. Troubleshooting (inspection and debugging)

### 2.1 Workload and pod inspection (from this repo)

| Command | Where used | Purpose |
|--------|------------|---------|
| `kubectl get ingress -n development front-end-development-ingress \| grep bookstore \| awk '{print $3}'` | chapter-2.sh | Get front-end app URL (Ingress address). |
| `kubectl get ingresses` | _docs/communication-flow.md | See Ingress **Address** (ALB) set by Load Balancer Controller. |
| `kubectl get pods -n development \| grep Running \| awk '{print $1}'` | chapter-6.sh | List running pods in `development` (e.g. for restart). |
| `kubectl get cm -n kube-system aws-auth -o yaml` | chapter-5.sh | Inspect **aws-auth** ConfigMap (IAM access to cluster). |
| `kubectl get nodes` | All 5 CodeBuild buildspecs | Verify cluster connectivity after `update-kubeconfig`. |
| `kubectl get pods -n kube-system -l k8s-app=aws-node` | cni/setup-irsa.sh (commented) | Check VPC CNI (aws-node) pods after IRSA. |

### 2.2 Recommended troubleshooting commands (add to your runbook)

| Command | Purpose |
|--------|---------|
| `kubectl get pods -n development` | List pods in development; check READY and STATUS. |
| `kubectl describe pod <POD_NAME> -n development` | Why is this pod Pending? Check **Events** at the bottom. |
| `kubectl describe ingress -n development <ingress-name>` | Ingress status, backend, ALB. |
| `kubectl get events -n <namespace> --sort-by='.lastTimestamp'` | Recent cluster events. |
| `kubectl get nodes` | Node status and version; if **SchedulingDisabled**, node is cordoned. |
| `kubectl uncordon <NODE_NAME>` | Allow scheduling on a cordoned node (after `kubectl get nodes`). |
| `kubectl get cm -n kube-system aws-auth -o yaml` | Debug “access denied” / IAM mapping. |

### 2.2a Pod YAML and image inspection (cheat sheet)

| Command | Purpose |
|--------|---------|
| `kubectl get pod <full-pod-name> -o yaml` | Get full YAML of a pod (use exact name from `kubectl get pods`, e.g. `finalizer-cleanup-controller-79658bd4f7-r9d6n`). |
| `kubectl get pod -l app=<label> -o yaml` | Get YAML for pod(s) matching a label (e.g. `app=finalizer-cleanup-controller`). |
| `kubectl get pods -A` | List all pods in all namespaces (to find full pod name). |
| `kubectl describe pod <pod-name>` | Summary + Events; use when you don't need raw YAML. |

**Identifying the image that needs to be updated:** In the pod YAML, look at:

- **`spec.containers[].image`** — the image the pod is *configured* to use (e.g. `finalizer-cleanup-controller:latest`).
- **`status.containerStatuses[].state.waiting.message`** — the pull error (e.g. "pull access denied", "repository does not exist"). Kubernetes resolves an image without a registry to `docker.io/library/<name>:<tag>`, which often fails for custom images.

**To fix ImagePullBackOff:** Update the **Deployment** (not the pod), so new pods use a pullable image:

```bash
# Option 1: Edit the deployment
kubectl edit deployment <deployment-name>

# Option 2: Set image directly
kubectl set image deployment/<deployment-name> <container-name>=<full-image-url>:<tag>
```

Set `spec.template.spec.containers[].image` to a **full registry URL** your cluster can pull from (e.g. ECR: `<account-id>.dkr.ecr.<region>.amazonaws.com/finalizer-cleanup-controller:latest`). Build and push your image to that registry first.

### 2.3 Restarts and recovery

| Command | Where used | Purpose |
|--------|------------|---------|
| `kubectl rollout restart deployment/<DEPLOY_NAME> -n development` | — | Restart a deployment (rolling restart; preferred for a single app). |
| `kubectl delete pods -n development $(kubectl get pods -n development \| grep Running \| awk '{print $1}')` | chapter-6.sh | Restart all running pods in `development` (e.g. after App Mesh so new pods get sidecars). |
| `kubectl delete pods -n kube-system -l k8s-app=aws-node` | cni/setup-irsa.sh | Restart VPC CNI pods so they use new IRSA. |
| `kubectl scale deploy -n development resource-api-development-acg-resource-api --replicas=0` | chapter-6.sh (commented) | Example scale-down for testing. |

---

## 3. eksctl – Cluster and IAM lifecycle

### 3.1 Cluster and node groups

| Command | Where used | Purpose |
|--------|------------|---------|
| `eksctl create cluster -f Infrastructure/eksctl/01-initial-cluster/cluster.yaml` | chapter-1.sh | Create initial EKS cluster. |
| `eksctl create nodegroup -f cluster.yaml` (from 02-spot-instances) | chapter-4.sh | Create spot instance node group. |
| `eksctl get nodegroups --cluster eks-acg` | chapter-4.sh | List node groups. |
| `eksctl delete nodegroup --cluster eks-acg eks-node-group` | chapter-4.sh | Delete on-demand node group (before spot). |
| `eksctl create nodegroup -f cluster.yaml` (03-managed-nodes) | chapter-4.sh (commented) | Alternative: managed nodes. |
| `eksctl delete nodegroup --cluster eks-acg eks-node-group-spot-instances` | chapter-4.sh (commented) | Delete spot node group. |
| `eksctl create fargateprofile -f cluster.yaml` | chapter-4.sh (commented) | Create Fargate profile (04-fargate). |

### 3.2 OIDC and IAM service accounts (IRSA)

| Command | Where used | Purpose |
|--------|------------|---------|
| `eksctl utils associate-iam-oidc-provider --cluster=eks-acg --approve` | chapter-3.sh, load-balancer-controller/create-irsa.sh | Associate OIDC provider for IRSA. |
| `eksctl create iamserviceaccount --name <name> ...` | chapter-3.sh, chapter-5.sh, chapter-6.sh, create-irsa.sh (LB, external-dns, cni), configure-app-mesh.sh | Create IRSA for: resources-api, renting-api, inventory-api, clients-api, front-end, aws-load-balancer-controller, external-dns, aws-node (CNI), appmesh-controller. |
| `eksctl get iamserviceaccount --cluster eks-acg` | chapter-6.sh (commented) | List IAM service accounts (e.g. find appmesh-controller role). |

### 3.3 IAM identity mapping (CodeBuild → EKS)

| Command | Where used | Purpose |
|--------|------------|---------|
| `eksctl create iamidentitymapping --cluster eks-acg --arn <role_arn> --username <name> --group system:masters` | chapter-5.sh (x5) | Map CodeBuild IAM roles to cluster access (inventory-api, renting-api, resource-api, clients-api, front-end deployment). |

---

## 4. kubectl – Apply, create, wait, set, label

| Command | Where used | Purpose |
|--------|------------|---------|
| `kubectl wait --for=condition=available deployment/aws-load-balancer-controller -n kube-system --timeout=120s` | chapter-2.sh | Wait for Load Balancer Controller before external-dns. |
| `kubectl create namespace development` | chapter-2.sh | Create `development` namespace (idempotent). |
| `kubectl apply -f development-mesh.yaml` (Infrastructure/service-mesh) | chapter-6.sh | Apply App Mesh development mesh. |
| `kubectl label namespace development mesh=development-mesh` | chapter-6.sh | Label namespace for App Mesh. |
| `kubectl label namespace development "appmesh.k8s.aws/sidecarInjectorWebhook"=enabled` | chapter-6.sh | Enable sidecar injection for `development`. |
| `kubectl apply -k "https://github.com/aws/eks-charts/stable/appmesh-controller/crds?ref=master"` | configure-app-mesh.sh | Apply App Mesh controller CRDs. |
| `kubectl set env ds aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true` | cni/setup.sh | Enable custom network config for VPC CNI. |
| `kubectl set env ds aws-node -n kube-system ENI_CONFIG_LABEL_DEF=...` | cni/setup.sh | Set ENI label for CNI. |

---

## 5. Quick troubleshooting flow

1. **App not responding / wrong URL**  
   - `kubectl get ingress -n development` → check **Address** (ALB).  
   - `kubectl get pods -n development` → check pod STATUS and READY.  
   - `kubectl describe ingress -n development <ingress-name>` and `kubectl logs -n development deployment/<name> -f`.

2. **“Access denied” or CodeBuild can’t talk to cluster**  
   - `kubectl get cm -n kube-system aws-auth -o yaml`  
   - Confirm `eksctl create iamidentitymapping` was run for the deployment role.

3. **Load Balancer / Ingress not created**  
   - `kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller`  
   - `kubectl logs -n kube-system deployment/aws-load-balancer-controller -f`.

4. **Pods not getting new config (e.g. App Mesh sidecar)**  
   - Restart: `kubectl delete pods -n development $(kubectl get pods -n development -o name)` or the chapter-6 pattern for running pods only.

5. **VPC CNI / networking issues**  
   - `kubectl get pods -n kube-system -l k8s-app=aws-node`  
   - After IRSA change: `kubectl delete pods -n kube-system -l k8s-app=aws-node`.

---

## 6. Prerequisites (from this repo)

- **eksctl:** `scripts-by-chapter/install-prerequisites.sh` or `prepare-cloud-shell.sh` (CloudShell).  
- **kubectl:** Installed in CodeBuild via buildspec (curl from S3, chmod, mv). For local/CloudShell, install kubectl and run `aws eks update-kubeconfig --region <region> --name eks-acg`.

All paths and script names above are relative to the repo root: `hands-on-with-amazon-eks`.
