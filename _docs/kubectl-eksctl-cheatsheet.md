# kubectl & eksctl Cheat Sheet — Debugging & Operations on AWS EKS

General-purpose reference for debugging and operating Kubernetes on Amazon EKS. Replace `<namespace>`, `<cluster-name>`, `<pod>`, etc. with your values.

---

## 1. Quick goals → commands

| Goal | Command |
|------|---------|
| List pods in a namespace | `kubectl get pods -n <namespace>` |
| Why is this pod Pending / CrashLoopBackOff? | `kubectl describe pod <pod> -n <namespace>` → read **Events** |
| Stream app logs | `kubectl logs -n <namespace> <pod> -f` |
| Node cordoned (SchedulingDisabled)? | `kubectl get nodes` → `kubectl uncordon <node>` |
| Rolling restart a deployment | `kubectl rollout restart deployment/<name> -n <namespace>` |
| Get app URL from Ingress | `kubectl get ingress -n <namespace>` (column **ADDRESS**) |
| Who can access the cluster? | `kubectl get cm -n kube-system aws-auth -o yaml` |

---

## 2. kubectl — Logs (debugging runtime behavior)

**When to use:** App errors, crashes, what the process is doing. Always specify `-n <namespace>` for workload pods.

| What you want | Command | Notes |
|---------------|---------|--------|
| Logs for one pod | `kubectl logs -n <namespace> <pod>` | Last chunk of log output |
| Stream logs (follow) | `kubectl logs -n <namespace> <pod> -f` | Like `tail -f` |
| Logs from deployment (any pod) | `kubectl logs -n <namespace> deployment/<name>` | Picks current pod |
| Last N lines | `kubectl logs -n <namespace> <pod> --tail=100` | |
| Logs since time | `kubectl logs -n <namespace> <pod> --since=1h` | |
| Previous crashed container | `kubectl logs -n <namespace> <pod> --previous` | For CrashLoopBackOff |
| Specific container in pod | `kubectl logs -n <namespace> <pod> -c <container>` | Multi-container pods (e.g. sidecar) |

**EKS system components (often in `kube-system`):**

```bash
# AWS Load Balancer Controller (creates ALB/NLB from Ingress)
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller -f

# VPC CNI (aws-node)
kubectl logs -n kube-system -l k8s-app=aws-node -f

# CoreDNS
kubectl logs -n kube-system -l k8s-app=kube-dns -f
```

---

## 3. kubectl — Inspect resources (get & describe)

**When to use:** See status, find names, understand why something isn’t working. **Events** at the bottom of `describe` are the first place to look for scheduling/image/volume errors.

### 3.1 Get (list and status)

| What | Command | What to look at |
|------|---------|------------------|
| Pods in namespace | `kubectl get pods -n <namespace>` | **STATUS** (Running, Pending, CrashLoopBackOff, ImagePullBackOff), **READY** |
| Pods with node/IP | `kubectl get pods -n <namespace> -o wide` | **NODE**, **IP** |
| All namespaces | `kubectl get pods -A` | Find which ns a pod is in |
| By label | `kubectl get pods -n <namespace> -l app=<label>` | |
| Deployments | `kubectl get deploy -n <namespace>` | READY, UP-TO-DATE, AVAILABLE |
| Nodes | `kubectl get nodes` | STATUS (Ready, NotReady), **SchedulingDisabled** = cordoned |
| Ingress | `kubectl get ingress -n <namespace>` | **ADDRESS** = LB hostname (ALB/NLB) |
| Services | `kubectl get svc -n <namespace>` | CLUSTER-IP, EXTERNAL-IP, PORTS |
| Events (recent) | `kubectl get events -n <namespace> --sort-by='.lastTimestamp'` | Warning/Error, reason, message |
| All events | `kubectl get events -A --sort-by='.lastTimestamp'` | Cluster-wide |

### 3.2 Describe (details + Events)

| Resource | Command | Use for |
|----------|---------|--------|
| Pod | `kubectl describe pod <pod> -n <namespace>` | **Events** (Pending reason, pull errors, volume mount failures), restarts, limits |
| Node | `kubectl describe node <node>` | Capacity, allocatable, conditions, taints |
| Ingress | `kubectl describe ingress <name> -n <namespace>` | Backends, LB, TLS, why no ADDRESS |
| Deployment | `kubectl describe deploy <name> -n <namespace>` | Replicas, image, rollout status |
| Service | `kubectl describe svc <name> -n <namespace>` | Endpoints (which pods), ClusterIP |

