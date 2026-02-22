# etcd (Kubernetes key-value store)

**etcd** is the key-value store used by Kubernetes for all cluster state. On **EKS**, etcd is managed by AWS (control plane); you don't get direct access. This runbook covers how to think about etcd issues and where to look.

## What etcd is used for

- Storing all API objects (Pods, Services, ConfigMaps, etc.).
- Leader election and coordination.
- When etcd is unhealthy or lost: API server can't read/write, cluster can appear stuck or inconsistent.

## What you might see when etcd has issues

- API requests slow or timing out.
- `kubectl get nodes` or other commands hang or return errors.
- Controllers not making progress (e.g. deployments stuck).
- "etcd cluster is unavailable" or similar in control plane logs (if visible).

## EKS (managed control plane)

- You **cannot** SSH into control plane or run etcdctl; AWS manages etcd.
- If the control plane is degraded, check **AWS EKS console** → cluster → status and events.
- **Fixes**: Usually "wait and retry" for transient issues; for persistent issues, open a support case. In extreme cases, recreate the cluster (backup critical state first).

## Self-managed / kubeadm clusters

1. **Check etcd health** (on control plane node, with correct certs):
   ```bash
   # Example (paths vary by install)
   sudo ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
     --cacert=/etc/kubernetes/pki/etcd/ca.crt \
     --cert=/etc/kubernetes/pki/etcd/server.crt \
     --key=/etc/kubernetes/pki/etcd/server.key \
     endpoint health
   ```
2. **Common issues**: Disk full (etcd needs disk for WAL/snapshots), network partition, too many keys or large resources. Check disk, I/O, and etcd logs.
3. **Backup/restore**: Follow Kubernetes docs for etcd backup and restore; practice in a lab.

## No manifest

This scenario is a **runbook only**. Do not attempt to "break" etcd in a shared or production cluster. For the live troubleshooting exercise, focus on recognizing API slowness or control plane issues and checking EKS console / AWS support.
