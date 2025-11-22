#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Source libraries
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/wait.sh"
source "$SCRIPT_DIR/../../lib/helm.sh"

main() {
    log_component "cert-manager"
    
    # Ensure Helm repos
    ensure_helm_repos "jetstack"
    
    log_info "Installing cert-manager..."
    helm upgrade --install cert-manager jetstack/cert-manager \
        --namespace cert-manager --create-namespace \
        --values "$PROJECT_ROOT/bootstrap/cert-manager/values.yaml" \
        --wait
    
    # Wait for CRDs
    wait_for_crd "certificates.cert-manager.io" || return 1
    wait_for_crd "issuers.cert-manager.io" || return 1
    wait_for_crd "clusterissuers.cert-manager.io" || return 1
    
    log_success "cert-manager installed successfully"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi