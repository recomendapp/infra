#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

main() {
    log_component "Validating ArgoCD"
    
    local errors=0
    
    # Check namespace
    if kubectl get namespace argocd >/dev/null 2>&1; then
        log_success "Namespace exists"
    else
        log_error "Namespace not found"
        ((errors++))
    fi
    
    # Check CRDs
    local crds=("applications.argoproj.io" "appprojects.argoproj.io")
    for crd in "${crds[@]}"; do
        if kubectl get crd "$crd" >/dev/null 2>&1; then
            log_success "CRD $crd exists"
        else
            log_error "CRD $crd not found"
            ((errors++))
        fi
    done
    
    # Check main deployments
	local deployments=(
		"argocd-server"
		"argocd-repo-server"
		"argocd-applicationset-controller"
	)
    for deploy in "${deployments[@]}"; do
        if kubectl -n argocd get deploy "$deploy" >/dev/null 2>&1; then
            if kubectl -n argocd rollout status deploy/"$deploy" --timeout=5s >/dev/null 2>&1; then
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
    
    # Check ExternalSecrets
    local secrets=("github-credentials" "github-repo")
    for secret in "${secrets[@]}"; do
        if kubectl -n argocd get externalsecret "$secret" >/dev/null 2>&1; then
            log_success "ExternalSecret $secret exists"
        else
            log_warning "ExternalSecret $secret not found"
        fi
    done
    
    if [ $errors -eq 0 ]; then
        log_success "ArgoCD validation passed"
        return 0
    else
        log_error "ArgoCD validation failed with $errors error(s)"
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi