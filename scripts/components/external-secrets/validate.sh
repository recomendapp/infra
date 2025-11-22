#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/wait.sh"

main() {
    log_component "Validating External Secrets Operator"
    
    local errors=0
    
    # Check namespace
    if kubectl get namespace external-secrets >/dev/null 2>&1; then
        log_success "Namespace exists"
    else
        log_error "Namespace not found"
        ((errors++))
    fi
    
    # Check CRDs
    local crds=("clustersecretstores.external-secrets.io" "secretstores.external-secrets.io" "externalsecrets.external-secrets.io")
    for crd in "${crds[@]}"; do
        if kubectl get crd "$crd" >/dev/null 2>&1; then
            log_success "CRD $crd exists"
        else
            log_error "CRD $crd not found"
            ((errors++))
        fi
    done
    
    # Check deployments
    local deployments=("external-secrets" "external-secrets-webhook" "external-secrets-cert-controller")
    for deploy in "${deployments[@]}"; do
        if kubectl -n external-secrets get deploy "$deploy" >/dev/null 2>&1; then
            if kubectl -n external-secrets rollout status deploy/"$deploy" --timeout=5s >/dev/null 2>&1; then
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
        log_success "External Secrets Operator validation passed"
        return 0
    else
        log_error "External Secrets Operator validation failed with $errors error(s)"
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi