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
	@echo "  make cluster-create       Create cluster + bootstrap"
	@echo "  make cluster-delete       Delete the cluster"
	@echo ""
	@echo "⚙️  Bootstrap:"
	@echo "  make bootstrap            Run cluster bootstrap"
	@echo ""
	@echo "🌐 Access & UI:"
	@echo "  make argocd-ui            Access ArgoCD UI (port-forward)"
	@echo "  make argocd-password      Show ArgoCD admin password"
	@echo ""
	@echo "💾 Backup (Velero):"
	@echo "  make backup-create        Create a manual backup"
	@echo "  make backup-list          List all backups"
	@echo "  make backup-status        Check Velero status"
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
	@echo "🚀 Running cluster bootstrap..."
	cd bootstrap && ./install.sh
	@echo "✅ Bootstrap completed."

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

.DEFAULT_GOAL := help