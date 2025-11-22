SHELL := /usr/bin/env bash

# ============================================================================
# K3s Cluster Management - Pure GitOps
# ============================================================================

CLUSTER_CONFIG     = hetzner/cluster_config.yaml
CLUSTER_CONFIG_GEN = hetzner/cluster_config.generated.yaml

# ============================================================================
# ENV
# ============================================================================
ifneq (,$(wildcard .env.local))
include .env.local
export
endif

KUBECONFIG		:=	$(CURDIR)/kubeconfig
export KUBECONFIG

# ============================================================================
# Main Commands
# ============================================================================

.PHONY: help
help:
	@echo "════════════════════════════════════════════════════════════════════"
	@echo "  🚀 K3s Cluster - Pure GitOps"
	@echo "════════════════════════════════════════════════════════════════════"
	@echo ""
	@echo "🏗️  Cluster Management:"
	@echo "  make cluster-create		Create cluster + bootstrap"
	@echo "  make cluster-delete		Delete the cluster"
	@echo ""
	@echo "⚙️  Bootstrap:"
	@echo "  make bootstrap				Run cluster bootstrap"
	@echo "  make bootstrap-minimal		Run minimal bootstrap"
	@echo "  make bootstrap-component	COMPONENT=<name>  Bootstrap a specific component"
	@echo ""
	@echo "🔍 Validation:"
	@echo "  make validate				Validate all components"
	@echo "  make validate-component	COMPONENT=<name>  Validate a specific component"
	@echo ""
	@echo "🧹 Uninstall:"
	@echo "  make uninstall				Uninstall all components"
	@echo "  make uninstall-component	COMPONENT=<name>  Uninstall a specific component"
	@echo ""
	@echo "🌐 Access & UI:"
	@echo "  make argocd-ui				Access ArgoCD UI (port-forward)"
	@echo "  make argocd-password		Show ArgoCD admin password"
	@echo ""
	@echo "💾 Backup (Velero):"
	@echo "  make backup-create			Create a manual backup"
	@echo "  make backup-list			List all backups"
	@echo "  make backup-status			Check Velero status"
	@echo "  make backup-restore		Restore from a backup"
	@echo ""
	@echo "════════════════════════════════════════════════════════════════════"

# ============================================================================
# Cluster Operations
# ============================================================================

.PHONY: generate-cluster-config
generate-cluster-config:
	@echo "🔧 Generating cluster config..."
	@if [ -z "$(HCLOUD_TOKEN)" ]; then \
		echo "❌ Error: HCLOUD_TOKEN environment variable is not set."; \
		exit 1; \
	fi
	@envsubst < $(CLUSTER_CONFIG) > $(CLUSTER_CONFIG_GEN)
	@echo "✅ Generated $(CLUSTER_CONFIG_GEN)"

.PHONY: clean-cluster-config
clean-cluster-config:
	@echo "🧹 Cleaning generated cluster config..."
	@rm -f $(CLUSTER_CONFIG_GEN)


.PHONY: cluster-create
cluster-create: generate-cluster-config
	@echo "════════════════════════════════════════════════════════════════════"
	@echo "  🏗️  Creating K3s Cluster"
	@echo "════════════════════════════════════════════════════════════════════"
	@echo ""
	@hetzner-k3s create --config $(CLUSTER_CONFIG_GEN)
	@echo ""
	@echo "🎉 Cluster created successfully!"

.PHONY: cluster-delete
cluster-delete: generate-cluster-config
	@echo "════════════════════════════════════════════════════════════════════"
	@echo "  🗑️  Deleting K3s Cluster"
	@echo "════════════════════════════════════════════════════════════════════"
	@echo ""
	@echo "⚠️  This will delete the entire cluster!"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		echo ""; \
		echo "1️⃣  Deleting cluster..."; \
		hetzner-k3s delete --config $(CLUSTER_CONFIG_GEN); \
		echo "✅ Cluster deleted"; \
	else \
		echo "❌ Cancelled"; \
	fi
	@$(MAKE) clean-cluster-config


# ============================================================================
# Bootstrap
# ============================================================================

.PHONY: bootstrap
bootstrap:
	@./scripts/profiles/full.sh

.PHONY: bootstrap-minimal
bootstrap-minimal:
	@./scripts/profiles/minimal.sh

.PHONY: bootstrap-component
bootstrap-component:
	@if [ -z "$(COMPONENT)" ]; then \
		echo "❌ Usage: make bootstrap-component COMPONENT=argocd"; \
		exit 1; \
	fi; \
	./scripts/components/$(COMPONENT)/install.sh

# ============================================================================
# Validation
# ============================================================================

.PHONY: validate
validate:
	@echo "🔍 Validating all components..."; \
	errors=0; \
	for component in cert-manager external-secrets argocd velero; do \
		if [ -f "./scripts/components/$$component/validate.sh" ]; then \
			echo ""; \
			./scripts/components/$$component/validate.sh || ((errors++)); \
		fi; \
	done; \
	echo ""; \
	if [ $$errors -eq 0 ]; then \
		echo "✅ All validations passed"; \
	else \
		echo "❌ $$errors validation(s) failed"; \
		exit 1; \
	fi

.PHONY: validate-component
validate-component:
	@if [ -z "$(COMPONENT)" ]; then \
		echo "❌ Usage: make validate-component COMPONENT=argocd"; \
		exit 1; \
	fi; \
	./scripts/components/$(COMPONENT)/validate.sh

# ============================================================================
# Uninstall
# ============================================================================

.PHONY: uninstall
uninstall:
	@./scripts/uninstall.sh

.PHONY: uninstall-component
uninstall-component:
	@if [ -z "$(COMPONENT)" ]; then \
		echo "❌ Usage: make uninstall-component COMPONENT=argocd"; \
		exit 1; \
	fi; \
	./scripts/components/$(COMPONENT)/uninstall.sh

.PHONY: uninstall-all
uninstall-all:
	@echo "⚠️  This will DELETE everything from the cluster!"; \
	read -p "Type 'DELETE' to confirm: " confirm; \
	if [ "$$confirm" = "DELETE" ]; then \
		for component in gitops argocd velero external-dns infisical external-secrets cert-manager; do \
			./scripts/components/$$component/uninstall.sh 2>/dev/null || true; \
		done; \
		echo "✅ Full uninstall complete"; \
	else \
		echo "❌ Cancelled"; \
	fi

# ============================================================================
# Access & UI
# ============================================================================

.PHONY: argocd-password
argocd-password:
	@echo "🔑 ArgoCD Admin Password:"
	@kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d && echo || echo "❌ Secret not found"

.PHONY: argocd-ui
argocd-ui:
	@echo "════════════════════════════════════════════════════════════════════"
	@echo "  🌐 ArgoCD UI Access"
	@echo "════════════════════════════════════════════════════════════════════"
	@echo ""
	@echo "URL:      https://localhost:8080"
	@echo "Username: admin"
	@echo "Password: $$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d)"
	@echo ""
	@echo "⚠️  Accept the self-signed certificate in your browser"
	@echo "Press Ctrl+C to stop port-forward"
	@echo ""
	@kubectl port-forward svc/argocd-server -n argocd 8080:443


# ============================================================================
# Velero Backup Commands
# ============================================================================

.PHONY: backup-create
backup-create:
	@echo "💾 Creating manual backup..."
	@velero backup create manual-backup-$$(date +%Y%m%d-%H%M%S)
	@echo "✅ Backup created"

.PHONY: backup-list
backup-list:
	@echo "📋 Listing backups..."
	@velero backup get

.PHONY: backup-status
backup-status:
	@echo "🔍 Velero status..."
	@kubectl -n velero get pods
	@echo ""
	@echo "📍 Backup locations:"
	@velero backup-location get

.PHONY: backup-restore
backup-restore:
	@echo "📋 Available Velero backups:"; \
	velero backup get; \
	echo ""; \
	read -p "👉 Enter backup name to restore: " BACKUP; \
	if [ -z "$$BACKUP" ]; then \
		echo "❌ No backup selected"; exit 1; \
	fi; \
	echo ""; \
	read -p "⚠️ This will restore '$$BACKUP'. Continue? [y/N] " CONFIRM; \
	if ! echo "$$CONFIRM" | grep -iq "^y"; then \
		echo "❌ Cancelled"; exit 1; \
	fi; \
	echo ""; \
	echo "⏳ Checking Velero availability..."; \
	if ! kubectl -n velero get deploy/velero >/dev/null 2>&1; then \
		echo "❌ Velero deployment not found or cluster unreachable"; exit 1; \
	fi; \
	echo "⏳ Waiting for Velero pod to be ready..."; \
	if ! kubectl -n velero rollout status deploy/velero --timeout=60s >/dev/null 2>&1; then \
		echo "❌ Velero is not ready — aborting restore"; exit 1; \
	fi; \
	echo "🚀 Launching restore: $$BACKUP"; \
	if ! velero restore create --from-backup "$$BACKUP"; then \
		echo "❌ Restore failed to launch"; exit 1; \
	fi; \
	echo "✅ Restore launched."

# ============================================================================
# Restore
# ============================================================================

.PHONY: disaster-recovery
disaster-recovery:
	@./scripts/restore.sh

.PHONY: restore-diagnose
restore-diagnose:
	@if [ -z "$(RESTORE_NAME)" ]; then \
		./scripts/restore/diagnose.sh; \
		exit 0; \
	fi; \
	./scripts/restore/diagnose.sh "$(RESTORE_NAME)"

.DEFAULT_GOAL := help