**How to use Events:** At the bottom of `kubectl describe pod` you get lines like `Warning FailedScheduling`, `Failed Pull`, `FailedMount`. The **message** tells you the cause (e.g. insufficient CPU, image not found, PVC not bound).

### 3.3 Raw YAML/JSON (for image, volumes, full spec)

```bash
kubectl get pod <pod> -n <namespace> -o yaml
kubectl get pod <pod> -n <namespace> -o jsonpath='{.spec.containers[*].image}'
kubectl get deploy <name> -n <namespace> -o yaml
```

Use **get -o yaml** when you need the exact image, volume mount path, or resource limits. Fix issues in the **controller** (Deployment/StatefulSet), not the Pod—Pods are recreated from the controller.

---

## 4. kubectl — Debugging common pod issues

| Problem | What to run | What to check |
|---------|-------------|----------------|
| **Pending** | `kubectl describe pod <pod> -n <namespace>` | Events: insufficient CPU/memory, no node match (taints/tolerations), PVC not bound |
| **ImagePullBackOff** / **ErrImagePull** | `kubectl describe pod <pod> -n <namespace>` | Events: image name, pull secret, registry auth. Fix: `kubectl set image deployment/<name> <container>=<full-image>:<tag> -n <namespace>` or edit deployment |
| **CrashLoopBackOff** | `kubectl logs -n <namespace> <pod> --previous` then `describe pod` | App crash; logs show exit reason; describe shows restarts |
| **Pod stuck Terminating** | `kubectl get pod <pod> -n <namespace> -o yaml` | Look for `finalizers`; if a controller is gone, you may need to patch finalizers (advanced) |
| **Not Ready** (Readiness probe) | `kubectl logs -n <namespace> <pod>` | App not responding on probe port/path; fix app or probe |

**Fix ImagePullBackOff:** Set image on the **Deployment** (or StatefulSet), not the Pod. Use a **full image URL** (e.g. `123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:v1`).

```bash
kubectl set image deployment/<name> <container>=<full-image-url>:<tag> -n <namespace>
# or
kubectl edit deployment <name> -n <namespace>
```

---

## 5. kubectl — Nodes (cordon, uncordon, drain)

| Goal | Command |
|------|---------|
| List nodes, see status | `kubectl get nodes` |
| Why is node NotReady? | `kubectl describe node <node>` |
| Cordon (no new pods) | `kubectl cordon <node>` |
| Uncordon (allow scheduling) | `kubectl uncordon <node>` |
| Drain (evict pods for maintenance) | `kubectl drain <node> --ignore-daemonsets --delete-emptydir-data` |

---

## 6. kubectl — Rollouts and restarts

| Goal | Command |
|------|---------|
| Rolling restart | `kubectl rollout restart deployment/<name> -n <namespace>` |
| Rollout status | `kubectl rollout status deployment/<name> -n <namespace>` |
| Rollout history | `kubectl rollout history deployment/<name> -n <namespace>` |
| Undo last rollout | `kubectl rollout undo deployment/<name> -n <namespace>` |
| Scale to zero | `kubectl scale deployment/<name> -n <namespace> --replicas=0` |
| Scale up | `kubectl scale deployment/<name> -n <namespace> --replicas=3` |
| Restart all pods in namespace (e.g. after config change) | `kubectl delete pods -n <namespace> -l app=<label>` or `kubectl delete pods -n <namespace> --field-selector=status.phase=Running` (then let Deployment recreate) |

---

## 7. kubectl — Apply, create, and wait

```bash
kubectl apply -f <file-or-dir>
kubectl create namespace <namespace>
kubectl wait --for=condition=available deployment/<name> -n <namespace> --timeout=120s
kubectl label namespace <namespace> <key>=<value>
kubectl set env deployment/<name> KEY=value -n <namespace>
```

---

## 8. EKS / AWS — Cluster and kubeconfig

**Connect to the cluster:**

```bash
aws eks update-kubeconfig --region <region> --name <cluster-name>
kubectl get nodes   # verify
```

**"Connection refused" to localhost (8080, 8888, etc.):** kubectl has no cluster in kubeconfig, so it tries localhost. Run `aws eks update-kubeconfig --region <region> --name <cluster-name>` (use your cluster name; list with `aws eks list-clusters --region <region>`), then retry.

**AWS CLI (EKS):**

```bash
aws eks describe-cluster --name <cluster-name> --region <region>
aws eks list-clusters --region <region>
aws eks list-nodegroups --cluster-name <cluster-name> --region <region>
```

**IAM and cluster access (EKS uses `aws-auth` ConfigMap):**

```bash
# See who is mapped (role ARN → user/group)
kubectl get configmap aws-auth -n kube-system -o yaml
```

