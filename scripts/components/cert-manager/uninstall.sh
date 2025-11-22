#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

main() {
    log_component "Uninstalling cert-manager"
    
    log_warning "This will remove cert-manager and all its resources"
    read -p "Are you sure? [y/N] " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Cancelled"
        return 0
    fi
    
    log_info "Uninstalling Helm release..."
    helm uninstall cert-manager -n cert-manager 2>/dev/null || log_warning "Helm release not found"
    
    log_info "Deleting namespace..."
    kubectl delete namespace cert-manager --timeout=60s 2>/dev/null || log_warning "Namespace not found"
    
    log_success "cert-manager uninstalled"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi