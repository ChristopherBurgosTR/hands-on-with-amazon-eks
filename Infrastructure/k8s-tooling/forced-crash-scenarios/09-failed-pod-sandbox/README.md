# Failed to create pod sandbox

**"Failed to create pod sandbox"** means the container runtime (containerd/CRI-O) could not create the pod's network namespace or sandbox. Often seen in **Events** together with "Error syncing pod".

## What you'll see

- `kubectl describe pod`: Events show "Failed to create pod sandbox" and a reason (e.g. "failed to set up network", "failed to create containerd task", "network plugin not ready").

## Common causes (EKS / Kubernetes)

| Cause | What to check |
|-------|----------------|
| **CNI not ready** | AWS VPC CNI (aws-node) not running or failing on the node. `kubectl get pods -n kube-system -l k8s-app=aws-node`. |
| **Insufficient ENI/IPs** | EKS: node hit ENI or secondary IP limit; add capacity or use custom networking. |
| **Runtime failure** | containerd/CRI-O error; check node kubelet/container runtime logs. |
| **Security / admission** | PodSecurityPolicy or Pod Security Admission rejecting the pod; check policy and pod securityContext. |
| **Resource exhaustion** | Node out of memory or inodes; check node conditions and kubelet. |

## How to troubleshoot

1. `kubectl describe pod <name>` — **Events**: note the exact "Failed to create pod sandbox" message and the node.
2. `kubectl get nodes` — is the node Ready?
3. **EKS**: Check CNI and node:
   ```bash
   kubectl get pods -n kube-system -l k8s-app=aws-node -o wide
   kubectl describe node <node-name>
   ```
4. On the node (if you have access): kubelet logs, containerd logs. On EKS managed nodes you may need to use EKS console or support.

## No manifest

This scenario is a **runbook only**. Sandbox failures are usually environmental (CNI, runtime, node). To simulate, you could break the CNI on a test node (e.g. stop aws-node DaemonSet pod or use a node with wrong IAM/ENI); do that only in a disposable cluster.
