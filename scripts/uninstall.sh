#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPONENTS_DIR="$SCRIPT_DIR/components"

source "$SCRIPT_DIR/lib/common.sh"

show_menu() {
    clear
    log_section "🗑️  CLUSTER CLEANUP"
    echo "Choose what to uninstall:"
    echo ""
    echo "1️⃣  Full cleanup (everything)"
    echo "2️⃣  GitOps applications only"
    echo "3️⃣  ArgoCD only"
    echo "4️⃣  Velero only"
    echo "5️⃣  DNS (external-dns) only"
    echo "6️⃣  Secrets management (External Secrets + Infisical)"
    echo "7️⃣  cert-manager only"
    echo "8️⃣  Custom (select components)"
    echo "9️⃣  Exit"
    echo ""
    read -p "Select option [1-9]: " choice
    
    case $choice in
        1) full_cleanup ;;
        2) uninstall_component "gitops" ;;
        3) uninstall_component "argocd" ;;
        4) uninstall_component "velero" ;;
        5) uninstall_component "external-dns" ;;
        6) uninstall_secrets ;;
        7) uninstall_component "cert-manager" ;;
        8) custom_cleanup ;;
        9) exit 0 ;;
        *) log_error "Invalid option"; show_menu ;;
    esac
}

uninstall_component() {
    local component="$1"
    local script="$COMPONENTS_DIR/$component/uninstall.sh"
    
    if [ -f "$script" ]; then
        "$script"
    else
        log_error "Uninstall script not found for $component"
        exit 1
    fi
}

uninstall_secrets() {
    log_section "Uninstalling Secrets Management Stack"
    uninstall_component "infisical"
    uninstall_component "external-secrets"
}

full_cleanup() {
    log_section "🔴 FULL CLUSTER CLEANUP"
    
    log_warning "This will remove EVERYTHING:"
    echo "  • GitOps applications"
    echo "  • ArgoCD"
    echo "  • Velero"
    echo "  • external-dns"
    echo "  • Infisical"
    echo "  • External Secrets"
    echo "  • cert-manager"
    echo ""
    log_error "This is DESTRUCTIVE and CANNOT be undone!"
    echo ""
    read -p "Type 'DELETE' to confirm: " confirm
    
    if [ "$confirm" != "DELETE" ]; then
        log_info "Cancelled"
        exit 0
    fi
    
    log_info "Starting full cleanup (in reverse order)..."
    
    # Uninstall in reverse dependency order
    local components=(
        "gitops"
        "argocd"
        "velero"
        "external-dns"
        "infisical"
        "external-secrets"
        "cert-manager"
    )
    
    for component in "${components[@]}"; do
        log_section "Uninstalling $component"
        if [ -f "$COMPONENTS_DIR/$component/uninstall.sh" ]; then
            # Run non-interactively for full cleanup
            yes | "$COMPONENTS_DIR/$component/uninstall.sh" 2>/dev/null || true
        else
            log_warning "Uninstall script not found for $component, skipping..."
        fi
    done
    
    log_section "🎉 Full Cleanup Complete"
    log_info "Cluster is now clean"
}

custom_cleanup() {
    log_section "Custom Cleanup"
    
    echo "Available components:"
    echo "  1. gitops"
    echo "  2. argocd"
    echo "  3. velero"
    echo "  4. external-dns"
    echo "  5. infisical"
    echo "  6. external-secrets"
    echo "  7. cert-manager"
    echo ""
    read -p "Enter component numbers to uninstall (space-separated, e.g., '1 2 3'): " choices
    
    local component_map=(
        ""
        "gitops"
        "argocd"
        "velero"
        "external-dns"
        "infisical"
        "external-secrets"
        "cert-manager"
    )
    
    for choice in $choices; do
        if [ "$choice" -ge 1 ] && [ "$choice" -le 7 ]; then
            local component="${component_map[$choice]}"
            log_section "Uninstalling $component"
            uninstall_component "$component"
        else
            log_warning "Invalid choice: $choice"
        fi
    done
    
    log_success "Custom cleanup complete"
}

# Main
if ! kubectl cluster-info >/dev/null 2>&1; then
    log_error "Cannot connect to Kubernetes cluster"
    exit 1
fi

show_menu