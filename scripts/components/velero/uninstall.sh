#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

main() {
    log_component "Uninstalling Velero"
    
    log_warning "This will remove Velero"
    log_warning "⚠️  Backup/restore functionality will be lost!"
    log_warning "⚠️  Existing backups in storage will NOT be deleted"
    read -p "Are you sure? [y/N] " confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Cancelled"
        return 0
    fi
    
    # Delete all Backups
    log_info "Deleting Backup resources (not the actual backup data)..."
    kubectl delete backups --all -n velero --timeout=30s 2>/dev/null || log_warning "No Backups found"
    
    # Delete all Restores
    log_info "Deleting Restore resources..."
    kubectl delete restores --all -n velero --timeout=30s 2>/dev/null || log_warning "No Restores found"
    
    # Delete BackupStorageLocations
    log_info "Deleting BackupStorageLocations..."
    kubectl delete backupstoragelocations --all -n velero --timeout=30s 2>/dev/null || log_warning "No BackupStorageLocations found"
    
    # Delete VolumeSnapshotLocations
    log_info "Deleting VolumeSnapshotLocations..."
    kubectl delete volumesnapshotlocations --all -n velero --timeout=30s 2>/dev/null || log_warning "No VolumeSnapshotLocations found"
    
    # Delete Schedules
    log_info "Deleting Schedules..."
    kubectl delete schedules --all -n velero --timeout=30s 2>/dev/null || log_warning "No Schedules found"
    
    # Delete ExternalSecret
    log_info "Deleting Velero credentials ExternalSecret..."
    kubectl delete externalsecret velero-credentials -n velero 2>/dev/null || log_warning "ExternalSecret not found"
    
    # Delete secret
    kubectl delete secret velero-credentials -n velero 2>/dev/null || true
    
    # Uninstall Helm release
    log_info "Uninstalling Velero Helm release..."
    helm uninstall velero -n velero 2>/dev/null || log_warning "Helm release not found"
    
    # Delete namespace
    log_info "Deleting namespace..."
    kubectl delete namespace velero --timeout=60s 2>/dev/null || log_warning "Namespace not found"
    
    # Optional: Clean up CRDs (commented by default)
    # log_warning "Cleaning up CRDs..."
    # kubectl delete crd backups.velero.io 2>/dev/null || true
    # kubectl delete crd restores.velero.io 2>/dev/null || true
    # kubectl delete crd schedules.velero.io 2>/dev/null || true
    # kubectl delete crd backupstoragelocations.velero.io 2>/dev/null || true
    # kubectl delete crd volumesnapshotlocations.velero.io 2>/dev/null || true
    # kubectl delete crd backuprepositories.velero.io 2>/dev/null || true
    # kubectl delete crd podvolumerestores.velero.io 2>/dev/null || true
    # kubectl delete crd podvolumebackups.velero.io 2>/dev/null || true
    
    log_success "Velero uninstalled"
    log_info "Note: Backups in cloud storage remain intact"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi