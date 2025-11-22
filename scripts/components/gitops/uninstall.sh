#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$SCRIPT_DIR/../../lib/common.sh"

main() {
    log_component "GitOps Root Application"
    
    log_info "Deleting the root application to tear down the cluster..."
    kubectl delete -f "$PROJECT_ROOT/cluster/root.yaml" --ignore-not-found=true >/dev/null
    
    log_success "GitOps root application deleted - ArgoCD will now prune all applications"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
