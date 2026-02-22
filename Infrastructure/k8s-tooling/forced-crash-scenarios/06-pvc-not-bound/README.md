# PVC not bound

The **PersistentVolumeClaim** stays **Pending** (not Bound) because no StorageClass can provision a volume (e.g. wrong or non-existent StorageClass). Pods that use this PVC will also stay **Pending** — "waiting for volume to be created".

## What you'll see

- `kubectl get pvc`: **pvc-not-bound-demo** is **Pending**.
- `kubectl get pods`: pod using the PVC is **Pending**; `kubectl describe pod` shows "0/X nodes are available: X persistentvolumeclaim 'pvc-not-bound-demo' not found" or "waiting for volume to be created".

## How to troubleshoot

1. `kubectl get pvc` — confirm PVC is Pending.
2. `kubectl describe pvc pvc-not-bound-demo` — **Events** show "no persistent volumes available" or "storageclass not found".
3. `kubectl get storageclass` — list available StorageClasses (on EKS you typically have `gp2` or `gp3`).
4. Fix: set `spec.storageClassName` to an existing StorageClass (or omit to use default), or create the missing StorageClass / provisioner.

## Apply / clean up

```bash
kubectl apply -f .
# Delete deployment first so pods release the PVC, then PVC
kubectl delete -f .
```
