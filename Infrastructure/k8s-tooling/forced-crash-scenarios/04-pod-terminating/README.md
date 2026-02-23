# Pod stuck in Terminating

The pod stays **Terminating** because a **finalizer** is set and never removed. The API server waits for the finalizer to complete before removing the object.

## Set up the test

**Prerequisites:** A running EKS (or any Kubernetes) cluster and `kubectl` configured.

1. From the repo root, go to this scenario folder:
   ```bash
   cd Infrastructure/k8s-tooling/forced-crash-scenarios/04-pod-terminating
   ```
2. Apply the manifest to create the broken state:
   ```bash
   kubectl apply -f .
   ```
3. Delete the pod so it enters Terminating: run `kubectl delete pod terminating-demo` (or `kubectl delete -f .`). The pod will stay **Terminating** and never disappear. Confirm with `kubectl get pods`.

## What you'll see

- `kubectl get pods`: the pod **terminating-demo** shows status **Terminating** (and may stay that way indefinitely).
- `kubectl describe pod terminating-demo`: in **Metadata** you’ll see **Finalizers** with `example.com/block-deletion`. The API server won’t delete the object until that finalizer is removed. To view finalizers use `kubectl get pod terminating-demo -o yaml` (describe often omits them).

## How to fix the problem

**Diagnose:** Confirm the pod is stuck because of a finalizer.

1. List pods and note the one stuck in Terminating:
   ```bash
   kubectl get pods
   ```
2. Inspect the pod and find **Finalizers**:
   ```bash
   kubectl get pod terminating-demo -o yaml | grep -A3 finalizers
   # (kubectl describe often does not show finalizers; use get -o yaml)
   # kubectl describe pod terminating-demo
   ```
   You’ll see `finalizers: [example.com/block-deletion]`. Nothing in this demo removes that, so the pod never completes deletion.

**Fix:** The only way to "fix" a stuck Terminating pod caused by a finalizer is to **remove the finalizer** so the API server can finish the delete. (In production, the controller that added the finalizer is supposed to remove it after doing cleanup; if that controller is broken or missing, you may have to remove it manually.)

Remove the finalizer:

**Option A — Manual patch (one-off):**

```bash
kubectl patch pod terminating-demo -p '{"metadata":{"finalizers":null}}' --type=merge
```

**Option B — Run a controller** that removes this finalizer for any stuck pod (see [finalizer-cleanup-controller](../../finalizer-cleanup-controller/README.md)):

```bash
# From repo root: run locally or deploy in-cluster
cd Infrastructure/k8s-tooling/finalizer-cleanup-controller && python controller.py
```

As soon as the finalizer is removed, the API server completes the deletion and the pod disappears from `kubectl get pods`.

**Verify:**

```bash
kubectl get pods
# terminating-demo should no longer appear
```

**Takeaway:** If a pod (or any object) stays Terminating, check **finalizers**. Removing the finalizer allows the object to be deleted. Use with care in production — only do this when you understand why the finalizer was there and that it’s safe to skip it.

## Other causes of "stuck Terminating"

- **Node NotReady:** The kubelet on the node can’t report that the container stopped, so the pod stays Terminating. Fix the node or force-delete the pod (see scenario 05-node-not-ready).
- **Process ignoring SIGTERM:** The main process doesn’t exit within `terminationGracePeriodSeconds`. Check logs; you may need to fix the app or adjust the grace period.

## Clean up

For this scenario you already "fixed" the pod by removing the finalizer, so the pod is gone. To remove any remaining resources from the manifest (e.g. if you re-applied later), from this scenario folder run:

```bash
kubectl delete -f . --wait=false
# If the pod is still there (e.g. you didn’t patch yet), remove the finalizer first:
# kubectl patch pod terminating-demo -p '{"metadata":{"finalizers":null}}' --type=merge
kubectl delete -f .
```

`kubectl delete -f .` deletes every resource in the YAML in this directory (here, the Pod **terminating-demo**). The actual **fix** was removing the finalizer so the pod could be deleted (see "How to fix the problem" above).
