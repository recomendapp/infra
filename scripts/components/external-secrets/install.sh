#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/wait.sh"
source "$SCRIPT_DIR/../../lib/helm.sh"

main() {
    log_component "External Secrets Operator"
    
    ensure_helm_repos "external-secrets"
    
    log_info "Installing External Secrets Operator..."
    helm upgrade --install external-secrets external-secrets/external-secrets \
        --namespace external-secrets --create-namespace \
        --values "$PROJECT_ROOT/bootstrap/infisical/values.yaml" \
        --wait
    
    # Wait for CRDs
    wait_for_crd "clustersecretstores.external-secrets.io" || return 1
    wait_for_crd "secretstores.external-secrets.io" || return 1
    wait_for_crd "externalsecrets.external-secrets.io" || return 1
    
    # Wait for deployments
    wait_for_deployment "external-secrets" "external-secrets" || return 1
    wait_for_deployment "external-secrets" "external-secrets-webhook" || return 1
    wait_for_deployment "external-secrets" "external-secrets-cert-controller" || return 1
    
    log_success "External Secrets Operator installed successfully"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi