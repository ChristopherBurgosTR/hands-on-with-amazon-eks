# FailedScheduling

The **scheduler** cannot place the pod on any node. The pod stays **Pending** and **Events** show **FailedScheduling** with a reason (e.g. "0/X nodes are available: X node(s) didn't match node selector", "X Insufficient cpu", "X node(s) had taint X").

## What you'll see

- `kubectl get pods`: **Pending**.
- `kubectl describe pod -l app=failed-scheduling-demo`: **Events** — "FailedScheduling" and the exact reason (node selector, resources, taints).

## How to troubleshoot

1. `kubectl get pods` — confirm Pending.
2. `kubectl describe pod <name>` — read **Events** for the FailedScheduling message.
3. Address the cause:
   - **Node selector**: Add the required label to a node, or change/remove the selector.
   - **Insufficient resources**: Reduce requests, add nodes, or remove other workloads.
   - **Taints**: Add a matching toleration to the pod, or remove the taint from the node.

## Apply / clean up

```bash
kubectl apply -f .
kubectl delete -f .
```
