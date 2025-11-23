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
	@echo "  make install				Install cluster dependencies via GitOps"
	@echo ""
	@echo "🌐 Access & UI:"
	@echo "  make argocd-ui				Access ArgoCD UI (port-forward)"
	@echo "  make argocd-password		Show ArgoCD admin password"
	@echo "  make argocd-sync			Manually trigger a sync of the root application"
	@echo ""
	@echo "🧹 Uninstall:"
	@echo "  make uninstall				Uninstall all GitOps managed applications"
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
# Install
# ============================================================================

.PHONY: install
install:
	@./scripts/install.sh

# ============================================================================
# Uninstall
# ============================================================================

.PHONY: uninstall
uninstall:
	@./scripts/uninstall.sh

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

.PHONY: argocd-sync
argocd-sync:
	@echo "🔄 Syncing ArgoCD root application..."
	@kubectl -n argocd patch app root --type merge -p '{"spec":{"syncPolicy":{"automated":null}}}' >/dev/null
	@argocd app sync root
	@kubectl -n argocd patch app root --type merge -p '{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true}}}}' >/dev/null
	@echo "✅ Sync complete."

# ============================================================================
# Backup
# ============================================================================
.PHONY: backup
backup:
	@./scripts/backup/entrypoint.sh

.DEFAULT_GOAL := help