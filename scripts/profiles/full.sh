#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPONENTS_DIR="$SCRIPT_DIR/../components"

source "$SCRIPT_DIR/../lib/common.sh"

main() {
    log_section "🚀 Full Cluster Bootstrap"
    
    check_kubectl || exit 1
    
    local components=(
        "cert-manager"
        "external-secrets"
        "infisical"
        "external-dns"
        "argocd"
        "velero"
        "gitops"
    )
    
    for component in "${components[@]}"; do
        if [ -f "$COMPONENTS_DIR/$component/install.sh" ]; then
            "$COMPONENTS_DIR/$component/install.sh" || {
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
    echo "  • Check backups: make backup-status"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi