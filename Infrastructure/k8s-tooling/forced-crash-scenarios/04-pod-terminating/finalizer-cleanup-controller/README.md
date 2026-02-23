# Finalizer Cleanup Controller

A small controller that **removes the `example.com/block-deletion` finalizer** from pods so they can leave the **Terminating** state. Use it with the [04-pod-terminating](../forced-crash-scenarios/04-pod-terminating) scenario when you want the "proper" fix (a controller that clears the finalizer) instead of manually patching.

## What it does

- Lists pods (in one namespace or all) on a timer.
- For any pod that has **`deletion_timestamp`** set and **`example.com/block-deletion`** in `metadata.finalizers`, it runs:
  `kubectl patch pod <name> -n <namespace> -p '{"metadata":{"finalizers":null}}' --type=merge`
- The API server then completes deletion and the pod disappears.

## Prerequisites

- `kubectl` in `PATH` (for the patch step).
- Python 3.8+ and `pip install -r requirements.txt`, or run via the Docker image.
- Kubeconfig or in-cluster config so the controller can list pods and run `kubectl`.

## Run locally

```bash
cd Infrastructure/k8s-tooling/finalizer-cleanup-controller
pip install -r requirements.txt
python controller.py
```

Optional environment variables:

| Variable         | Default                   | Description                          |
|------------------|---------------------------|--------------------------------------|
| `FINALIZER_NAME` | `example.com/block-deletion` | Finalizer to remove                  |
| `NAMESPACE`      | (empty = all)             | Only consider pods in this namespace |
| `POLL_INTERVAL`  | `5`                       | Seconds between list cycles          |

## Run in-cluster

1. Build and push an image that includes Python, `kubectl`, and this repo (or copy in `controller.py` + `requirements.txt` and run `pip install` in the image):

   ```bash
   docker build -t <your-registry>/finalizer-cleanup-controller:latest .
   docker push <your-registry>/finalizer-cleanup-controller:latest
   ```

2. Create a ServiceAccount (and optional RBAC) that can list and patch pods. The provided manifest uses the default service account; for production, use a dedicated SA and restrict to the namespaces you need.

3. Apply the Deployment:

   ```bash
   kubectl apply -f deploy/
   ```

4. The controller runs in the cluster and will clear the finalizer from any stuck **Terminating** pod that has `example.com/block-deletion`.

## Try it with 04-pod-terminating

1. Create the stuck pod:
   ```bash
   kubectl apply -f ../forced-crash-scenarios/04-pod-terminating/
   kubectl delete pod terminating-demo
   kubectl get pods   # should show terminating-demo Terminating
   ```

2. Start the controller (locally or deploy it in-cluster).

3. The controller will patch the pod and remove the finalizer; the pod will disappear from `kubectl get pods`.

## Clean up

- **Local:** Stop the controller (Ctrl+C).
- **In-cluster:** `kubectl delete -f deploy/`
