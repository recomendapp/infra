#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$SCRIPT_DIR/../../lib/common.sh"

main() {
    log_component "GitOps Applications"
    
    log_info "Applying cluster configuration..."
    kubectl apply -f "$PROJECT_ROOT/cluster/root-cluster.yaml" >/dev/null
    
    log_info "Applying root applications..."
    kubectl apply -f "$PROJECT_ROOT/apps/root-apps.yaml" >/dev/null
    
    log_success "GitOps configured - ArgoCD will sync applications"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi