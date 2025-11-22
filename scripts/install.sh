#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPONENTS_DIR="$SCRIPT_DIR/components"

source "$SCRIPT_DIR/lib/common.sh"

main() {
    log_section "🚀 Full Cluster Bootstrap"
    
    check_kubectl || exit 1
    
    log_info "This script will install ArgoCD and then apply the root application to bootstrap the cluster."
    
    # 1. Install ArgoCD
    if [ -f "$COMPONENTS_DIR/argocd/install.sh" ]; then
        "$COMPONENTS_DIR/argocd/install.sh" || {
            log_error "Failed to install ArgoCD"
            exit 1
        }
    else
        log_error "Install script not found for ArgoCD"
        exit 1
    fi
    
    # 2. Install GitOps root application
    if [ -f "$COMPONENTS_DIR/gitops/install.sh" ]; then
        "$COMPONENTS_DIR/gitops/install.sh" || {
            log_error "Failed to apply root GitOps application"
            exit 1
        }
    else
        log_error "Install script not found for GitOps"
        exit 1
    fi
    
    log_section "🎉 Bootstrap Complete!"
    echo ""
    log_info "Next steps:"
    echo "  • Check ArgoCD: make argocd-ui"
    echo "  • View password: make argocd-password"
}

main "$@"
