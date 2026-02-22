# Forced pod crash scenarios

Manifests and runbooks for **intentionally failing or problematic states** on Kubernetes (EKS). Use these to practice troubleshooting for live hands-on exercises: `kubectl describe`, `kubectl logs`, events, service discovery, and configuration.

Each subfolder is one scenario. Where there is a manifest, apply from that folder with `kubectl apply -f <folder>`.

---

## Scenario index

| # | Scenario | Folder | Type | What it does |
|---|----------|--------|------|--------------|
| 01 | CrashLoopBackOff | [01-crashloop-backoff](./01-crashloop-backoff) | Manifest | Container exits non-zero → restarts → CrashLoopBackOff. |
| 02 | Pod stuck in Pending | [02-pod-pending](./02-pod-pending) | Manifest | nodeSelector no node matches → pod never scheduled. |
| 03 | ImagePullBackOff / ErrImagePull | [03-image-pull-backoff](./03-image-pull-backoff) | Manifest | Wrong/missing image → pull fails → ErrImagePull then ImagePullBackOff. |
| 04 | Pod stuck in Terminating | [04-pod-terminating](./04-pod-terminating) | Manifest | Finalizer blocks deletion → pod stays Terminating. |
| 05 | NodeNotReady | [05-node-not-ready](./05-node-not-ready) | Runbook | How to identify and fix a NotReady node (no manifest). |
| 06 | PVC not bound | [06-pvc-not-bound](./06-pvc-not-bound) | Manifest | Non-existent StorageClass → PVC Pending → pod Pending. |
| 07 | Error syncing pod | [07-error-syncing-pod](./07-error-syncing-pod) | Runbook | How to interpret "Error syncing pod" and find the real cause. |
| 08 | Service not accessible (in-cluster) | [08-service-not-accessible](./08-service-not-accessible) | Manifest | Service selector doesn't match pods → no Endpoints → connection fails. |
| 09 | Failed to create pod sandbox | [09-failed-pod-sandbox](./09-failed-pod-sandbox) | Runbook | CNI/runtime causes; how to troubleshoot (no manifest). |
| 10 | FailedScheduling | [10-failed-scheduling](./10-failed-scheduling) | Manifest | Scheduler can't place pod (e.g. nodeSelector) → Pending + FailedScheduling events. |
| 11 | etcd issues | [11-etcd-issues](./11-etcd-issues) | Runbook | etcd as Kubernetes store; what to check on EKS vs self-managed. |
| 12 | Cert signed by unknown authority | [12-cert-unknown-authority](./12-cert-unknown-authority) | Runbook | Resolve x509 "unknown authority" (kubeconfig / EKS update-kubeconfig). |

---

## Quick start

```bash
# From repo root — apply a scenario (example: crashloop)
kubectl apply -f Infrastructure/k8s-tooling/forced-crash-scenarios/01-crashloop-backoff/

# Inspect (example)
kubectl get pods -l scenario=crashloop-backoff
kubectl describe pod -l scenario=crashloop-backoff

# Clean up
kubectl delete -f Infrastructure/k8s-tooling/forced-crash-scenarios/01-crashloop-backoff/
```

**Runbook-only** scenarios (05, 07, 09, 11, 12) have no manifest — use their README for troubleshooting steps.

---

## Training focus (live EKS troubleshooting)

- **Kubernetes debugging**: pods, events, describe, logs.
- **Service networking and discovery**: Services, Endpoints, DNS (e.g. 08).
- **Resource and health**: scheduling, Pending, CrashLoopBackOff, NodeNotReady (01, 02, 05, 10).
- **Configuration**: image pull, PVCs, StorageClass (03, 06).
- **Problem-solving**: use events and describe to find root cause; fix selector, labels, or config.

Reference: [Kubernetes – Debugging applications](https://kubernetes.io/docs/tasks/debug/debug-application/), [kubectl cheat sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/).

---

## Adding a scenario

1. Add a numbered folder: `13-<name>/`, etc.
2. Put a manifest (YAML) and/or README in that folder.
3. Add a row to the table above in this README.
