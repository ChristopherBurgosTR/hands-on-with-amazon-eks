# etcd (Kubernetes key-value store)

**etcd** is the key-value store used by Kubernetes for all cluster state. On **EKS**, etcd is managed by AWS (control plane); you don't get direct access. This runbook covers how to think about etcd issues and where to look.

## Set up / how to use this scenario

**No manifest to apply.** This is a runbook-only scenario. Use it when:

- The live exercise or your cluster shows **API slowness**, timeouts, or control plane issues, or
- You want to understand what etcd is and what to check on EKS vs self-managed clusters.

**Prerequisites:** A cluster (EKS or self-managed) and `kubectl` configured. For EKS you won't run etcd directly; use the AWS console and this runbook.

1. If you see `kubectl` commands hanging or API errors, consider control plane/etcd as a possible cause.
2. On EKS: check the cluster status and events in the **AWS EKS console**.
3. Follow the "EKS" and "Self-managed" sections below as applicable.

## What etcd is used for

- Storing all API objects (Pods, Services, ConfigMaps, etc.).
- Leader election and coordination.
- When etcd is unhealthy or lost: API server can't read/write, cluster can appear stuck or inconsistent.

## What you might see when etcd has issues

- API requests slow or timing out.
- `kubectl get nodes` or other commands hang or return errors.
- Controllers not making progress (e.g. deployments stuck).
- "etcd cluster is unavailable" or similar in control plane logs (if visible).

## How to fix the problem

**EKS (managed control plane):**

- You **cannot** access etcd directly; AWS manages it.
- **Diagnose:** If API is slow or failing, check **AWS EKS console** → your cluster → status and events.
- **Fix:** For transient issues, wait and retry. For persistent control plane issues, open an AWS support case. In extreme cases, recreate the cluster after backing up what you need (e.g. manifests, data).

**Self-managed / kubeadm clusters:**

1. **Diagnose:** Check etcd health on a control plane node (paths may vary):
   ```bash
   sudo ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
     --cacert=/etc/kubernetes/pki/etcd/ca.crt \
     --cert=/etc/kubernetes/pki/etcd/server.crt \
     --key=/etc/kubernetes/pki/etcd/server.key \
     endpoint health
   ```
2. **Common issues:** Disk full (etcd needs disk for WAL/snapshots), network partition, or overload. Check disk, I/O, and etcd logs.
3. **Fix:** Free disk, fix network, or restore from backup using Kubernetes etcd backup/restore docs. Practice backup/restore in a lab.

**Verify:** API responds normally: `kubectl get nodes` and other commands succeed without long delays or errors.

**Takeaway:** On EKS you don’t fix etcd yourself — you use the console and support. On self-managed clusters, diagnose with etcdctl and logs, then fix disk/network or restore.

## Clean up

This scenario doesn’t create resources — it’s a runbook. There’s nothing to delete. If you were testing on a cluster with control plane issues, resolving those (or recreating the cluster) is the “clean up.”
