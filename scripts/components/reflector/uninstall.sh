#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

main() {
    log_component "Uninstalling reflector"

    log_warning "This will remove Reflector from kube-system."
    read -p "Are you sure? [y/N] " confirm

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Cancelled"
        return 0
    fi

    log_info "Uninstalling Helm release..."
    helm uninstall reflector -n kube-system 2>/dev/null || log_warning "Helm release not found"

    log_success "Reflector uninstalled"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
