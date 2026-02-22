# Service not accessible from within the cluster

The **Service** has **no Endpoints** because its **selector** doesn't match any Pod labels. From inside the cluster, DNS resolves (e.g. `demo-svc.default.svc.cluster.local`) but connections fail because no pod is behind the Service.

## Set up the test

**Prerequisites:** A running EKS (or any Kubernetes) cluster and `kubectl` configured.

1. From the repo root, go to this scenario folder:
   ```bash
   cd Infrastructure/k8s-tooling/forced-crash-scenarios/08-service-not-accessible
   ```
2. Apply the manifests to create the broken state (Deployment + Service with wrong selector):
   ```bash
   kubectl apply -f .
   ```
3. Wait for the pod to be Running. The Service will have **no Endpoints**. Confirm with `kubectl get endpoints demo-svc` (empty) and `kubectl get pods -l app=demo-app` (Running). From another pod, `curl http://demo-svc` would fail.

## What you'll see

- `kubectl get svc demo-svc`: ClusterIP is present.
- `kubectl get endpoints demo-svc`: **No endpoints** (or 0/0).
- Pods exist and are Running: `kubectl get pods -l app=demo-app`. So the "app" isn’t down — the Service just isn’t pointing at the pods.

## How to fix the problem

**Diagnose:** Find out *why* the Service has no backends.

1. Check that the Service exists and has no Endpoints:
   ```bash
   kubectl get svc demo-svc
   kubectl get endpoints demo-svc
   ```
2. Check the Service’s **selector** and compare to **Pod labels**:
   ```bash
   kubectl get svc demo-svc -o yaml | grep -A5 selector
   kubectl get pods -l app=demo-app
   kubectl get pods -l app=wrong-selector
   ```
   The Service selects `app=wrong-selector`, but the pods have `app=demo-app`. Selector and labels don’t match, so no Endpoints are created.

**Fix:** Make the Service’s **selector** match the Pod labels so the Service gets Endpoints. Here the pods have `app: demo-app`, so the Service should select `app: demo-app`.

Option A — **Edit the Service**:

```bash
kubectl edit svc demo-svc
```

Under `spec`, change the selector from:

```yaml
selector:
  app: wrong-selector
```

to:

```yaml
selector:
  app: demo-app
```

Save and exit. The Endpoints controller will immediately create Endpoints for the matching pods.

Option B — **Patch the Service**:

```bash
kubectl patch svc demo-svc -p '{"spec":{"selector":{"app":"demo-app"}}}'
```

**Verify:** The Service should now have Endpoints and be reachable.

```bash
kubectl get endpoints demo-svc
# Should list the pod IP(s)
# From another pod in the same namespace:
# kubectl run curl --rm -it --image=curlimages/curl -- curl -s -o /dev/null -w "%{http_code}" http://demo-svc/
```

**Takeaway:** If a Service is "not accessible" from inside the cluster, check **Endpoints** first. Empty Endpoints usually mean the Service **selector** doesn’t match any Pod labels. Fix by aligning selector with pod labels (and that **port** / **targetPort** match the container).

## Clean up

When you're done practicing, remove the demo resources. From this scenario folder:

```bash
kubectl delete -f .
```

This deletes the Deployment **app-with-wrong-labels**, the Service **demo-svc**, and the Pod(s) created by the Deployment. The **fix** was updating the Service selector to match the pods (see "How to fix the problem" above).
