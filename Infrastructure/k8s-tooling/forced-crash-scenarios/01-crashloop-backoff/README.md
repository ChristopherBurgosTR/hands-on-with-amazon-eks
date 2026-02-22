# CrashLoopBackOff

Container **exits immediately with code 1**. Kubernetes restarts it; after several failures the pod enters **CrashLoopBackOff** (exponential backoff between restarts).

## Set up the test

**Prerequisites:** A running EKS (or any Kubernetes) cluster and `kubectl` configured (e.g. `aws eks update-kubeconfig --name <cluster> --region <region>`).

1. From the repo root, go to this scenario folder:
   ```bash
   cd Infrastructure/k8s-tooling/forced-crash-scenarios/01-crashloop-backoff
   ```
2. Apply the manifest to create the broken state:
   ```bash
   kubectl apply -f .
   ```
3. Within a few seconds, the pod will enter **CrashLoopBackOff**. Confirm with `kubectl get pods -l app=crashloop-demo`.

## What you'll see

- `kubectl get pods -l app=crashloop-demo`: status **CrashLoopBackOff** (or Error), RESTARTS increasing.
- `kubectl describe pod -l app=crashloop-demo`: **Events** show "Back-off restarting failed container" and "last termination reason: Error".
- `kubectl logs -l app=crashloop-demo --previous`: shows the log from the last run before the crash (e.g. "Intentional crash for demo").

## How to fix the problem

**Diagnose:** Find out *why* the container is exiting.

1. Check pod status and restarts:
   ```bash
   kubectl get pods -l app=crashloop-demo
   ```
2. Read **Events** (tells you the pod is restarting and why Kubernetes thinks it failed):
   ```bash
   kubectl describe pod -l app=crashloop-demo
   ```
   Look at the **Events** section at the bottom — e.g. "Back-off restarting failed container".
3. Read the **container's last log** (what the app printed before exiting):
   ```bash
   kubectl logs -l app=crashloop-demo --previous
   ```
   Here you see "Intentional crash for demo" — the container ran and then exited. For a real app you might see a stack trace or "connection refused".

**Fix:** The root cause in this demo is the **command**: the container runs `exit 1`, so it always exits with a failure code. Fix it by changing the Deployment so the container runs a command that **stays running** (or fix the real application code/config in a real scenario).

Option A — **Edit the Deployment in place** (good practice for learning):

```bash
kubectl edit deployment crashloop-demo
```

In the editor, find the container's `command` and change it from:

```yaml
command: ["sh", "-c", "echo 'Intentional crash for demo'; exit 1"]
```

to something that keeps the container running, e.g.:

```yaml
command: ["sleep", "infinity"]
```

Save and exit. Kubernetes will roll out a new pod with the new command.

Option B — **Patch the Deployment** (no editor):

```bash
kubectl patch deployment crashloop-demo --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/command", "value": ["sleep", "infinity"]}]'
```

**Verify:** The new pod should stay Running.

```bash
kubectl get pods -l app=crashloop-demo
# STATUS should be Running, RESTARTS 0 (or low and not increasing)
kubectl logs -l app=crashloop-demo
# No new "Intentional crash" message; pod is stable
```

**Takeaway:** Fixing CrashLoopBackOff means finding *why* the process exits (logs, describe, events) and then fixing the image, command, or application so the main process runs successfully and doesn’t exit with a non-zero code.

## Clean up

When you're done practicing, remove the demo resources. From this scenario folder:

```bash
kubectl delete -f .
```

This deletes **every resource defined in the YAML in this directory**: the Deployment **crashloop-demo** and (as a result) the Pod(s) it created. The cluster will no longer run this workload.

**Note:** Clean up only *removes* the workload. It does not "fix" the problem. The **fix** is changing the Deployment so the container no longer crashes (see "How to fix the problem" above).
