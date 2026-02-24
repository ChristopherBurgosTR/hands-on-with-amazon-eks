# AWS Cloud Tool Commands

Reference for AWS CLI, profiles, CloudFormation, load balancers (ALB/NLB), and related commands. Use `--profile <name>` and/or `--region <region>` when needed.

---

## 1. AWS CLI configure & identity

**Configure default credentials and region (interactive):**

```bash
aws configure
# Prompts: AWS Access Key ID, Secret Access Key, region, output format
```

**Configure a named profile:**

```bash
aws configure --profile <profile-name>
```

**List current config:**

```bash
aws configure list
aws configure list --profile <profile-name>
```

**Verify who you are (account, ARN):**

```bash
aws sts get-caller-identity
aws sts get-caller-identity --profile <profile-name>
# Output: Account, UserId, Arn
```

**Get account ID only (for scripts):**

```bash
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
```

---

## 2. Export profile & region

**Use a specific profile for all following commands:**

```bash
export AWS_PROFILE=<profile-name>
# e.g. export AWS_PROFILE=bastion
```

**Use a specific region:**

```bash
export AWS_DEFAULT_REGION=<region>
# e.g. export AWS_DEFAULT_REGION=us-east-1
```

**One-off profile/region per command (no export):**

```bash
aws <command> --profile <profile-name> --region <region>
```

**Unset profile (back to default):**

```bash
unset AWS_PROFILE
```

---

## 3. Cloud-tool (internal / pipeline)

- **Login:** `login` (or your org’s cloud-tool login command)
- **Dry run (validate without deploying):**  
  `cloud-iac deploy-pipeline --dryrun`
- **View configuration:**  
  `cloud-tool view-config`
- **Deploy pipeline:**  
  `cloud-iac deploy-pipeline`

---

## 4. CloudFormation — stacks

**Create stack (from template file):**

```bash
aws cloudformation create-stack \
  --stack-name <stack-name> \
  --template-body file://<path-to-template.yaml-or.json> \
  --parameters ParameterKey=Key1,ParameterValue=Value1 \
  --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM \
  --region <region>
```

**Deploy/update stack (create-or-update, with parameters and tags):**

```bash
aws cloudformation deploy \
  --template-file <path-to-template.yaml-or.json> \
  --stack-name <stack-name> \
  --parameter-overrides Key1=Value1 Key2=Value2 \
  --tags Key1=Value1 Key2=Value2 \
  --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM
```

**Describe stack (status, outputs):**

```bash
aws cloudformation describe-stacks --stack-name <stack-name>
```

**Get a single output value (e.g. for scripts):**

```bash
aws cloudformation describe-stacks \
  --stack-name <stack-name> \
  --query "Stacks[0].Outputs[?OutputKey=='<OutputKey>'].OutputValue" \
  --output text
```

**List stack resources (logical IDs, physical IDs):**

```bash
aws cloudformation describe-stack-resources --stack-name <stack-name>
```

**List stack events (recent failures, rollbacks):**

```bash
aws cloudformation describe-stack-events --stack-name <stack-name>
```

**List all stacks (optional filter by status):**

```bash
aws cloudformation list-stacks
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE
```

**Update stack (change parameters/template):**

```bash
aws cloudformation update-stack \
  --stack-name <stack-name> \
  --template-body file://<path> \
  --parameters ParameterKey=Key1,ParameterValue=Value1 \
  --capabilities CAPABILITY_NAMED_IAM CAPABILITY_IAM
```

**Delete stack:**

```bash
aws cloudformation delete-stack --stack-name <stack-name>
```

**List exports (cross-stack references):**

```bash
aws cloudformation list-exports --query "Exports[?contains(Name,'<partial-name>')]"
```

---

## 5. Load balancers (ALB & NLB — ELB v2)

Use **`aws elbv2`** for Application Load Balancers (ALB) and Network Load Balancers (NLB). EKS Ingress often creates ALBs via the AWS Load Balancer Controller.

**List load balancers:**

```bash
aws elbv2 describe-load-balancers --region <region>
```

**Get load balancer by ARN or name:**

```bash
aws elbv2 describe-load-balancers --names <lb-name> --region <region>
aws elbv2 describe-load-balancers --load-balancer-arns <arn> --region <region>
```

**List by tag (e.g. Kubernetes Ingress):**

```bash
aws elbv2 describe-load-balancers --region <region> \
  --query "LoadBalancers[?contains(LoadBalancerName,'k8s')]"
```

**Describe target groups (for an LB or all):**

```bash
aws elbv2 describe-target-groups --region <region>
aws elbv2 describe-target-groups --load-balancer-arn <lb-arn> --region <region>
```

**Target health (is traffic reaching pods?):**

```bash
aws elbv2 describe-target-health --target-group-arn <target-group-arn> --region <region>
```

**Listeners (ports, default actions):**

```bash
aws elbv2 describe-listeners --load-balancer-arn <lb-arn> --region <region>
```

**Listener rules (host/path routing):**

```bash
aws elbv2 describe-rules --listener-arn <listener-arn> --region <region>
```

**Tags on a load balancer:**

```bash
aws elbv2 describe-tags --resource-arns <lb-arn> --region <region>
```

**Add tags (e.g. for billing or ops):**

```bash
aws elbv2 add-tags \
  --resource-arns <lb-arn> \
  --tags Key=Name,Value=my-alb Key=Environment,Value=dev \
  --region <region>
```

**Get DNS name and state:**

```bash
aws elbv2 describe-load-balancers --names <lb-name> --region <region> \
  --query "LoadBalancers[0].[DNSName,State.Code]" --output text
```

---

