# FailedScheduling

The **scheduler** cannot place the pod on any node. The pod stays **Pending** and **Events** show **FailedScheduling** with a reason (e.g. "0/X nodes are available: X node(s) didn't match node selector", "X Insufficient cpu", "X node(s) had taint X").

## Set up the test

**Prerequisites:** A running EKS (or any Kubernetes) cluster and `kubectl` configured.

1. From the repo root, go to this scenario folder:
   ```bash
   cd Infrastructure/k8s-tooling/forced-crash-scenarios/10-failed-scheduling
   ```
2. Apply the manifest to create the broken state:
   ```bash
   kubectl apply -f .
   ```
3. The pod will stay **Pending**; Events will show **FailedScheduling**. Confirm with `kubectl get pods -l app=failed-scheduling-demo` and `kubectl describe pod -l app=failed-scheduling-demo`.

## What you'll see

- `kubectl get pods`: **Pending**.
- `kubectl describe pod -l app=failed-scheduling-demo`: **Events** show "FailedScheduling" and the exact reason (e.g. "0/X nodes are available: X node(s) didn't match node selector").

## How to fix the problem

**Diagnose:** Find out *why* the scheduler didn’t place the pod.

1. Confirm the pod is Pending:
   ```bash
   kubectl get pods -l app=failed-scheduling-demo
   ```
2. Read **Events** (the scheduler writes the reason here):
   ```bash
   kubectl describe pod -l app=failed-scheduling-demo
   ```
   You’ll see the exact cause — e.g. node selector, insufficient cpu/memory, or taints.

**Fix:** In this demo the cause is a **nodeSelector** that no node has (`schedule-here: no-node-has-this`). Fix by removing the nodeSelector so the pod can schedule on any node (or add the matching label to a node).

Option A — **Edit the Deployment**:

```bash
kubectl edit deployment failed-scheduling-demo
```

Delete the `nodeSelector` block under `spec.template.spec`. Save and exit. A new pod will be created and should schedule.

Option B — **Patch the Deployment**:

```bash
kubectl patch deployment failed-scheduling-demo --type='json' -p='[{"op": "remove", "path": "/spec/template/spec/nodeSelector"}]'
```

**Verify:** The new pod should be scheduled and go Running.

```bash
kubectl get pods -l app=failed-scheduling-demo
# STATUS should be Running; NODE should be set
```

**Takeaway:** FailedScheduling is the **reason** a pod is Pending. Always read **Events** with `kubectl describe pod` to get the exact reason, then fix the spec (nodeSelector, resources, tolerations) or the nodes (labels, taints, capacity) so the scheduler can place the pod.

## Clean up

When you're done practicing, remove the demo resources. From this scenario folder:

```bash
kubectl delete -f .
```

This deletes the Deployment **failed-scheduling-demo** and the Pod(s) it created. The **fix** was removing (or correcting) the nodeSelector so the pod could be scheduled (see "How to fix the problem" above).
