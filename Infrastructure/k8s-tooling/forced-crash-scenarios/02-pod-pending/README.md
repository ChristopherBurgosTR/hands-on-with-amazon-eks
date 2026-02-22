# Pod stuck in Pending

The pod stays **Pending** because the scheduler cannot place it on any node. This manifest uses a **nodeSelector** that no node has, so no node matches.

## Set up the test

**Prerequisites:** A running EKS (or any Kubernetes) cluster and `kubectl` configured.

1. From the repo root, go to this scenario folder:
   ```bash
   cd Infrastructure/k8s-tooling/forced-crash-scenarios/02-pod-pending
   ```
2. Apply the manifest to create the broken state:
   ```bash
   kubectl apply -f .
   ```
3. The pod will stay **Pending** (it never gets scheduled). Confirm with `kubectl get pods -l app=pending-demo`.

## What you'll see

- `kubectl get pods`: status **Pending**
- `kubectl describe pod -l app=pending-demo`: **Events** show **FailedScheduling** — e.g. "0/X nodes are available: X node(s) didn't match node selector."

## How to fix the problem

**Diagnose:** Find out *why* the pod isn’t scheduled.

1. Confirm the pod is Pending:
   ```bash
   kubectl get pods -l app=pending-demo
   ```
2. Read **Events** on the pod (this is where the scheduler reports why it didn’t place the pod):
   ```bash
   kubectl describe pod -l app=pending-demo
   ```
   In **Events** you’ll see something like: "0/3 nodes are available: 3 node(s) didn't match node selector."
3. Check what labels your nodes have (and what the pod is asking for):
   ```bash
   kubectl get nodes --show-labels
   kubectl get pod -l app=pending-demo -o yaml | grep -A5 nodeSelector
   ```
   The pod has `nodeSelector: nonexistent-label: "must-not-match-any-node"` and no node has that label, so the scheduler never places it.

**Fix:** Either make a node match the selector, or remove/change the nodeSelector so the pod can be scheduled. For this demo the simplest fix is to **remove the nodeSelector** so the pod can run on any node.

Option A — **Edit the Deployment**:

```bash
kubectl edit deployment pending-demo
```

Delete the entire `nodeSelector` block under `spec.template.spec` (the two lines with `nonexistent-label` and `must-not-match-any-node`). Save and exit. A new pod will be created and should schedule.

Option B — **Patch the Deployment** to remove the nodeSelector:

```bash
kubectl patch deployment pending-demo --type='json' -p='[{"op": "remove", "path": "/spec/template/spec/nodeSelector"}]'
```

**Verify:** The new pod should be scheduled and go to Running.

```bash
kubectl get pods -l app=pending-demo
# STATUS should change to Running; NODE should show a node name
```

**Takeaway:** A Pending pod is waiting for the scheduler. Always check **Events** with `kubectl describe pod` to see the exact reason (node selector, resources, taints, etc.), then fix the spec or the nodes so at least one node can run the pod.

## Clean up

When you're done practicing, remove the demo resources. From this scenario folder:

```bash
kubectl delete -f .
```

This deletes the Deployment **pending-demo** and the Pod(s) it created. That only removes the workload; the **fix** was changing or removing the nodeSelector so the pod could be scheduled (see "How to fix the problem" above).
