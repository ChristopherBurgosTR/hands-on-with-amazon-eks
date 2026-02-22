# Error syncing pod

**"Error syncing pod"** is a generic message from kubelet when it cannot bring the pod into the desired state. The real cause is in the event message that follows (e.g. failed to create sandbox, failed to mount volume, failed to create container).

## What you'll see

- `kubectl describe pod`: Events show "Error syncing pod" plus a more specific reason (e.g. "Failed to create pod sandbox", "Failed to mount volume", "Failed to create container").

## Common causes and where to look

| Cause | What to check |
|-------|----------------|
| Failed to create pod sandbox | See [09-failed-pod-sandbox](../09-failed-pod-sandbox) — often CNI, runtime, or security policy. |
| Failed to mount volume | Wrong or missing PVC, StorageClass, or CSI driver. Check `kubectl get pvc`, `describe pvc`, node storage. |
| Failed to create container | Image pull (ImagePullBackOff), runtime error, or securityContext not allowed by PodSecurityPolicy/PSA. |
| Network / CNI | Pod network not ready; check CNI pods (e.g. aws-node), node network. |

## How to troubleshoot

1. `kubectl describe pod <name>` — read **Events** from bottom up; the line after "Error syncing pod" usually has the specific failure.
2. `kubectl get events -A --sort-by='.lastTimestamp'` — cluster-wide events.
3. On the node: kubelet logs (e.g. `journalctl -u kubelet` on the node, or EKS no longer gives node SSH by default — use describe and controller logs).

## Optional: trigger a sync error with a bad volume

A pod that references a **non-existent PVC** will stay Pending with a scheduling/volume message; once scheduled, a **missing volume** can contribute to "Error syncing pod" on the node. For a clear "sync" style failure, the [06-pvc-not-bound](../06-pvc-not-bound) scenario (PVC never binds) keeps the pod Pending; if the PVC existed but the volume mount failed on the node, you'd see "Error syncing pod" with mount failure in events.

This scenario is mainly a **runbook**. Use `kubectl describe pod` and events to find the underlying cause, then follow the scenario that matches (sandbox, volume, image, etc.).
