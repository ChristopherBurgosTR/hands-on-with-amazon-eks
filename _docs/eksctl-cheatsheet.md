# eksctl Cheat Sheet — EKS Cluster & IAM

Reference for **eksctl** commands: install (bash), cluster and node group lifecycle, OIDC/IRSA, and IAM identity mapping. Replace `<cluster-name>`, `<nodegroup-name>`, etc. with your values.

---

## 1. Install eksctl (Bash)

**Option A — Latest release (Linux/macOS, amd64 or arm64):**

```bash
# Detect architecture and download latest
EKSCTL_ARCH=amd64
[ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "arm64" ] && EKSCTL_ARCH=arm64
curl -sL "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_${EKSCTL_ARCH}.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
chmod +x /usr/local/bin/eksctl
eksctl version
```

**Option B — Install to a user directory (no sudo, e.g. CloudShell):**

```bash
BIN_DIR="${BIN_DIR:-$HOME/bin}"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

EKSCTL_ARCH=amd64
[ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "arm64" ] && EKSCTL_ARCH=arm64
curl -sL "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_${EKSCTL_ARCH}.tar.gz" | tar xz -C /tmp
mv /tmp/eksctl "$BIN_DIR/"
chmod +x "$BIN_DIR/eksctl"
eksctl version
echo "Add to PATH: export PATH=\"$BIN_DIR:\$PATH\""
```

**Option C — Specific version (e.g. v0.147.0):**

```bash
EKSCTL_VER="v0.147.0"
EKSCTL_ARCH=amd64
[ "$(uname -m)" = "aarch64" ] || [ "$(uname -m)" = "arm64" ] && EKSCTL_ARCH=arm64
curl -sL "https://github.com/weaveworks/eksctl/releases/download/${EKSCTL_VER}/eksctl_$(uname -s)_${EKSCTL_ARCH}.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
chmod +x /usr/local/bin/eksctl
eksctl version
```

**Check install:**

```bash
command -v eksctl && eksctl version
```

**Docs:** [eksctl.io](https://eksctl.io) — installation and examples.

---

## 2. Cluster and node groups (lifecycle)

**Create cluster from YAML:**

```bash
eksctl create cluster -f cluster.yaml
```

**Node groups:**

```bash
# List node groups
eksctl get nodegroups --cluster <cluster-name>

# Create node group from YAML
eksctl create nodegroup -f nodegroup.yaml

# Delete node group
eksctl delete nodegroup --cluster <cluster-name> <nodegroup-name>
```

**Fargate:**

```bash
eksctl create fargateprofile -f fargate-profile.yaml
eksctl get fargateprofile --cluster <cluster-name>
```

**Delete cluster (and default node groups):**

```bash
eksctl delete cluster --name <cluster-name>
```

---

## 3. OIDC and IRSA (IAM roles for service accounts)

Pods assume an IAM role via IRSA (no long-lived keys). OIDC must be associated **once per cluster**.

**Associate OIDC provider (one-time per cluster):**

```bash
eksctl utils associate-iam-oidc-provider --cluster <cluster-name> --approve
```

**Create IAM service account (role + Kubernetes ServiceAccount):**

```bash
eksctl create iamserviceaccount \
  --name <service-account-name> \
  --namespace <namespace> \
  --cluster <cluster-name> \
  --attach-policy-arn <policy-arn> \
  --approve
```

**List IRSA service accounts:**

```bash
eksctl get iamserviceaccount --cluster <cluster-name>
```

**Debugging IRSA:** Pod not getting credentials? Check: (1) ServiceAccount has `eks.amazonaws.com/role-arn` annotation, (2) OIDC provider exists for cluster (`eksctl utils associate-iam-oidc-provider`), (3) IAM role trust policy allows the cluster OIDC and the K8s namespace/serviceaccount.

---

## 4. IAM identity mapping (human / CI access to cluster)

Maps an IAM role or user to a Kubernetes user/group so they can use `kubectl` (e.g. CodeBuild, GitHub Actions, SSO).

**Add mapping:**

```bash
eksctl create iamidentitymapping \
  --cluster <cluster-name> \
  --arn <iam-role-or-user-arn> \
  --username <kubernetes-username> \
  --group system:masters
```

**List mappings:**

```bash
eksctl get iamidentitymapping --cluster <cluster-name>
```

**Debugging “access denied”:** Run `kubectl get cm aws-auth -n kube-system -o yaml` and confirm the role ARN is in the mapRoles section (or add it via `eksctl create iamidentitymapping`).

---

## 5. Common flags

| Flag | Use |
|------|-----|
| `--cluster <name>` | Cluster name (many commands require it). |
| `--region <region>` | AWS region (if not from env/config). |
| `--approve` | Skip confirmation prompts. |
| `-f <file>` / `--config-file=<file>` | Use YAML config. |

---

## 6. After creating a cluster

1. **Update kubeconfig:**  
   `aws eks update-kubeconfig --region <region> --name <cluster-name>`
2. **Verify:**  
   `kubectl get nodes`
3. **Create IRSA / node groups / Fargate** as needed (sections 2–4).

---

## Prerequisites

- **AWS CLI:** Configured with credentials that can create EKS, IAM, and VPC resources (`aws sts get-caller-identity`).
- **kubectl:** Install separately; use after `aws eks update-kubeconfig`.

See also: `_docs/kubectl-cheatsheet.md` (debugging workloads), `_docs/kubectl-eksctl-logging-troubleshooting.md` (full reference).
