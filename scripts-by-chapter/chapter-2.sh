# Run from repo root (directory that contains scripts-by-chapter and Infrastructure)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd)"
cd "$REPO_ROOT" || { echo "Could not cd to repo root $REPO_ROOT"; exit 1; }

"$REPO_ROOT/scripts-by-chapter/chapter-1.sh"

echo "***************************************************"
echo "********* CHAPTER 2 - STARTED AT $(date) **********"
echo "***************************************************"
echo "--- This could take around 10 minutes"

# Getting NodeGroup IAM Role from Kubernetes Cluster
    nodegroup_iam_role=$(aws cloudformation list-exports --query "Exports[?contains(Name, 'nodegroup-eks-node-group::InstanceRoleARN')].Value" --output text | xargs | cut -d "/" -f 2)

# Installing Load Balancer Controller
    ( cd "$REPO_ROOT/Infrastructure/k8s-tooling/load-balancer-controller" && ./create.sh )
    aws_lb_controller_policy=$(aws cloudformation describe-stacks --stack-name aws-load-balancer-iam-policy --query "Stacks[*].Outputs[?OutputKey=='IamPolicyArn'].OutputValue" --output text | xargs)
    if [ -n "$aws_lb_controller_policy" ]; then
      aws iam attach-role-policy --role-name "${nodegroup_iam_role}" --policy-arn "${aws_lb_controller_policy}"
    fi

# Create SSL Certfiicate in ACM
    ( cd "$REPO_ROOT/Infrastructure/cloudformation/ssl-certificate" && ./create.sh )

# Installing ExternalDNS
    "$REPO_ROOT/Infrastructure/k8s-tooling/external-dns/create.sh"
    aws iam attach-role-policy --role-name "${nodegroup_iam_role}" --policy-arn arn:aws:iam::aws:policy/AmazonRoute53FullAccess

#  Create the DynamoDB Tables
    ( cd "$REPO_ROOT/clients-api/infra/cloudformation" && ./create-dynamodb-table.sh development ) & \
    ( cd "$REPO_ROOT/inventory-api/infra/cloudformation" && ./create-dynamodb-table.sh development ) & \
    ( cd "$REPO_ROOT/renting-api/infra/cloudformation" && ./create-dynamodb-table.sh development ) & \
    ( cd "$REPO_ROOT/resource-api/infra/cloudformation" && ./create-dynamodb-table.sh development ) &

    wait



# Adding DynamoDB Permissions to the node
    aws iam attach-role-policy --role-name "${nodegroup_iam_role}" --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess


# Installing the applications
    ( cd "$REPO_ROOT/resource-api/infra/helm" && ./create.sh ) & \
    ( cd "$REPO_ROOT/clients-api/infra/helm" && ./create.sh ) & \
    ( cd "$REPO_ROOT/inventory-api/infra/helm" && ./create.sh ) & \
    ( cd "$REPO_ROOT/renting-api/infra/helm" && ./create.sh ) & \
    ( cd "$REPO_ROOT/front-end/infra/helm" && ./create.sh ) &

    wait

# Here's your application

echo "************************** HERE IS YOUR APP!!! **************************"
kubectl get ingress -n development front-end-development-ingress | grep bookstore | awk '{print $3}'
echo "**************************"

# Create the VPC CNI Addon (ignore if it already exists)
    aws eks create-addon --addon-name vpc-cni --cluster-name eks-acg 2>/dev/null || true

echo "*************************************************************"
echo "********* READY TO CHAPTER 3! - FINISHED AT $(date) *********"
echo "*************************************************************"