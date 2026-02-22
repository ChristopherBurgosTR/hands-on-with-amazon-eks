# Service not accessible from within the cluster

The **Service** has **no Endpoints** because its **selector** doesn't match any Pod labels. From inside the cluster, DNS resolves (e.g. `demo-svc.default.svc.cluster.local`) but connections fail because no pod is behind the Service.

## What you'll see

- `kubectl get svc demo-svc` — ClusterIP is present.
- `kubectl get endpoints demo-svc` — **No endpoints** (or empty list).
- From another pod: `wget -qO- http://demo-svc.default.svc.cluster.local` — connection refused or timeout.

## How to troubleshoot

1. **Check Service and Endpoints**:
   ```bash
   kubectl get svc demo-svc -o wide
   kubectl get endpoints demo-svc
   ```
2. **Check selector vs pod labels**:
   ```bash
   kubectl get pods -l app=demo-app
   kubectl get pods -l app=wrong-selector
   ```
   Service selects `app=wrong-selector`; pods have `app=demo-app` — no match.
3. **Fix**: Update the Service's `spec.selector` to match the pods (e.g. `app: demo-app`), or ensure pods have the labels the Service expects. Also verify **port** and **targetPort** match the container.

## Apply / clean up

```bash
kubectl apply -f .
# Test from another pod in same namespace:
# kubectl run curl --rm -it --image=curlimages/curl -- curl -s -o /dev/null -w "%{http_code}" http://demo-svc/
kubectl delete -f .
```
