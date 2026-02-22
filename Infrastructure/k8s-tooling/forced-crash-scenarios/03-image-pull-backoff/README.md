# ImagePullBackOff / ErrImagePull

The container image **cannot be pulled** (wrong name, wrong tag, or no access). You'll see **ErrImagePull** first, then **ImagePullBackOff** as Kubernetes retries with backoff.

## Set up the test

**Prerequisites:** A running EKS (or any Kubernetes) cluster and `kubectl` configured.

1. From the repo root, go to this scenario folder:
   ```bash
   cd Infrastructure/k8s-tooling/forced-crash-scenarios/03-image-pull-backoff
   ```
2. Apply the manifest to create the broken state:
   ```bash
   kubectl apply -f .
   ```
3. The pod will show **ErrImagePull**, then **ImagePullBackOff**. Confirm with `kubectl get pods -l app=imagepull-demo`.

## What you'll see

- `kubectl get pods`: **ImagePullBackOff** (or ErrImagePull right after create).
- `kubectl describe pod -l app=imagepull-demo`: **Events** show "Failed to pull image ..." and the exact error (e.g. "not found", "pull access denied").

## How to fix the problem

**Diagnose:** Find out *why* the image can’t be pulled.

1. Check pod status:
   ```bash
   kubectl get pods -l app=imagepull-demo
   ```
2. Read **Events** and **Conditions** (they contain the pull error from the container runtime):
   ```bash
   kubectl describe pod -l app=imagepull-demo
   ```
   Look for lines like "Failed to pull image ... no such host", "not found", or "pull access denied". That tells you whether the problem is wrong name/tag, network, or auth.

**Fix:** The root cause here is a **wrong image name** (`nosuchregistry.example.com/nosuchimage:nosuchtag` doesn’t exist). Fix it by setting the image to one that exists and is pullable (e.g. a public image like `busybox:1.36`).

Option A — **Edit the Deployment**:

```bash
kubectl edit deployment imagepull-demo
```

Find `image: nosuchregistry.example.com/nosuchimage:nosuchtag` and change it to a valid image, e.g.:

```yaml
image: busybox:1.36
```

Save and exit. Kubernetes will create a new pod and pull the image.

Option B — **Patch the Deployment**:

```bash
kubectl patch deployment imagepull-demo --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value": "busybox:1.36"}]'
```

**Verify:** The new pod should pull the image and go Running.

```bash
kubectl get pods -l app=imagepull-demo
# STATUS should be Running
```

**In real clusters:** If the image name is correct, the problem might be **auth** (private registry) — add `imagePullSecrets` to the pod spec. Or **network** — node can’t reach the registry; fix DNS/firewall. The exact message in **Events** tells you which.

## Clean up

When you're done practicing, remove the demo resources. From this scenario folder:

```bash
kubectl delete -f .
```

This deletes the Deployment **imagepull-demo** and the Pod(s) it created. The **fix** was correcting the image (or auth/network) so the image can be pulled (see "How to fix the problem" above).
