#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPONENTS_DIR="$SCRIPT_DIR/components"

source "$SCRIPT_DIR/lib/common.sh"

main() {
    if ! kubectl cluster-info >/dev/null 2>&1; then
        log_error "Cannot connect to Kubernetes cluster"
        exit 1
    fi

    clear
    log_section "🗑️  Cluster Uninstall"
    echo "Choose what to uninstall:"
    echo ""
    echo "1. Uninstall All GitOps Applications (keeps ArgoCD)"
    echo "2. Uninstall ArgoCD itself (run after step 1)"
    echo "3. Exit"
    echo ""
    read -p "Select option [1-3]: " choice

    case $choice in
        1) uninstall_gitops_apps ;;
        2) uninstall_argocd ;;
        3) exit 0 ;;
        *) log_error "Invalid option";;
    esac
}

uninstall_gitops_apps() {
    log_section "Uninstalling all GitOps Applications"
    log_warning "This will delete all applications managed by ArgoCD based on the 'root.yaml' application."
    read -p "Are you sure? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        "$COMPONENTS_DIR/gitops/uninstall.sh"
    else
        log_info "Cancelled"
    fi
}

uninstall_argocd() {
    log_section "Uninstalling ArgoCD"
    log_warning "This will remove the ArgoCD controller. You should uninstall the GitOps applications first."
    read -p "Are you sure? [y/N] " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        if [ -f "$COMPONENTS_DIR/argocd/uninstall.sh" ]; then
            "$COMPONENTS_DIR/argocd/uninstall.sh"
        else
            log_error "ArgoCD uninstall script not found!"
        fi
    else
        log_info "Cancelled"
    fi
}

main "$@"
