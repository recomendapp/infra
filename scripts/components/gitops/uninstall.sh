#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$SCRIPT_DIR/../../lib/common.sh"

main() {
    log_component "Uninstalling GitOps Applications"
    
    log_warning "This will remove all ArgoCD Applications defined in root-apps.yaml"
    log_warning "⚠️  Actual application resources may remain unless cascade delete is set"
    read -p "Are you sure? [y/N] " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Cancelled"
        return 0
    fi
    
    log_info "Deleting root applications..."
    kubectl delete -f "$PROJECT_ROOT/apps/root-apps.yaml" --timeout=60s 2>/dev/null || log_warning "Root apps not found"
    
    log_info "Deleting cluster configuration..."
    kubectl delete -f "$PROJECT_ROOT/cluster/root-cluster.yaml" --timeout=60s 2>/dev/null || log_warning "Cluster config not found"
    
    # Optional: Delete all applications in argocd namespace
    read -p "Also delete ALL ArgoCD applications? [y/N] " delete_all
    if [[ "$delete_all" =~ ^[Yy]$ ]]; then
        log_info "Deleting all ArgoCD applications..."
        kubectl delete applications --all -n argocd --timeout=120s 2>/dev/null || log_warning "No applications found"
    fi
    
    log_success "GitOps applications removed"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi