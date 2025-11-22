#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/wait.sh"

main() {
    log_component "Validating cert-manager"
    
    local errors=0
    
    # Check namespace
    if kubectl get namespace cert-manager >/dev/null 2>&1; then
        log_success "Namespace exists"
    else
        log_error "Namespace not found"
        ((errors++))
    fi
    
    # Check CRDs
    local crds=("certificates.cert-manager.io" "issuers.cert-manager.io" "clusterissuers.cert-manager.io")
    for crd in "${crds[@]}"; do
        if kubectl get crd "$crd" >/dev/null 2>&1; then
            log_success "CRD $crd exists"
        else
            log_error "CRD $crd not found"
            ((errors++))
        fi
    done
    
    # Check deployments
    local deployments=("cert-manager" "cert-manager-webhook" "cert-manager-cainjector")
    for deploy in "${deployments[@]}"; do
        if kubectl -n cert-manager get deploy "$deploy" >/dev/null 2>&1; then
            if kubectl -n cert-manager rollout status deploy/"$deploy" --timeout=5s >/dev/null 2>&1; then
                log_success "Deployment $deploy is ready"
            else
                log_warning "Deployment $deploy exists but not ready"
                ((errors++))
            fi
        else
            log_error "Deployment $deploy not found"
            ((errors++))
        fi
    done
    
    if [ $errors -eq 0 ]; then
        log_success "cert-manager validation passed"
        return 0
    else
        log_error "cert-manager validation failed with $errors error(s)"
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi