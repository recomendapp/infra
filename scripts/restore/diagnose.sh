#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../lib/common.sh"

main() {
    log_section "🔍 Velero Restore Diagnostics"
    
    if [ -z "$1" ]; then
        echo "Usage: $0 <restore-name>"
        echo ""
        echo "Available restores:"
        kubectl get restores -n velero --no-headers 2>/dev/null | awk '{print "  - " $1}'
        exit 1
    fi
    
    local restore_name="$1"
    
    log_info "Checking restore: $restore_name"
    echo ""
    
    # Restore status
    log_component "Restore Status"
    kubectl -n velero get restore "$restore_name" -o wide 2>/dev/null || {
        log_error "Restore not found"
        exit 1
    }
    
    echo ""
    
    # Restore details
    log_component "Restore Details"
    velero restore describe "$restore_name" 2>/dev/null || true
    
    echo ""
    
    # PodVolumeRestores
    log_component "PodVolumeRestores"
    kubectl get podvolumerestores -n velero -l velero.io/restore-name="$restore_name" 2>/dev/null || {
        log_warning "No PodVolumeRestores found"
    }
    
    echo ""
    
    # Check node-agent pods
    log_component "Node-Agent Pods"
    if kubectl get pods -n velero -l name=node-agent >/dev/null 2>&1; then
        kubectl get pods -n velero -l name=node-agent -o wide
        echo ""
        
        log_info "Node-agent logs (last 20 lines):"
        kubectl logs -n velero -l name=node-agent --tail=20 --prefix=true 2>/dev/null || true
    else
        log_error "No node-agent pods found!"
        log_error "This is why volume restore is not working!"
        echo ""
        log_info "Fix: Reinstall Velero with deployNodeAgent: true"
    fi
    
    echo ""
    
    # Velero main pod logs
    log_component "Velero Main Pod Logs (last 30 lines)"
    kubectl logs -n velero deploy/velero --tail=30 2>/dev/null || true
    
    echo ""
    
    # Check PVCs in target namespace
    log_component "PVCs Status"
    local namespaces=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | grep -v 'kube-\|velero\|cert-manager\|external-secrets')
    
    for ns in $namespaces; do
        local pvc_count=$(kubectl get pvc -n "$ns" --no-headers 2>/dev/null | wc -l | tr -d ' ')
        if [ "$pvc_count" -gt 0 ]; then
            echo "Namespace: $ns"
            kubectl get pvc -n "$ns" 2>/dev/null || true
            echo ""
        fi
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi