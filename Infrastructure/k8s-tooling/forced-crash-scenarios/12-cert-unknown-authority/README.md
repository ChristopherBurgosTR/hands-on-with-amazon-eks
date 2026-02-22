# Certificate signed by unknown authority

You see an error like **"x509: certificate signed by unknown authority"** when `kubectl` (or any client) talks to the Kubernetes API server and doesn't trust the server's TLS certificate (e.g. self-signed or custom CA).

## When this happens

- After creating a new EKS cluster and using `aws eks update-kubeconfig`: usually **not** an issue — AWS uses a trusted CA.
- When using a **self-signed** or corporate CA for the API server.
- When **kubeconfig** points at the wrong cluster or an old/cached certificate.
- When the **API server certificate** was rotated and your kubeconfig still has an old CA.

## How to resolve

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

## No manifest

This scenario is a **runbook only**. Fix is configuration (kubeconfig or trust store), not a Kubernetes manifest.
