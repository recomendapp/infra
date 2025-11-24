#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPONENTS_DIR="$SCRIPT_DIR/../components"

source "$SCRIPT_DIR/../lib/common.sh"

main() {
    log_section "🔧 Minimal Bootstrap (Disaster Recovery)"
    
    check_kubectl || exit 1
    
    log_info "Installing only core components + Velero for restore..."
    
    local components=(
        "cert-manager"
        "external-secrets"
        "infisical"
        "velero"
        "reflector"
    )
    
    for component in "${components[@]}"; do
        if [ -f "$COMPONENTS_DIR/$component/install.sh" ]; then
            "$COMPONENTS_DIR/$component/install.sh" || {
                log_error "Failed to install $component"
                exit 1
            }
        fi
    done
    
    log_success "Minimal bootstrap complete - ready for Velero restore"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi