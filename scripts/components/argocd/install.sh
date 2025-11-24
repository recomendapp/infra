#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/wait.sh"
source "$SCRIPT_DIR/../../lib/helm.sh"

main() {
    log_component "ArgoCD"
    
    ensure_helm_repos "argo"
    
    # Install ArgoCD
    log_info "Installing ArgoCD..."
    helm upgrade --install argocd argo/argo-cd \
        --namespace argocd --create-namespace \
        --values "$PROJECT_ROOT/bootstrap/argocd/values.yaml" \
        --wait
    
    wait_for_crd "applications.argoproj.io" || return 1
    wait_for_crd "appprojects.argoproj.io" || return 1
    wait_for_deployment "argocd" "argocd-server" || return 1
    
    # GitHub Docker credentials
    log_info "Creating GitHub Docker credentials..."
    kubectl apply -f "$PROJECT_ROOT/bootstrap/argocd/github-credentials.yaml" >/dev/null
    wait_for_externalsecret "argocd" "github-credentials" || return 1
    
    # GitHub repo credentials
    log_info "Creating GitHub repository credentials..."
    kubectl apply -f "$PROJECT_ROOT/bootstrap/argocd/github-repo.yaml" >/dev/null
    wait_for_externalsecret "argocd" "github-repo" || return 1
   
    log_success "ArgoCD installed successfully"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi