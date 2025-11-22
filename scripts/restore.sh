#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/wait.sh"

full_restore() {
    log_section "🔴 FULL DISASTER RECOVERY"
    
    log_warning "Prerequisites:"
    echo "  ✓ Fresh cluster created (make cluster-create)"
    echo "  ✗ Bootstrap NOT run yet"
    echo ""
    
    read -p "Have you created a FRESH cluster? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_error "Please create a fresh cluster first: make cluster-create"
        exit 1
    fi
    
    log_info "Step 1/3: Installing minimal components (core + Velero)..."
    "$SCRIPT_DIR/profiles/minimal.sh" || exit 1

	log_info "Waiting for Velero to sync backups..."
	sleep 10

	# Wait until Velero lists at least 1 backup or timeout
	for i in {1..30}; do
		if velero backup get | grep -v "No backups found" | grep -qE "Completed|PartiallyFailed|New"; then
			break
		fi
		sleep 2
	done

    
    log_info "Step 2/3: Listing available backups..."
    echo ""
    velero backup get
    echo ""
    
    read -p "👉 Enter backup name to restore: " backup
    if [ -z "$backup" ]; then
        log_error "No backup selected"
        exit 1
    fi
    
    log_info "Step 3/3: Restoring from backup '$backup'..."
    echo ""
    
    restore_name="full-restore-$(date +%Y%m%d-%H%M%S)"
    
    if velero restore create "$restore_name" --from-backup "$backup" --wait; then
        log_success "Restore completed!"
        echo ""
        log_info "Restore details:"
        velero restore describe "$restore_name"
        echo ""
        log_info "Next steps:"
        echo "  • Verify pods: kubectl get pods -A"
        echo "  • Check ArgoCD: make argocd-ui"
        echo "  • Review restore logs: velero restore logs $restore_name"
    else
        log_error "Restore failed!"
        echo ""
        log_info "Check restore status:"
        echo "  velero restore describe $restore_name"
        echo "  velero restore logs $restore_name"
        exit 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    full_restore "$@"
fi