## 6. IAM (roles & policies — e.g. for Load Balancer Controller)

**Attach managed policy to role:**

```bash
aws iam attach-role-policy \
  --role-name <role-name> \
  --policy-arn <policy-arn>
```

**Detach policy from role:**

```bash
aws iam detach-role-policy \
  --role-name <role-name> \
  --policy-arn <policy-arn>
```

**List attached role policies:**

```bash
aws iam list-attached-role-policies --role-name <role-name>
```

---

## 7. EKS (cluster & kubeconfig)

**Update kubeconfig for kubectl:**

```bash
aws eks update-kubeconfig --region <region> --name <cluster-name>
```

**Describe cluster (status, endpoint, version):**

```bash
aws eks describe-cluster --name <cluster-name> --region <region>
```

**List clusters / node groups:**

```bash
aws eks list-clusters --region <region>
aws eks list-nodegroups --cluster-name <cluster-name> --region <region>
```

---

## 8. Other useful commands (ECR, RDS, CodeCommit)

**ECR — list images (e.g. for deploy tags):**

```bash
aws ecr list-images --repository-name <repo-name> --region <region>
aws ecr describe-images --repository-name <repo-name> --region <region>
```

**RDS — create DB instance (example):**

```bash
aws rds create-db-instance \
  --db-instance-identifier <id> \
  --db-instance-class <class> \
  --engine aurora-postgresql \
  --db-cluster-identifier <cluster-id> \
  --region <region> \
  --profile <profile> \
  --tags Key=Name,Value=<value>
```

**CodeCommit — clone URL from stack output:**

```bash
aws cloudformation describe-stacks --stack-name <repo-stack-name> \
  --query "Stacks[*].Outputs[?OutputKey=='CloneUrlHttp'].OutputValue" --output text
```

**Git config for CodeCommit (HTTPS with credential helper):**

```bash
git config --global credential.helper '!aws codecommit credential-helper $@'
git config --global credential.UseHttpPath true
```

Then use the CloneUrlHttp URL; git will use AWS CLI credentials.

---

## 9. Handy flags

| Flag | Use |
|------|-----|
| `--profile <name>` | Use named profile. |
| `--region <region>` | Region. |
| `--query "<jq-style>"` | Filter output (e.g. `Stacks[0].Outputs`). |
| `--output text` / `table` / `json` | Output format. |
| `--no-cli-pager` | Disable pager for script use. |

Example: `aws elbv2 describe-load-balancers --region us-east-1 --output table --no-cli-pager`

---

## 10. EKS compute options & cost savings

### Options at a glance

| Option | What it is | Typical cost vs on‑demand | Interruption / flexibility |
|--------|------------|----------------------------|----------------------------|
| **On‑demand EC2** (regular instances) | Pay per second, no commitment. | Baseline (100%). | No interruption; full control. |
| **Spot instances** | Excess EC2 capacity sold at a discount. Can be reclaimed with 2‑min notice. | Often **60–90% cheaper** than on‑demand. | Can be interrupted; use for fault‑tolerant or batch workloads. |
| **Fargate** | Serverless; pay per vCPU/memory per pod, no node management. | Often **more** than equivalent EC2 for steady 24/7 load; can be **cheaper** for bursty or low-utilization workloads. | No interruption; less control over OS/node. |
| **Savings Plans / Reserved Instances** | 1‑ or 3‑year commitment for EC2 (and optionally Fargate) in exchange for discount. | **~30–70%** off on‑demand depending on term and payment. | No change to interruption; less flexibility to change instance types/regions. |

### When to use which

- **Use Spot** when:
  - Workloads are **interruption‑tolerant**: batch, CI, dev/test, data processing, some worker queues.
  - You can **diversify** instance types and AZs (as in `02-spot-instances`) to reduce interruption risk.
  - You want the **largest discount** and can handle occasional replacement of nodes.

- **Use Fargate** when:
  - You want **no node ops** (no patching, scaling, or capacity planning for nodes).
  - Workloads are **bursty** or **spiky** (e.g. dev namespaces, low baseline with occasional peaks).
  - You’re willing to pay a premium for simplicity and don’t need node‑level tuning or special instance types.

- **Use regular (on‑demand) EC2** when:
  - Workloads are **critical and sensitive to interruption** (e.g. stateful, single‑replica, or hard to reschedule).
  - You need **predictable capacity** or specific instance types/features (GPU, local NVMe, etc.).
  - You’re combining with **Savings Plans or Reserved Instances** for baseline capacity.

### Cost‑saving options to consider (in order of impact)

1. **Spot for interruptible workloads** – Biggest per‑hour savings; use multiple instance types and AZs.
2. **Savings Plans (Compute or EC2)** – Commit to $/hour of EC2 (and optionally Fargate) for 1 or 3 years; apply to on‑demand and sometimes Spot.
3. **Reserved Instances (RI)** – Commit to specific instance type/region/AZ; good if your baseline is stable.
4. **Right‑sizing** – Use smaller instance types (e.g. `t3.small` / `t3.medium`) and scale with HPA/Cluster Autoscaler.
5. **Fargate for the right workloads** – Use for dev/batch/bursty namespaces (as in `04-fargate`) so you don’t pay for idle nodes.
6. **Cluster Autoscaler** – Scale node groups down when not needed (e.g. dev at night).
7. **Mixed strategy** – e.g. a small on‑demand (or RI) base + Spot for scale‑out, or Fargate for dev + EC2 (Spot/on‑demand) for production.

In this repo: `01-initial-cluster` and `03-managed-nodes` use on‑demand EC2; `02-spot-instances` uses Spot; `04-fargate` adds a Fargate profile for the `development` namespace.
