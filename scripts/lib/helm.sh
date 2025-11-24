#!/usr/bin/env bash

# Helm repositories registry
declare -A HELM_REPOS=(
    ["jetstack"]="https://charts.jetstack.io"
    ["external-secrets"]="https://charts.external-secrets.io"
    ["external-dns"]="https://kubernetes-sigs.github.io/external-dns/"
    ["argo"]="https://argoproj.github.io/argo-helm"
    ["vmware-tanzu"]="https://vmware-tanzu.github.io/helm-charts"
    ["emberstack"]="https://emberstack.github.io/helm-charts"
)

# Add a specific Helm repo
add_helm_repo() {
    local name="$1"
    local url="${HELM_REPOS[$name]}"
    
    if [ -z "$url" ]; then
        log_error "Unknown Helm repository: $name"
        return 1
    fi
    
    if helm repo list 2>/dev/null | grep -q "^$name"; then
        log_info "Helm repo '$name' already added"
    else
        log_info "Adding Helm repo '$name'..."
        helm repo add "$name" "$url" >/dev/null 2>&1
    fi
}

# Update Helm repos
update_helm_repos() {
    log_info "Updating Helm repositories..."
    helm repo update >/dev/null 2>&1
}

# Add multiple repos and update
ensure_helm_repos() {
    local repos=("$@")
    
    for repo in "${repos[@]}"; do
        add_helm_repo "$repo"
    done
    
    update_helm_repos
}