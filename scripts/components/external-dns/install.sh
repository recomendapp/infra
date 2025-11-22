#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/wait.sh"
source "$SCRIPT_DIR/../../lib/helm.sh"

main() {
    log_component "external-dns"
    
    ensure_helm_repos "external-dns"
    
    log_info "Creating namespace..."
    kubectl create namespace external-dns --dry-run=client -o yaml | kubectl apply -f - >/dev/null
    
    log_info "Applying Cloudflare ExternalSecret..."
    kubectl apply -f "$PROJECT_ROOT/bootstrap/external-dns/secret.yaml" >/dev/null
    
    wait_for_externalsecret "external-dns" "cloudflare-api-token" || return 1
    
    log_info "Installing external-dns..."
    helm upgrade --install external-dns external-dns/external-dns \
        --namespace external-dns \
        --values "$PROJECT_ROOT/bootstrap/external-dns/values.yaml" \
        --wait
    
    log_success "external-dns installed successfully"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi