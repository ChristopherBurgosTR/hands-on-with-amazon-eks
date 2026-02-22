# Error syncing pod

**"Error syncing pod"** is a generic message from kubelet when it cannot bring the pod into the desired state. The real cause is in the event message that follows (e.g. failed to create sandbox, failed to mount volume, failed to create container).

## Set up / how to use this scenario

**No manifest to apply.** This is a runbook-only scenario. Use it when:

- You see **"Error syncing pod"** in `kubectl describe pod` Events (e.g. during the live exercise), or
- You combine it with other scenarios: image pull failure, PVC issues, or sandbox/CNI issues can all surface as "Error syncing pod" with a more specific reason in the next event line.

**Prerequisites:** A cluster and `kubectl` configured. Either a pod that is already showing "Error syncing pod" in events, or run another scenario (e.g. 03 image pull, 06 PVC) and use this runbook to interpret the events.

1. Find a pod that isn't running: `kubectl get pods -A | grep -v Running`
2. Run `kubectl describe pod <name> -n <namespace>` and look at **Events** for "Error syncing pod" and the following line.
3. Follow the "How to troubleshoot" and "Common causes" sections below.

## What you'll see

- `kubectl describe pod`: Events show "Error syncing pod" plus a more specific reason (e.g. "Failed to create pod sandbox", "Failed to mount volume", "Failed to create container").

## Common causes and where to look

| Cause | What to check |
|-------|----------------|
| Failed to create pod sandbox | See [09-failed-pod-sandbox](../09-failed-pod-sandbox) — often CNI, runtime, or security policy. |
| Failed to mount volume | Wrong or missing PVC, StorageClass, or CSI driver. Check `kubectl get pvc`, `describe pvc`, node storage. |
| Failed to create container | Image pull (ImagePullBackOff), runtime error, or securityContext not allowed by PodSecurityPolicy/PSA. |
| Network / CNI | Pod network not ready; check CNI pods (e.g. aws-node), node network. |

## How to fix the problem

**Diagnose:** "Error syncing pod" is generic; the **next line** in Events has the real reason.

1. `kubectl describe pod <name> -n <namespace>` — read **Events** from the bottom up. Look for "Error syncing pod" and the **immediately following** message (e.g. "Failed to create pod sandbox", "Failed to mount volume", "Failed to create container").
2. `kubectl get events -A --sort-by='.lastTimestamp'` — cluster-wide events if you need more context.
3. Use the table under "Common causes" (above) to map that message to a scenario: sandbox → [09-failed-pod-sandbox](../09-failed-pod-sandbox), volume → PVC/StorageClass or [06-pvc-not-bound](../06-pvc-not-bound), container → image pull or runtime → [03-image-pull-backoff](../03-image-pull-backoff).

**Fix:** There is no single fix — you fix the **underlying** issue:
- **Failed to create pod sandbox** → Follow scenario 09 (CNI, runtime, node).
- **Failed to mount volume** → Fix the PVC, StorageClass, or volume (see 06).
- **Failed to create container** → Fix image pull, image, or securityContext (see 03).

**Verify:** After fixing the underlying cause, the pod should go Running. Check with `kubectl get pods` and `kubectl describe pod` (Events should show normal progression).

**Takeaway:** Always read the event line **after** "Error syncing pod" to get the specific failure, then fix that (sandbox, volume, or container).

## Clean up

This scenario doesn’t create resources — it’s a runbook. If you triggered "Error syncing pod" by running another scenario (e.g. 03 or 06), clean up by deleting the resources from that scenario’s folder with `kubectl delete -f .`.
