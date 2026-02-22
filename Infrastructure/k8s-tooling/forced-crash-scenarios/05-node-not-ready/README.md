# NodeNotReady

A **node** is in **NotReady** when the control plane doesn't receive healthy kubelet heartbeats (or node conditions fail). You can't create this state with a manifest; it's caused by the node (e.g. kubelet down, network, resource pressure). Use this runbook to recognize and fix it.

## What you'll see

- `kubectl get nodes`: one node shows **NotReady**.
- `kubectl describe node <name>`: **Conditions** — `Ready` is False; **Events** may show "NodeNotReady" or kubelet communication issues.

## How to troubleshoot

1. **Confirm**: `kubectl get nodes` — note which node is NotReady.
2. **Node details**: `kubectl describe node <node-name>` — read Conditions (Ready, MemoryPressure, DiskPressure, PIDPressure) and Events.
3. **Pods on that node**: `kubectl get pods -A -o wide | grep <node-name>` — they may be Evicted or stuck Terminating.
4. **Common causes**:
   - Kubelet stopped or crashing on the node.
   - Network between control plane and node broken.
   - Node out of memory or disk (MemoryPressure/DiskPressure).
   - On EKS: underlying EC2 instance stopped, or node failed health checks.
5. **Fixes**:
   - **EKS**: Check EC2 instance status in AWS console; replace node group instance if needed. Draining the node will reschedule workloads.
   - **Self-managed**: SSH to node, check `systemctl status kubelet`, logs (`journalctl -u kubelet`), disk/memory.
   - **Drain and remove**: If the node is lost, cordon and drain it, then delete the node object so pods are rescheduled elsewhere:
     ```bash
     kubectl cordon <node-name>
     kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data
     kubectl delete node <node-name>
     ```
   - For **pods stuck in Terminating** on that node: after drain, if they're still there, force delete: `kubectl delete pod <name> -n <ns> --grace-period=0 --force`.

## No manifest

This scenario is a **runbook only**. To practice, use a cluster where you can stop kubelet or simulate node failure (e.g. lab node).
