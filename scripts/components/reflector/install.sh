#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Libraries
source "$SCRIPT_DIR/../../lib/common.sh"
source "$SCRIPT_DIR/../../lib/wait.sh"
source "$SCRIPT_DIR/../../lib/helm.sh"

main() {
    log_component "reflector"

    ensure_helm_repos "emberstack"

    log_info "Installing Reflector..."
    helm upgrade --install reflector emberstack/reflector \
        --namespace kube-system \
        --create-namespace \
        --values "$PROJECT_ROOT/bootstrap/reflector/values.yaml" \
        --wait

    wait_for_deployment "kube-system" "reflector" || return 1

    log_success "Reflector installed successfully"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
