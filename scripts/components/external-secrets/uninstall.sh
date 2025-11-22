#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

main() {
    log_component "Uninstalling External Secrets Operator"
    
    log_warning "This will remove External Secrets Operator and all its resources"
    log_warning "⚠️  This will break all ExternalSecrets in the cluster!"
    read -p "Are you sure? [y/N] " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Cancelled"
        return 0
    fi
    
    # Delete all ExternalSecrets first (to prevent orphaned secrets)
    log_info "Deleting all ExternalSecrets..."
    kubectl delete externalsecrets --all -A --timeout=30s 2>/dev/null || log_warning "No ExternalSecrets found"
    
    # Delete SecretStores
    log_info "Deleting SecretStores..."
    kubectl delete secretstores --all -A --timeout=30s 2>/dev/null || log_warning "No SecretStores found"
    
    # Delete ClusterSecretStores
    log_info "Deleting ClusterSecretStores..."
    kubectl delete clustersecretstores --all --timeout=30s 2>/dev/null || log_warning "No ClusterSecretStores found"
    
    # Uninstall Helm release
    log_info "Uninstalling Helm release..."
    helm uninstall external-secrets -n external-secrets 2>/dev/null || log_warning "Helm release not found"
    
    # Delete namespace
    log_info "Deleting namespace..."
    kubectl delete namespace external-secrets --timeout=60s 2>/dev/null || log_warning "Namespace not found"
    
    # Clean up CRDs (optional, commented out by default as it's destructive)
    # log_warning "Cleaning up CRDs..."
    # kubectl delete crd clustersecretstores.external-secrets.io 2>/dev/null || true
    # kubectl delete crd secretstores.external-secrets.io 2>/dev/null || true
    # kubectl delete crd externalsecrets.external-secrets.io 2>/dev/null || true
    
    log_success "External Secrets Operator uninstalled"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi