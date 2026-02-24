# kubectl & eksctl Cheat Sheet

**Tip:** For front-end and app pods (inventory-api, renting-api, resource-api, clients-api), always use `-n development`.

---

## Goals → Commands (quick lookup)

| Goal | Command |
|------|---------|
| List pods in development | `kubectl get pods -n development` |
| Why is this pod Pending? | `kubectl describe pod <POD_NAME> -n development` (read **Events**) |
| App logs (pod Running) | `kubectl logs -n development <POD_NAME>` |
| Nodes cordoned? | `kubectl get nodes` → then `kubectl uncordon <NODE_NAME>` |
| Restart a deployment | `kubectl rollout restart deployment/<DEPLOY_NAME> -n development` |

---

## kubectl – Logs

```bash
kubectl logs -n development <POD_NAME>
kubectl logs -n development <POD_NAME> -f
kubectl logs -n development deployment/<DEPLOY_NAME>
kubectl logs -n development <POD_NAME> -c <CONTAINER_NAME>
kubectl logs -n development <POD_NAME> --previous
kubectl logs -n kube-system deployment/aws-load-balancer-controller -f
kubectl logs -n kube-system -l k8s-app=aws-node
```

---

## kubectl – Get & describe (inspection)

```bash
kubectl get pods -n development
kubectl get pods -n development -o wide
kubectl get pods -A
kubectl get pods -n development | grep Running
kubectl get nodes
kubectl get ingress -n development
kubectl get ingress -n development front-end-development-ingress | grep bookstore | awk '{print $3}'
kubectl get cm -n kube-system aws-auth -o yaml
kubectl get events -n development --sort-by='.lastTimestamp'
kubectl get pods -n kube-system -l k8s-app=aws-node
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

kubectl describe pod <POD_NAME> -n development
kubectl describe ingress -n development <INGRESS_NAME>
kubectl describe node <NODE_NAME>
```

---

## kubectl – Pod YAML & image debugging

```bash
kubectl get pods -n development
kubectl get pod <FULL_POD_NAME> -n development -o yaml
kubectl get pod -n development -l app=<LABEL> -o yaml
kubectl describe pod <POD_NAME> -n development
# Fix ImagePullBackOff: set image on deployment (not pod)
kubectl set image deployment/<DEPLOY_NAME> <CONTAINER_NAME>=<FULL_IMAGE_URL>:<TAG> -n development
# Or edit deployment
kubectl edit deployment <DEPLOY_NAME> -n development
```

---

## kubectl – Restarts & recovery

```bash
kubectl rollout restart deployment/<DEPLOY_NAME> -n development
kubectl delete pods -n development $(kubectl get pods -n development | grep Running | awk '{print $1}')
kubectl delete pods -n kube-system -l k8s-app=aws-node
kubectl uncordon <NODE_NAME>
kubectl scale deploy <DEPLOY_NAME> -n development --replicas=0
kubectl scale deploy <DEPLOY_NAME> -n development --replicas=1
```

---

## kubectl – Apply, create, wait, set, label

```bash
kubectl create namespace development
kubectl wait --for=condition=available deployment/aws-load-balancer-controller -n kube-system --timeout=120s
kubectl apply -f development-mesh.yaml
kubectl label namespace development mesh=development-mesh
kubectl label namespace development "appmesh.k8s.aws/sidecarInjectorWebhook"=enabled
kubectl apply -k "https://github.com/aws/eks-charts/stable/appmesh-controller/crds?ref=master"
kubectl set env ds aws-node -n kube-system AWS_VPC_K8S_CNI_CUSTOM_NETWORK_CFG=true
kubectl set env ds aws-node -n kube-system ENI_CONFIG_LABEL_DEF=failure-domain.beta.kubernetes.io/zone
```

---

## eksctl – Cluster & node groups

```bash
eksctl create cluster -f Infrastructure/eksctl/01-initial-cluster/cluster.yaml
eksctl get nodegroups --cluster eks-acg
eksctl create nodegroup -f cluster.yaml
eksctl delete nodegroup --cluster eks-acg eks-node-group
eksctl delete nodegroup --cluster eks-acg eks-node-group-spot-instances
eksctl create fargateprofile -f cluster.yaml
```

---

## eksctl – OIDC & IRSA

```bash
eksctl utils associate-iam-oidc-provider --cluster=eks-acg --approve
eksctl create iamserviceaccount --name <NAME> --namespace <NS> --cluster eks-acg --attach-policy-arn <ARN> --approve
eksctl get iamserviceaccount --cluster eks-acg
```

---

## eksctl – IAM identity mapping (CodeBuild → EKS)

```bash
eksctl create iamidentitymapping --cluster eks-acg --arn <ROLE_ARN> --username <USERNAME> --group system:masters
```

---

## One-liner troubleshooting flows

| Issue | Commands |
|-------|----------|
| App/URL | `kubectl get ingress -n development` → `kubectl get pods -n development` → `kubectl logs -n development deployment/<name> -f` |
| Access denied | `kubectl get cm -n kube-system aws-auth -o yaml`; confirm `eksctl create iamidentitymapping` for role |
| Ingress not created | `kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller` → `kubectl logs -n kube-system deployment/aws-load-balancer-controller -f` |
| Restart for new config (e.g. mesh) | `kubectl delete pods -n development $(kubectl get pods -n development -o name)` |
| VPC CNI | `kubectl get pods -n kube-system -l k8s-app=aws-node` → `kubectl delete pods -n kube-system -l k8s-app=aws-node` |

---

## Prerequisites

```bash
# Install eksctl (repo script)
./scripts-by-chapter/install-prerequisites.sh
# Kubeconfig (after cluster exists)
aws eks update-kubeconfig --region <region> --name eks-acg
```

All paths relative to repo root: `hands-on-with-amazon-eks`. Full reference: `_docs/kubectl-eksctl-logging-troubleshooting.md`.
