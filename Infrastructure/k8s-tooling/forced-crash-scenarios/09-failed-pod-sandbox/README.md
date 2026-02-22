# Failed to create pod sandbox

**"Failed to create pod sandbox"** means the container runtime (containerd/CRI-O) could not create the pod's network namespace or sandbox. Often seen in **Events** together with "Error syncing pod".

## Set up / how to use this scenario

**No manifest to apply.** This is a runbook-only scenario. Use it when:

- You see **"Failed to create pod sandbox"** (or "Error syncing pod" with that reason) in `kubectl describe pod` Events, or
- You have a lab cluster where you can break the CNI or runtime on a node (e.g. stop the aws-node DaemonSet pod on a test node); only in a disposable cluster.

**Prerequisites:** A cluster and `kubectl` configured. Either a pod already showing this error in events, or a lab where you can induce it.

1. Find a pod that isn't running and run `kubectl describe pod <name> -n <namespace>`.
2. In **Events**, look for "Failed to create pod sandbox" and the reason (e.g. network plugin not ready, CNI error).
3. Follow the "How to troubleshoot" and "Common causes" sections below.

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

## How to fix the problem

**Diagnose:** Get the exact sandbox failure and which node it’s on.

1. `kubectl describe pod <name> -n <namespace>` — in **Events**, note the full "Failed to create pod sandbox" message and the **node name**.
2. `kubectl get nodes` — is that node **Ready**?
3. **EKS:** Check whether the CNI (aws-node) is running on that node:
   ```bash
   kubectl get pods -n kube-system -l k8s-app=aws-node -o wide
   kubectl describe node <node-name>
   ```
4. On the node (if you have access): check kubelet and containerd logs. On EKS you often rely on the console and support.

**Fix:** Depends on the cause from the event and the table above:
- **CNI not ready:** Fix or restart the CNI (e.g. aws-node). On EKS, check IAM and subnet/ENI for the node.
- **Insufficient ENI/IPs (EKS):** Increase capacity (e.g. more subnets, custom networking) or scale the node group.
- **Runtime failure:** Restart kubelet/containerd on the node or replace the node.
- **Security/admission:** Adjust PodSecurityPolicy or Pod Security Admission so the pod is allowed, or change the pod’s securityContext.
- **Resource exhaustion:** Free disk/memory on the node or drain and replace the node.

**Verify:** The pod (or a new one from the same workload) should go Running. Check `kubectl get pods` and Events.

**Takeaway:** Sandbox failures are environmental (CNI, runtime, or node). The exact message in Events tells you which; then fix that component or replace the node.

## Clean up

This scenario doesn’t create resources — it’s a runbook. If you induced a sandbox failure in a lab (e.g. broke CNI on a node), restore the node or delete the test workload; there’s no `kubectl delete -f .` for this scenario.
