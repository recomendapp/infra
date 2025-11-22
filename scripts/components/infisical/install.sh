#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$SCRIPT_DIR/../../lib/common.sh"

main() {
    log_component "Infisical Configuration"
    
    # Check environment variables
    check_env_vars "INFISICAL_CLIENT_ID" "INFISICAL_CLIENT_SECRET" || return 1
    
    log_info "Creating Infisical universal-auth secret..."
    kubectl create secret generic infisical-auth \
        -n external-secrets \
        --from-literal=clientId="$INFISICAL_CLIENT_ID" \
        --from-literal=clientSecret="$INFISICAL_CLIENT_SECRET" \
        --dry-run=client -o yaml | kubectl apply -f - >/dev/null
    
    log_info "Applying Infisical ClusterSecretStore..."
    kubectl apply -f "$PROJECT_ROOT/bootstrap/infisical/secretstore.yaml" >/dev/null
    
    log_success "Infisical configured successfully"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi