#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

main() {
    log_component "Uninstalling external-dns"
    
    log_warning "This will remove external-dns"
    log_warning "⚠️  DNS records will no longer be automatically managed!"
    read -p "Are you sure? [y/N] " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Cancelled"
        return 0
    fi
    
    log_info "Deleting ExternalSecret..."
    kubectl delete externalsecret cloudflare-api-token -n external-dns 2>/dev/null || log_warning "ExternalSecret not found"
    
    log_info "Deleting secret..."
    kubectl delete secret cloudflare-api-token -n external-dns 2>/dev/null || log_warning "Secret not found"
    
    log_info "Uninstalling Helm release..."
    helm uninstall external-dns -n external-dns 2>/dev/null || log_warning "Helm release not found"
    
    log_info "Deleting namespace..."
    kubectl delete namespace external-dns --timeout=60s 2>/dev/null || log_warning "Namespace not found"
    
    log_success "external-dns uninstalled"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi