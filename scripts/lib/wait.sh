#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

# Wait for CRD to be established
wait_for_crd() {
    local crd="$1"
    local timeout=60
    local interval=2

    log_info "Waiting for CRD '${crd}'..."

    while [ $timeout -gt 0 ]; do
        if kubectl get crd "${crd}" >/dev/null 2>&1; then
            if kubectl wait --for=condition=Established crd/"${crd}" --timeout=30s >/dev/null 2>&1; then
                log_success "CRD '${crd}' is ready"
                return 0
            fi
        fi

        sleep $interval
        timeout=$((timeout - interval))
    done

    log_error "Timeout waiting for CRD '${crd}'"
    return 1
}

# Wait for deployment to be ready
wait_for_deployment() {
    local namespace="$1"
    local deployment="$2"
    local timeout="${3:-120s}"

    log_info "Waiting for deployment ${namespace}/${deployment}..."
    
    if kubectl -n "$namespace" rollout status deploy/"$deployment" --timeout="$timeout" >/dev/null 2>&1; then
        log_success "Deployment ${namespace}/${deployment} is ready"
        return 0
    else
        log_error "Deployment ${namespace}/${deployment} failed to become ready"
        return 1
    fi
}

# Wait for ExternalSecret to be ready
wait_for_externalsecret() {
    local namespace="$1"
    local name="$2"
    local timeout="${3:-60s}"

    log_info "Waiting for ExternalSecret ${namespace}/${name}..."
    
    if kubectl -n "$namespace" wait --for=condition=Ready --timeout="$timeout" externalsecret/"$name" >/dev/null 2>&1; then
        log_success "ExternalSecret ${namespace}/${name} is ready"
        return 0
    else
        log_error "ExternalSecret ${namespace}/${name} failed to become ready"
        return 1
    fi
}

# Wait for namespace to exist
wait_for_namespace() {
    local namespace="$1"
    local timeout=30
    local interval=2

    log_info "Waiting for namespace '${namespace}'..."

    while [ $timeout -gt 0 ]; do
        if kubectl get namespace "${namespace}" >/dev/null 2>&1; then
            log_success "Namespace '${namespace}' exists"
            return 0
        fi

        sleep $interval
        timeout=$((timeout - interval))
    done

    log_error "Timeout waiting for namespace '${namespace}'"
    return 1
}