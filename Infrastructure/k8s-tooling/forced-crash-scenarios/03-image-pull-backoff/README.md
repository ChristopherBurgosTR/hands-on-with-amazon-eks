# ImagePullBackOff / ErrImagePull

The container image **cannot be pulled** (wrong name, wrong tag, or no access). You'll see **ErrImagePull** first, then **ImagePullBackOff** as Kubernetes retries with backoff.

## What you'll see

- `kubectl get pods`: **ImagePullBackOff** (or ErrImagePull right after create).
- `kubectl describe pod -l app=imagepull-demo`: Events show "Failed to pull image ..." / "pull access denied" or "not found".

## How to troubleshoot

1. `kubectl get pods` — confirm ImagePullBackOff/ErrImagePull.
2. `kubectl describe pod <name>` — **Events** and **Conditions** show the exact pull error.
3. Fix: correct image name/tag, fix registry auth (imagePullSecrets), or fix network/registry access.

## Apply / clean up

```bash
kubectl apply -f .
kubectl delete -f .
```
