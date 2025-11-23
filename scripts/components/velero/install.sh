#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/wait.sh"
source "$SCRIPT_DIR/../../lib/helm.sh"

main() {
    log_component "Velero"
    
    ensure_helm_repos "vmware-tanzu"
    
    log_info "Creating namespace..."
    kubectl create namespace velero --dry-run=client -o yaml | kubectl apply -f - >/dev/null
    
    log_info "Applying Velero ExternalSecret..."
    kubectl apply -f "$PROJECT_ROOT/bootstrap/velero/secret.yaml" >/dev/null
    
    wait_for_externalsecret "velero" "velero-credentials" || return 1
    
    log_info "Installing Velero..."
    helm upgrade --install velero vmware-tanzu/velero \
        --namespace velero \
        --values "$PROJECT_ROOT/bootstrap/velero/values.yaml" \
        --set-string configuration.backupStorageLocation[0].bucket="$(kubectl -n velero get secret velero-credentials -o jsonpath='{.data.VELERO_R2_BUCKET}' | base64 -d)" \
        --set-string configuration.backupStorageLocation[0].config.s3Url="https://$(kubectl -n velero get secret velero-credentials -o jsonpath='{.data.VELERO_R2_ACCOUNT_ID}' | base64 -d).r2.cloudflarestorage.com" \
        --wait
    
    wait_for_deployment "velero" "velero" || return 1
    
    log_success "Velero installed successfully"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi