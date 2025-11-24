#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPONENTS_DIR="$SCRIPT_DIR/../components"

source "$SCRIPT_DIR/../lib/common.sh"

main() {
    log_section "🚀 Full Cluster Bootstrap"
    
    check_kubectl || exit 1
    
    log_info "This script will install foundational components (cert-manager, external-secrets, infisical, argocd)
and then apply the root application to bootstrap the cluster."
    
    local components=(
        "cert-manager"
        "external-secrets"
        "infisical"
		"velero"
        "reflector"
        "argocd"
        "gitops"
    )
    
    for component in "${components[@]}"; do
        log_section "Installing Component: $component"
        local install_script="$COMPONENTS_DIR/$component/install.sh"
        if [ -f "$install_script" ]; then
            "$install_script" || {
                log_error "Failed to install $component"
                exit 1
            }
        else
            log_error "Install script not found for $component"
            exit 1
        fi
    done
    
    log_section "🎉 Bootstrap Complete!"
    echo ""
    log_info "Next steps:"
    echo "  • Check ArgoCD: make argocd-ui"
    echo "  • View password: make argocd-password"
}

main "$@"