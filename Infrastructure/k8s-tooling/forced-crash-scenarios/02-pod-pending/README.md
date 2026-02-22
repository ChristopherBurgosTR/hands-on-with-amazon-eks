# Pod stuck in Pending

The pod stays **Pending** because the scheduler cannot place it on any node. This manifest uses a **nodeSelector** that no node has, so no node matches.

## What you'll see

- `kubectl get pods`: status **Pending**
- `kubectl describe pod -l app=pending-demo`: Events show **FailedScheduling** — "0/X nodes are available: X node(s) didn't match node selector."

## How to troubleshoot

1. `kubectl get pods` — confirm Pending.
2. `kubectl describe pod <name>` — read **Events** at the bottom for the scheduling reason.
3. Check nodes: `kubectl get nodes`, `kubectl describe node <name>`.
4. Fix: remove or change the nodeSelector so at least one node matches, or add the label to a node.

## Apply / clean up

```bash
kubectl apply -f .
kubectl delete -f .
```


Training alignment
Debugging: kubectl get/describe/logs, Events (01, 02, 03, 06, 07, 09, 10).
Service networking: Endpoints, selector vs labels, in-cluster DNS (08).
Resource/health: Pending, scheduling, NodeNotReady, CrashLoopBackOff (01, 02, 05, 10).
Configuration: image pull, PVC/StorageClass, finalizers (03, 04, 06).
Certs/control plane: kubeconfig and EKS (12), etcd awareness (11).
The main README in forced-crash-scenarios has the full table, quick-start commands, and a short “Training focus” section that ties these to the areas you listed (debugging, service networking, resource/health, ingress/LB, config/secrets, problem-solving). Use the README as your index; each scenario folder has its own README with apply/cleanup and troubleshooting steps.