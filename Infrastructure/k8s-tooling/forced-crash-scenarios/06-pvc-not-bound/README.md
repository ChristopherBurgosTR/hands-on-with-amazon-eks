# PVC not bound

The **PersistentVolumeClaim** stays **Pending** (not Bound) because no StorageClass can provision a volume (e.g. wrong or non-existent StorageClass). Pods that use this PVC will also stay **Pending** — "waiting for volume to be created".

## Set up the test

**Prerequisites:** A running EKS (or any Kubernetes) cluster and `kubectl` configured.

1. From the repo root, go to this scenario folder:
   ```bash
   cd Infrastructure/k8s-tooling/forced-crash-scenarios/06-pvc-not-bound
   ```
2. Apply the manifests to create the broken state (PVC + Deployment that uses it):
   ```bash
   kubectl apply -f .
   ```
3. The PVC will stay **Pending** and the pod will stay **Pending**. Confirm with `kubectl get pvc` and `kubectl get pods -l app=pvc-demo`.

## What you'll see

- `kubectl get pvc`: **pvc-not-bound-demo** is **Pending**.
- `kubectl get pods -l app=pvc-demo`: pod is **Pending**; `kubectl describe pod` shows the pod waiting for the volume (e.g. "waiting for volume to be created" or "0/X nodes available: X persistentvolumeclaim 'pvc-not-bound-demo' not found").
- `kubectl describe pvc pvc-not-bound-demo`: **Events** show something like "storageclass not found" or "no persistent volumes available".

## How to fix the problem

**Diagnose:** Find out *why* the PVC never binds.

1. Check PVC status:
   ```bash
   kubectl get pvc
   kubectl describe pvc pvc-not-bound-demo
   ```
   In **Events** you’ll see that the StorageClass `nonexistent-storage-class` doesn’t exist or can’t provision a volume.
2. List available StorageClasses (EKS usually has `gp2` or `gp3`):
   ```bash
   kubectl get storageclass
   ```

**Fix:** The PVC uses a **non-existent StorageClass** (`nonexistent-storage-class`). Fix it by changing the PVC to use an **existing** StorageClass (e.g. `gp3` on EKS), or omit the storageClassName to use the default.

Option A — **Edit the PVC**:

```bash
kubectl edit pvc pvc-not-bound-demo
```

Change `storageClassName: nonexistent-storage-class` to an existing class, e.g.:

```yaml
storageClassName: gp3
```

**Note:** Some clusters don’t allow changing storageClassName on an existing PVC. If you get an error, delete the PVC and the Deployment, fix the YAML file (set `storageClassName: gp3` or remove the line to use default), then re-apply:

```bash
kubectl delete -f .
# Edit pvc.yaml (or the file that defines the PVC) and set storageClassName to gp3 (or your default).
kubectl apply -f .
```

Option B — **Delete and re-apply with correct StorageClass:** Edit `pvc.yaml` in this folder: set `storageClassName` to `gp3` (or your cluster’s default). Then:

```bash
kubectl delete -f .
kubectl apply -f .
```

**Verify:** The PVC should bind and the pod should schedule and run.

```bash
kubectl get pvc
# pvc-not-bound-demo STATUS should be Bound
kubectl get pods -l app=pvc-demo
# STATUS should be Running
```

**Takeaway:** A PVC stays Pending when no StorageClass can provision a volume. Check **Events** on the PVC and list **StorageClasses**; fix the PVC’s `storageClassName` (or create the right StorageClass) so the volume can be provisioned and the pod can run.

## Clean up

When you're done practicing, remove the demo resources. From this scenario folder:

```bash
kubectl delete -f .
```

This deletes the PVC **pvc-not-bound-demo**, the Deployment **pvc-demo**, and the Pod(s) it created. The **fix** was setting the PVC’s StorageClass to one that exists so the PVC could bind (see "How to fix the problem" above).
