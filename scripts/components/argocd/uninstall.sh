#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

main() {
    log_component "Uninstalling ArgoCD"
    
    log_warning "This will remove ArgoCD and ALL its applications!"
    log_warning "⚠️  All GitOps-managed resources will become orphaned!"
    read -p "Are you sure? [y/N] " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Cancelled"
        return 0
    fi
    
    # Delete all Applications first
    log_info "Deleting all ArgoCD Applications..."
    kubectl delete applications --all -n argocd --timeout=60s 2>/dev/null || log_warning "No Applications found"
    
    # Delete all AppProjects
    log_info "Deleting all AppProjects..."
    kubectl delete appprojects --all -n argocd --timeout=30s 2>/dev/null || log_warning "No AppProjects found"

    # Delete ExternalSecrets
    log_info "Deleting GitHub credentials..."
    kubectl delete externalsecret github-credentials -n argocd 2>/dev/null || log_warning "ExternalSecret not found"
    kubectl delete externalsecret github-repo -n argocd 2>/dev/null || log_warning "ExternalSecret not found"
    
    # Delete secrets
    kubectl delete secret github-credentials -n argocd 2>/dev/null || true
    kubectl delete secret github-repo -n argocd 2>/dev/null || true
    
    # Uninstall Helm release
    log_info "Uninstalling ArgoCD Helm release..."
    helm uninstall argocd -n argocd 2>/dev/null || log_warning "Helm release not found"
    
    # Delete namespace
	log_info "Deleting namespace..."
	kubectl delete namespace argocd --timeout=30s 2>/dev/null || true

	# Force delete CRDs that block namespace deletion
	log_info "Removing leftover ArgoCD CRDs..."
	kubectl delete crd applications.argoproj.io --ignore-not-found
	kubectl delete crd applicationsets.argoproj.io --ignore-not-found
	kubectl delete crd appprojects.argoproj.io --ignore-not-found

	# Retry namespace deletion now that CRDs are gone
	log_info "Final namespace cleanup..."
	kubectl delete ns argocd --force --grace-period=0 --ignore-not-found
    log_success "ArgoCD uninstalled"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi