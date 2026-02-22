# Pod stuck in Terminating

The pod stays **Terminating** because a **finalizer** is set and never removed. The API server waits for the finalizer to complete before removing the object.

## What you'll see

- `kubectl get pods`: status **Terminating** (Ready 0/1, never disappears).
- `kubectl describe pod terminating-demo`: **Finalizers** include `example.com/block-deletion`.

## How to troubleshoot

1. `kubectl get pods` — confirm Terminating.
2. `kubectl describe pod <name>` — check **Finalizers** in metadata.
3. If the controller that should remove the finalizer is broken or missing, you can remove it manually (use with care in production):
   ```bash
   kubectl patch pod terminating-demo -p '{"metadata":{"finalizers":null}}' --type=merge
   ```
4. After removing the finalizer, the pod is removed from the API.

## Other causes of "stuck Terminating"

- Node NotReady: kubelet can't report container termination; fix the node or force-delete the pod (see node-not-ready runbook).
- Long `terminationGracePeriodSeconds` and process ignoring SIGTERM; check logs and consider SIGKILL after grace period.

## Apply / clean up

```bash
kubectl apply -f .
# Pod will stay Terminating until you remove the finalizer, then:
kubectl patch pod terminating-demo -p '{"metadata":{"finalizers":null}}' --type=merge
# Or delete the manifest and then patch if the pod name is still present
kubectl delete -f . --wait=false
kubectl patch pod terminating-demo -p '{"metadata":{"finalizers":null}}' --type=merge
```
