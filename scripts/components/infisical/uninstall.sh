#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

main() {
    log_component "Uninstalling Infisical Configuration"
    
    log_warning "This will remove Infisical ClusterSecretStore and auth secret"
    read -p "Are you sure? [y/N] " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Cancelled"
        return 0
    fi
    
    log_info "Deleting ClusterSecretStore..."
    kubectl delete clustersecretstore infisical 2>/dev/null || log_warning "ClusterSecretStore not found"
    
    log_info "Deleting auth secret..."
    kubectl delete secret infisical-auth -n external-secrets 2>/dev/null || log_warning "Auth secret not found"
    
    log_success "Infisical configuration removed"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi