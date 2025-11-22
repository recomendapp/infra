#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

main() {
    log_component "Validating Velero"
    
    local errors=0
    
    # Check namespace
    if kubectl get namespace velero >/dev/null 2>&1; then
        log_success "Namespace exists"
    else
        log_error "Namespace not found"
        ((errors++))
    fi
    
    # Check deployment
    if kubectl -n velero get deploy velero >/dev/null 2>&1; then
        if kubectl -n velero rollout status deploy/velero --timeout=5s >/dev/null 2>&1; then
            log_success "Deployment velero is ready"
        else
            log_warning "Deployment velero exists but not ready"
            ((errors++))
        fi
    else
        log_error "Deployment velero not found"
        ((errors++))
    fi
    
    # Check node-agent daemonset (CRITICAL for volume restore)
    log_info "Checking node-agent daemonset..."
    if kubectl -n velero get daemonset node-agent >/dev/null 2>&1; then
        local desired=$(kubectl -n velero get daemonset node-agent -o jsonpath='{.status.desiredNumberScheduled}')
        local ready=$(kubectl -n velero get daemonset node-agent -o jsonpath='{.status.numberReady}')
        
        if [ "$desired" = "$ready" ] && [ "$ready" -gt 0 ]; then
            log_success "node-agent daemonset is ready ($ready/$desired pods)"
        else
            log_error "node-agent daemonset not ready ($ready/$desired pods)"
            log_info "This is REQUIRED for volume backup/restore!"
            ((errors++))
        fi
    else
        log_error "node-agent daemonset not found"
        log_error "Volume backup/restore will NOT work!"
        log_info "Add 'deployNodeAgent: true' to velero values.yaml"
        ((errors++))
    fi
    
    # Check BackupStorageLocation
    if kubectl -n velero get backupstoragelocation default >/dev/null 2>&1; then
        local phase=$(kubectl -n velero get backupstoragelocation default -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
        if [ "$phase" = "Available" ]; then
            log_success "BackupStorageLocation is Available"
        else
            log_warning "BackupStorageLocation phase: $phase"
            ((errors++))
        fi
    else
        log_error "BackupStorageLocation not found"
        ((errors++))
    fi
    
    # Check if backups are visible
    log_info "Checking for backups..."
    local backup_count=$(kubectl -n velero get backups --no-headers 2>/dev/null | wc -l | tr -d ' ')
    if [ "$backup_count" -gt 0 ]; then
        log_success "Found $backup_count backup(s)"
    else
        log_warning "No backups found (may take a moment to sync)"
    fi
    
    # Check ExternalSecret
    if kubectl -n velero get externalsecret velero-credentials >/dev/null 2>&1; then
        log_success "ExternalSecret velero-credentials exists"
    else
        log_warning "ExternalSecret velero-credentials not found"
    fi
    
    if [ $errors -eq 0 ]; then
        log_success "Velero validation passed"
        return 0
    else
        log_error "Velero validation failed with $errors error(s)"
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi