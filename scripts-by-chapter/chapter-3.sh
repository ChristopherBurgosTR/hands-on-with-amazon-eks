# Run from repo root
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
cd "$REPO_ROOT" || { echo "Could not cd to repo root $REPO_ROOT"; exit 1; }

"$REPO_ROOT/scripts-by-chapter/chapter-1.sh"
"$REPO_ROOT/scripts-by-chapter/chapter-2.sh"

echo "***************************************************"
echo "********* CHAPTER 3 - STARTED AT $(date) **********"
echo "***************************************************"
echo "--- This could take around 10 minutes"

# Prerequisites
command -v eksctl >/dev/null 2>&1 || { echo "eksctl is required but not installed. See https://eksctl.io/installation/"; exit 1; }
command -v helm >/dev/null 2>&1 || { echo "helm is required but not installed. See https://helm.sh/docs/intro/install/"; exit 1; }

# Create OIDC Provider and connect it with EKS
    eksctl utils associate-iam-oidc-provider --cluster=eks-acg --approve

# Create IAM Policies of Bookstore Microservices
    ( cd "$REPO_ROOT/clients-api/infra/cloudformation" && ./create-iam-policy.sh ) & \
    ( cd "$REPO_ROOT/resource-api/infra/cloudformation" && ./create-iam-policy.sh ) & \
    ( cd "$REPO_ROOT/inventory-api/infra/cloudformation" && ./create-iam-policy.sh ) & \
    ( cd "$REPO_ROOT/renting-api/infra/cloudformation" && ./create-iam-policy.sh ) &

    wait

# Getting NodeGroup IAM Role from Kubernetes Cluster
    nodegroup_iam_role=$(aws cloudformation list-exports --query "Exports[?contains(Name, 'nodegroup-eks-node-group::InstanceRoleARN')].Value" --output text | xargs | cut -d "/" -f 2)

# Removing DynamoDB Permissions to the node
    aws iam detach-role-policy --role-name "${nodegroup_iam_role}" --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess

# Create IAM Service Accounts (stacks created by create-iam-policy.sh above)
    resource_iam_policy=$(aws cloudformation describe-stacks --stack-name development-iam-policy-resource-api --query "Stacks[0].Outputs[?OutputKey=='IamPolicyArn'].OutputValue | [0]" --output text 2>/dev/null | tr -d '"')
    renting_iam_policy=$(aws cloudformation describe-stacks --stack-name development-iam-policy-renting-api --query "Stacks[0].Outputs[?OutputKey=='IamPolicyArn'].OutputValue | [0]" --output text 2>/dev/null | tr -d '"')
    inventory_iam_policy=$(aws cloudformation describe-stacks --stack-name development-iam-policy-inventory-api --query "Stacks[0].Outputs[?OutputKey=='IamPolicyArn'].OutputValue | [0]" --output text 2>/dev/null | tr -d '"')
    clients_iam_policy=$(aws cloudformation describe-stacks --stack-name development-iam-policy-clients-api --query "Stacks[0].Outputs[?OutputKey=='IamPolicyArn'].OutputValue | [0]" --output text 2>/dev/null | tr -d '"')
    eksctl create iamserviceaccount --name resources-api-iam-service-account \
        --namespace development \
        --cluster eks-acg \
        --attach-policy-arn ${resource_iam_policy} --approve & \
    eksctl create iamserviceaccount --name renting-api-iam-service-account \
        --namespace development \
        --cluster eks-acg \
        --attach-policy-arn ${renting_iam_policy} --approve & \
    eksctl create iamserviceaccount --name inventory-api-iam-service-account \
        --namespace development \
        --cluster eks-acg \
        --attach-policy-arn ${inventory_iam_policy} --approve & \
    eksctl create iamserviceaccount --name clients-api-iam-service-account \
        --namespace development \
        --cluster eks-acg \
        --attach-policy-arn ${clients_iam_policy} --approve &

    wait

# Upgrading the applications
    ( cd "$REPO_ROOT/resource-api/infra/helm-v2" && ./create.sh ) & \
    ( cd "$REPO_ROOT/clients-api/infra/helm-v2" && ./create.sh ) & \
    ( cd "$REPO_ROOT/inventory-api/infra/helm-v2" && ./create.sh ) & \
    ( cd "$REPO_ROOT/renting-api/infra/helm-v2" && ./create.sh ) &

    wait


# Updating IRSA for AWS Load Balancer Controller
    
    helm uninstall aws-load-balancer-controller -n kube-system 2>/dev/null || true
    aws_load_balancer_iam_policy=$(aws cloudformation describe-stacks --stack-name aws-load-balancer-iam-policy --query "Stacks[0].Outputs[?OutputKey=='IamPolicyArn'].OutputValue | [0]" --output text 2>/dev/null | tr -d '"')
    [ -n "$aws_load_balancer_iam_policy" ] && aws iam detach-role-policy --role-name "${nodegroup_iam_role}" --policy-arn "${aws_load_balancer_iam_policy}" 2>/dev/null || true
    ( cd "$REPO_ROOT/Infrastructure/k8s-tooling/load-balancer-controller" && ./create-irsa.sh )

# Updating IRSA for External DNS
    
    helm uninstall external-dns -n kube-system 2>/dev/null || helm uninstall external-dns 2>/dev/null || true
    external_dns_iam_policy="arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
    aws iam detach-role-policy --role-name "${nodegroup_iam_role}" --policy-arn "${external_dns_iam_policy}" 2>/dev/null || true
    ( cd "$REPO_ROOT/Infrastructure/k8s-tooling/external-dns" && ./create-irsa.sh )


# Updating IRSA for VPC CNI
    vpc_cni_iam_policy="arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    aws iam detach-role-policy --role-name "${nodegroup_iam_role}" --policy-arn "${vpc_cni_iam_policy}" 2>/dev/null || true
    ( cd "$REPO_ROOT/Infrastructure/k8s-tooling/cni" && ./setup-irsa.sh )


echo "*************************************************************"
echo "********* READY FOR CHAPTER 4 - FINISHED AT $(date) *********"
echo "*************************************************************"