Adding or debugging IAM access is done via **eksctl** (see below) or by editing `aws-auth` (advanced).

---

## 9. eksctl — Cluster and node groups (lifecycle)

```bash
# Create cluster from config file
eksctl create cluster -f cluster.yaml

# List / create / delete node groups
eksctl get nodegroups --cluster <cluster-name>
eksctl create nodegroup -f nodegroup.yaml
eksctl delete nodegroup --cluster <cluster-name> <nodegroup-name>

# Fargate
eksctl create fargateprofile -f fargate-profile.yaml
eksctl get fargateprofile --cluster <cluster-name>
```

---

## 10. eksctl — OIDC and IRSA (IAM roles for service accounts)

Pods use an IAM role via IRSA (no long-lived keys). OIDC must be associated once per cluster.

```bash
# One-time per cluster
eksctl utils associate-iam-oidc-provider --cluster <cluster-name> --approve

# Create IAM service account (role + K8s SA)
eksctl create iamserviceaccount \
  --name <service-account-name> \
  --namespace <namespace> \
  --cluster <cluster-name> \
  --attach-policy-arn <policy-arn> \
  --approve

# List IRSA roles
eksctl get iamserviceaccount --cluster <cluster-name>
```

**Debugging IRSA:** Pod not getting credentials? Check: (1) ServiceAccount has `eks.amazonaws.com/role-arn` annotation, (2) OIDC provider exists for cluster, (3) trust policy on the IAM role allows that OIDC and the K8s SA.

---

## 11. eksctl — IAM identity mapping (human/CI access to cluster)

Maps an IAM role or user to a Kubernetes user/group so they can use `kubectl` (e.g. CodeBuild, GitHub Actions).

```bash
eksctl create iamidentitymapping \
  --cluster <cluster-name> \
  --arn <iam-role-or-user-arn> \
  --username <kubernetes-username> \
  --group system:masters

# List mappings
eksctl get iamidentitymapping --cluster <cluster-name>
```

**Debugging “access denied”:** Run `kubectl get cm aws-auth -n kube-system -o yaml` and confirm the role ARN is in the mapRoles section (or add it via `eksctl create iamidentitymapping`).

---

## 12. Debugging flows (general)

| Scenario | Steps |
|----------|--------|
| **Pod not starting** | `kubectl get pods -n <ns>` → `kubectl describe pod <pod> -n <ns>` (Events) → fix image/resources/volumes on Deployment if needed. |
| **App not reachable** | `kubectl get ingress -n <ns>` (ADDRESS?) → `kubectl get svc -n <ns>` → `kubectl get endpoints -n <ns>` (pods behind Svc?) → `kubectl logs -n <ns> deployment/<name>`. |
| **Ingress has no ADDRESS** | Check AWS Load Balancer Controller: `kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller` and `kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller -f`. Controller needs IRSA and subnet tags for ALB. |
| **Node NotReady** | `kubectl describe node <node>` (conditions); check VPC CNI: `kubectl get pods -n kube-system -l k8s-app=aws-node` and their logs. |
| **“Access denied” to API** | `kubectl get cm aws-auth -n kube-system -o yaml`; ensure your IAM principal is mapped (eksctl get iamidentitymapping / create iamidentitymapping). |
| **Need to restart system component** | Restart VPC CNI: `kubectl delete pods -n kube-system -l k8s-app=aws-node`. Restart LBC: delete pods with label `app.kubernetes.io/name=aws-load-balancer-controller`. |

---

## 13. Handy flags and shortcuts

| Flag | Meaning |
|------|---------|
| `-n <namespace>` / `--namespace=<namespace>` | Namespace (use for all workload commands) |
| `-A` / `--all-namespaces` | All namespaces |
| `-o wide` | Extra columns (e.g. node, IP) |
| `-o yaml` / `-o json` | Raw output |
| `-l key=value` | Label selector |
| `--tail=N` | Last N lines (logs) |
| `--since=1h` | Logs from last hour |
| `-f` | Follow (stream) |
| `--previous` | Previous container instance (crashed) |
| `--context=<name>` | Use specific kubeconfig context |

---

## 14. Prerequisites

- **kubectl:** Install and add to PATH; then `aws eks update-kubeconfig --region <region> --name <cluster-name>`.
- **eksctl:** Install from [eksctl.io](https://eksctl.io) or your repo’s install script.
- **AWS CLI:** Configured with credentials that can call EKS and IAM (`aws sts get-caller-identity`).

For more context and repo-specific examples, see `_docs/kubectl-eksctl-logging-troubleshooting.md`.
