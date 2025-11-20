#!/usr/bin/env bash
set -e

#
# Utility: wait for a CRD to be established
#
wait_for_crd() {
  local crd="$1"
  local timeout=60
  local interval=2

  echo "⏳ Waiting for CRD '${crd}'..."

  while [ $timeout -gt 0 ]; do
    if kubectl get crd "${crd}" >/dev/null 2>&1; then
      if kubectl wait --for=condition=Established crd/"${crd}" --timeout=30s >/dev/null 2>&1; then
        echo "✅ CRD '${crd}' is ready!"
        return 0
      fi
    fi

    sleep $interval
    timeout=$((timeout - interval))
  done

  echo "❌ Timeout waiting for CRD '${crd}'"
  exit 1
}


echo "Adding required Helm repositories..."
helm repo add jetstack https://charts.jetstack.io
helm repo add external-secrets https://charts.external-secrets.io
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update


# ------------------------------------------------------------------------------
# cert-manager
# ------------------------------------------------------------------------------
echo "Installing cert-manager..."
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager --create-namespace \
  -f cert-manager/values.yaml

# cert-manager CRDs
wait_for_crd "certificates.cert-manager.io"
wait_for_crd "issuers.cert-manager.io"
wait_for_crd "clusterissuers.cert-manager.io"


# ------------------------------------------------------------------------------
# External Secrets Operator (Infisical)
# ------------------------------------------------------------------------------
echo "Installing External Secrets Operator..."
helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets --create-namespace \
  -f infisical/values.yaml

# ESO CRDs
wait_for_crd "clustersecretstores.external-secrets.io"
wait_for_crd "secretstores.external-secrets.io"
wait_for_crd "externalsecrets.external-secrets.io"

echo "Waiting for External Secrets Operator components to be ready..."
kubectl -n external-secrets rollout status deploy/external-secrets --timeout=120s
kubectl -n external-secrets rollout status deploy/external-secrets-webhook --timeout=120s
kubectl -n external-secrets rollout status deploy/external-secrets-cert-controller --timeout=120s


echo "Creating Infisical universal-auth secret..."
kubectl create secret generic infisical-auth \
  -n external-secrets \
  --from-literal=clientId="$INFISICAL_CLIENT_ID" \
  --from-literal=clientSecret="$INFISICAL_CLIENT_SECRET" \
  --dry-run=client -o yaml | kubectl apply -f -


echo "Applying Infisical ClusterSecretStore..."
kubectl apply -f infisical/secretstore.yaml


# ------------------------------------------------------------------------------
# external-dns
# ------------------------------------------------------------------------------

echo "Creating namespace external-dns..."
kubectl create namespace external-dns --dry-run=client -o yaml | kubectl apply -f -

echo "Applying Cloudflare ExternalSecret..."
kubectl apply -f external-dns/secret.yaml

echo "Waiting for external-dns secret to be created..."
if ! kubectl -n external-dns wait --for=condition=Ready --timeout=60s externalsecret/cloudflare-api-token; then
  echo "❌ ExternalSecret cloudflare-api-token FAILED to become Ready"
  exit 1
fi

echo "Checking if Cloudflare secret exists..."
kubectl -n external-dns get secret cloudflare-api-token -o yaml

echo "Installing external-dns..."
helm upgrade --install external-dns external-dns/external-dns \
  --namespace external-dns --create-namespace \
  -f external-dns/values.yaml

# ------------------------------------------------------------------------------
# ArgoCD
# ------------------------------------------------------------------------------
echo "Installing ArgoCD..."
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd --create-namespace \
  -f argocd/values.yaml

# ArgoCD CRDs
wait_for_crd "applications.argoproj.io"
wait_for_crd "appprojects.argoproj.io"

echo "Waiting for ArgoCD server to be ready..."
kubectl -n argocd rollout status deploy/argocd-server --timeout=120s

# -------------------------------------------------------------------------------
# Apply cluster configuration
# -------------------------------------------------------------------------------
echo "Bootstrapping ArgoCD with cluster configuration..."
kubectl apply -f ../cluster/root-cluster.yaml
echo "Applying root applications..."
kubectl apply -f ../apps/root-apps.yaml