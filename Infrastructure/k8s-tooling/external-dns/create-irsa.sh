helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/

service_account_name="external-dns-service-account"

eksctl create iamserviceaccount --name ${service_account_name} \
    --cluster eks-acg \
    --attach-policy-arn arn:aws:iam::aws:policy/AmazonRoute53FullAccess --approve

helm upgrade --install external-dns \
    --set provider=aws \
    --set extraEnv[0].name=AWS_REGION \
    --set extraEnv[0].value=us-east-1 \
    --set serviceAccount.create=false \
    --set serviceAccount.name=${service_account_name} \
    external-dns/external-dns