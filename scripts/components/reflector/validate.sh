#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/wait.sh"

main() {
    log_component "Validating reflector"

    local errors=0

    # Check namespace
    if kubectl get namespace kube-system >/dev/null 2>&1; then
        log_success "Namespace kube-system exists"
    else
        log_error "Namespace kube-system not found"
        ((errors++))
    fi

    # Check deployment
    if kubectl -n kube-system get deploy reflector >/dev/null 2>&1; then
        if kubectl -n kube-system rollout status deploy/reflector --timeout=5s >/dev/null 2>&1; then
            log_success "Deployment reflector is ready"
        else
            log_warning "Deployment reflector exists but not ready"
            ((errors++))
        fi
    else
        log_error "Deployment reflector not found"
        ((errors++))
    fi

    if [ $errors -eq 0 ]; then
        log_success "Reflector validation passed"
        return 0
    else
        log_error "Reflector validation failed with $errors error(s)"
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
