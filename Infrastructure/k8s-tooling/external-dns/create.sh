helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
helm upgrade --install external-dns external-dns/external-dns \
    --set provider=aws \
    --set extraEnv[0].name=AWS_REGION \
    --set extraEnv[0].value=us-east-1