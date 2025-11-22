#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$SCRIPT_DIR/../../lib/common.sh"

main() {
    log_component "GitOps Root Application"
    
    log_info "Applying the root application to bootstrap the cluster..."
    kubectl apply -f "$PROJECT_ROOT/cluster/root.yaml" >/dev/null
    
    log_success "GitOps configured - ArgoCD will now sync all applications"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
