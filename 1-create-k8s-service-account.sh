#!/bin/bash

# To be run on the host

# Create a k8s service account for vault

kubectl create serviceaccount vault-auth

# Update vault-auth service account to use included configuration
kubectl apply --filename vault-k8s/vault-auth-service-account.yml

cat <<EOF > kube_sa_info
# Set VAULT_SA_NAME to the service account you created earlier
export VAULT_SA_NAME=$(kubectl get sa vault-auth -o jsonpath="{.secrets[*]['name']}")

EOF

. kube_sa_info

cat <<EOF >> kube_sa_info
# Set SA_JWT_TOKEN value to the service account JWT used to access the TokenReview API
export SA_JWT_TOKEN=$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data.token}" | base64 --decode; echo)

# Set SA_CA_CRT to the PEM encoded CA cert used to talk to Kubernetes API
export SA_CA_CRT="$(kubectl get secret $VAULT_SA_NAME -o jsonpath="{.data['ca\.crt']}" | base64 --decode; echo)"

# Set K8S_HOST to minikube IP address
export K8S_HOST=$(minikube ip)
EOF
