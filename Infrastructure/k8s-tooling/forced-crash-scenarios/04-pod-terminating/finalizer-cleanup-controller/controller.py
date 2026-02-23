#!/usr/bin/env python3
"""
Finalizer cleanup controller for scenario 04-pod-terminating.

Watches for pods that have deletion_timestamp set and the finalizer
example.com/block-deletion. Removes that finalizer so the API server
can complete deletion (pod leaves "Terminating" state).

Run with kubeconfig (e.g. in-cluster or KUBECONFIG). Optional env:
  FINALIZER_NAME - default: example.com/block-deletion
  NAMESPACE      - default: "" (all namespaces)
  POLL_INTERVAL  - default: 5 (seconds between list cycles)
"""

import os
import subprocess
import sys
import time
from typing import List, Tuple

from kubernetes import client, config

FINALIZER = os.environ.get("FINALIZER_NAME", "example.com/block-deletion")
NAMESPACE = os.environ.get("NAMESPACE", "").strip() or None
POLL_INTERVAL = int(os.environ.get("POLL_INTERVAL", "5"))


def load_config():
    """Load in-cluster or kubeconfig."""
    try:
        config.load_incluster_config()
    except config.ConfigException:
        config.load_kube_config()


def should_clean(pod: client.V1Pod) -> bool:
    """True if pod is stuck terminating with our finalizer."""
    if not pod.metadata or not pod.metadata.finalizers:
        return False
    if pod.metadata.deletion_timestamp is None:
        return False
    return FINALIZER in pod.metadata.finalizers


def remove_finalizer_kubectl(namespace: str, name: str) -> bool:
    """Remove finalizer via kubectl patch (merge patch)."""
    cmd = [
        "kubectl", "patch", "pod", name,
        "-n", namespace,
        "-p", '{"metadata":{"finalizers":null}}',
        "--type=merge",
    ]
    try:
        subprocess.run(cmd, check=True, capture_output=True, text=True)
        return True
    except subprocess.CalledProcessError as e:
        print(f"kubectl patch failed for {namespace}/{name}: {e.stderr}", file=sys.stderr)
        return False
    except FileNotFoundError:
        print("kubectl not found; install kubectl or run in a image that has it", file=sys.stderr)
        return False


def list_stuck_pods(v1: client.CoreV1Api) -> List[Tuple[str, str]]:
    """Return list of (namespace, name) for pods we should clean."""
    stuck = []
    if NAMESPACE:
        pods = v1.list_namespaced_pod(NAMESPACE).items
    else:
        pods = v1.list_pod_for_all_namespaces().items
    for pod in pods:
        if should_clean(pod):
            stuck.append((pod.metadata.namespace, pod.metadata.name))
    return stuck


def run():
    load_config()
    v1 = client.CoreV1Api()
    ns_label = NAMESPACE or "all namespaces"
    print(f"Finalizer cleanup controller: watching for finalizer {FINALIZER!r} in {ns_label}", flush=True)

    while True:
        for ns, name in list_stuck_pods(v1):
            print(f"Removing finalizer from {ns}/{name}", flush=True)
            if remove_finalizer_kubectl(ns, name):
                print(f"Removed finalizer from {ns}/{name}", flush=True)
        time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    run()
