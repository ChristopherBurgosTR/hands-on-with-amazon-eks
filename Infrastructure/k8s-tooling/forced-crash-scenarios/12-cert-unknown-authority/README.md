# Certificate signed by unknown authority

You see an error like **"x509: certificate signed by unknown authority"** when `kubectl` (or any client) talks to the Kubernetes API server and doesn't trust the server's TLS certificate (e.g. self-signed or custom CA).

## Set up / how to use this scenario

**No manifest to apply.** This is a runbook-only scenario. Use it when:

- You get **x509: certificate signed by unknown authority** (or similar) when running `kubectl`, or
- You've just created an EKS cluster and need to point your kubeconfig at it.

**Prerequisites:** `kubectl` and (for EKS) AWS CLI configured. Either you're already seeing the cert error, or you're configuring access to a new cluster.

1. **EKS:** Run `aws eks update-kubeconfig --name <cluster-name> --region <region>`, then retry `kubectl get nodes`.
2. If the error persists, follow "How to resolve" below (refresh kubeconfig, fix CA, or lab-only insecure skip).

## When this happens

- After creating a new EKS cluster and using `aws eks update-kubeconfig`: usually **not** an issue — AWS uses a trusted CA.
- When using a **self-signed** or corporate CA for the API server.
- When **kubeconfig** points at the wrong cluster or an old/cached certificate.
- When the **API server certificate** was rotated and your kubeconfig still has an old CA.

## How to fix the problem

**Diagnose:** You see an error when running `kubectl` (e.g. "x509: certificate signed by unknown authority"). That means your client doesn’t trust the API server’s TLS certificate — often because kubeconfig has the wrong or outdated CA.

**Fix:** Use the right fix for your situation:

### 1. Refresh kubeconfig (EKS)

```bash
aws eks update-kubeconfig --name <cluster-name> --region <region>
```

This fetches the current CA from EKS and updates `~/.kube/config`. Retry `kubectl` after this.

### 2. Trust the cluster CA in your kubeconfig

Your kubeconfig has a `certificate-authority-data` (or `certificate-authority` file) for the cluster. The error means the API server cert is signed by a CA that doesn't match what's in your kubeconfig.

- **EKS**: Re-run `aws eks update-kubeconfig` so the CA is up to date.
- **Self-signed / custom CA**: Ensure the `certificate-authority-data` (or the file at `certificate-authority`) contains the **root CA that signed the API server certificate**, not an outdated or wrong cert.

### 3. Insecure skip (temporary / lab only)

**Do not use in production.** For a quick test in a disposable environment only:

```yaml
# In kubeconfig, for the cluster, add:
clusters:
- cluster:
    server: https://...
    insecure-skip-tls-verify: true
```

Or:

```bash
kubectl --insecure-skip-tls-verify=true get nodes
```

This disables verification and is unsafe for any real workload.

### 4. Add the CA to system trust store (alternative)

If the API server uses a CA that isn't in your kubeconfig, you can add that CA to your OS trust store (e.g. `update-ca-certificates` on Linux, Keychain on macOS) so that TLS clients trust it. Usually for Kubernetes it's easier to fix kubeconfig (steps 1–2).

## Summary

| Situation | Action |
|-----------|--------|
| EKS cluster | `aws eks update-kubeconfig --name <cluster> --region <region>` |
| Wrong or stale CA in kubeconfig | Update `certificate-authority-data` (or file) to the correct cluster CA. |
| Lab only | `insecure-skip-tls-verify: true` or `--insecure-skip-tls-verify` (avoid in production). |

**Verify:** After updating kubeconfig or the CA, run `kubectl get nodes` (or any API call). It should succeed without cert errors.

**Takeaway:** The fix is always on the **client**: point kubeconfig at the right cluster and use the correct CA (or, in lab only, skip TLS verify). You don’t fix this by changing the server.

## Clean up

This scenario doesn’t create Kubernetes resources — the “problem” is your kubeconfig or trust store. There’s nothing to delete with `kubectl delete -f .`. If you used `insecure-skip-tls-verify` in a lab, remove it when done and use a proper CA instead.
