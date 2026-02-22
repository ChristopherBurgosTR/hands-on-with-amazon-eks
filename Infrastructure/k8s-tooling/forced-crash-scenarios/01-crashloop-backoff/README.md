# CrashLoopBackOff

Container **exits immediately with code 1**. Kubernetes restarts it; after several failures the pod enters **CrashLoopBackOff** (exponential backoff between restarts).

## Apply

```bash
kubectl apply -f .
```

## Inspect

```bash
kubectl get pods -l app=crashloop-demo
kubectl describe pod -l app=crashloop-demo
kubectl logs -l app=crashloop-demo --previous
```

## Clean up

```bash
kubectl delete -f .
```
