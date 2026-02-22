# NodeNotReady

A **node** is in **NotReady** when the control plane doesn't receive healthy kubelet heartbeats (or node conditions fail). You can't create this state with a manifest; it's caused by the node (e.g. kubelet down, network, resource pressure). Use this runbook to recognize and fix it.

## Set up / how to use this scenario

**No manifest to apply.** This is a runbook-only scenario. Use it when:

- You encounter a **NotReady** node in a cluster (e.g. during the live troubleshooting exercise), or
- You have a lab cluster where you can simulate node failure (e.g. stop kubelet on a node, or terminate an EC2 instance in a node group).

**Prerequisites:** A cluster where at least one node is NotReady (or where you can create that state). `kubectl` configured.

1. If you're simulating: cause a node to go NotReady (e.g. stop kubelet, or in a disposable EKS cluster remove a node group and leave pods on a missing node).
2. Run `kubectl get nodes` and confirm one node shows **NotReady**.
3. Follow the "How to troubleshoot" steps below.

## What you'll see

- `kubectl get nodes`: one node shows **NotReady**.
- `kubectl describe node <name>`: **Conditions** — `Ready` is False; **Events** may show "NodeNotReady" or kubelet communication issues.

## How to fix the problem

**Diagnose:** Confirm which node is NotReady and why.

1. **Confirm**: `kubectl get nodes` — note which node shows **NotReady**.
2. **Node details**: `kubectl describe node <node-name>` — read **Conditions** (Ready, MemoryPressure, DiskPressure, PIDPressure) and **Events**. That tells you whether it’s kubelet, network, or resource pressure.
3. **Pods on that node**: `kubectl get pods -A -o wide | grep <node-name>` — they may be Evicted or stuck Terminating.

**Fix:** Depends on cause and whether you can recover the node.

- **EKS:** Check the EC2 instance in the AWS console (running? health?). If the instance is gone or unhealthy, the node group will replace it; drain the NotReady node so the control plane stops trying to use it. If the instance is fine but kubelet is bad, you may need to replace the node (scale down, scale up) or contact support.
- **Self-managed:** SSH to the node and check `systemctl status kubelet`, `journalctl -u kubelet`, disk and memory. Restart kubelet or fix the underlying issue.
- **Node is lost or unrecoverable:** Cordon and drain the node, then delete the node object so workloads reschedule elsewhere:
  ```bash
  kubectl cordon <node-name>
  kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
  kubectl delete node <node-name>
  ```
- **Pods stuck in Terminating** on that node (e.g. kubelet not responding): After drain, if pods remain, force-delete them:
  ```bash
  kubectl delete pod <name> -n <namespace> --grace-period=0 --force
  ```

**Verify:** The NotReady node is gone or Ready again, and workloads are running on other nodes:

```bash
kubectl get nodes
kubectl get pods -A -o wide
```

**Takeaway:** NotReady means the control plane isn’t getting a healthy heartbeat from the node. Diagnose with `describe node` (Conditions, Events), then fix the node or drain/delete it and let workloads move elsewhere.

## Clean up

This scenario doesn’t create resources from a manifest — it’s a runbook. There’s nothing to delete with `kubectl delete -f .`. If you simulated a NotReady node in a lab (e.g. stopped kubelet or terminated an instance), fix or remove that node as above; that’s the “clean up” for the scenario.
