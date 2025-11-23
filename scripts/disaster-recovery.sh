#!/bin/bash
# scripts/disaster-recovery.sh
# Basé sur: https://github.com/vmware-tanzu/velero/discussions/6867

set -e

BACKUP_NAME="${1}"

if [ -z "$BACKUP_NAME" ]; then
    echo "Available backups:"
    kubectl get backups -n velero -o custom-columns=NAME:.metadata.name,CREATED:.status.startTimestamp,STATUS:.status.phase
    echo ""
    read -p "Enter backup name (or 'latest'): " BACKUP_NAME
fi

if [ "$BACKUP_NAME" == "latest" ]; then
    BACKUP_NAME=$(kubectl get backups -n velero -o jsonpath='{.items[-1].metadata.name}')
    echo "Using latest backup: $BACKUP_NAME"
fi

echo ""
echo "🚨 Disaster Recovery from backup: $BACKUP_NAME"
echo ""
echo "⚠️  This will DELETE existing data and restore from backup!"
read -p "Continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "Step 1/6: Suspending ArgoCD applications..."
# Désactive le self-heal pour empêcher ArgoCD de recréer les ressources
kubectl patch application umami -n argocd --type merge -p '{"spec":{"syncPolicy":null}}' 2>/dev/null || echo "⚠️ umami app not found"
kubectl patch application typesense -n argocd --type merge -p '{"spec":{"syncPolicy":null}}' 2>/dev/null || echo "⚠️ typesense app not found"

echo "✅ ArgoCD sync disabled"
sleep 3

echo ""
echo "Step 2/6: Deleting StatefulSets..."
# Supprime complètement les StatefulSets (pas juste scale à 0)
kubectl delete statefulset umami-postgres -n default --ignore-not-found=true
kubectl delete statefulset typesense -n default --ignore-not-found=true

echo "⏳ Waiting for pods to terminate (max 60s)..."
sleep 10

# Force delete si les pods persistent
kubectl delete pod umami-postgres-0 -n default --force --grace-period=0 2>/dev/null || true
kubectl delete pod typesense-0 -n default --force --grace-period=0 2>/dev/null || true

# Attends que les pods soient vraiment partis
for i in {1..30}; do
    PODS=$(kubectl get pods -n default -l 'app in (umami-postgres,typesense)' --no-headers 2>/dev/null | wc -l)
    if [ "$PODS" -eq 0 ]; then
        echo "✅ All pods terminated"
        break
    fi
    echo "Waiting for pods to terminate... ($i/30) - $PODS pods remaining"
    sleep 2
done

echo ""
echo "Step 3/6: Removing PVC finalizers and deleting..."

# Liste les PVCs avant suppression
echo "Current PVCs:"
kubectl get pvc -n default 2>/dev/null || echo "No PVCs"

# Retire les finalizers pour forcer la suppression
for pvc in data-umami-postgres-0 data-typesense-0; do
    if kubectl get pvc $pvc -n default &>/dev/null; then
        echo "Removing finalizers from $pvc..."
        kubectl patch pvc $pvc -n default -p '{"metadata":{"finalizers":[]}}' --type=merge 2>/dev/null || true
        kubectl delete pvc $pvc -n default --ignore-not-found=true --timeout=10s 2>/dev/null || true
    fi
done

# Vérifie qu'ils sont supprimés
sleep 5
echo ""
echo "PVCs after deletion:"
kubectl get pvc -n default 2>/dev/null || echo "✅ No PVCs"

# Si des PVCs persistent en Terminating, force leur suppression
for pvc in data-umami-postgres-0 data-typesense-0; do
    if kubectl get pvc $pvc -n default &>/dev/null; then
        STATUS=$(kubectl get pvc $pvc -n default -o jsonpath='{.status.phase}')
        if [ "$STATUS" == "Terminating" ]; then
            echo "⚠️ Force deleting stuck PVC: $pvc"
            kubectl patch pvc $pvc -n default -p '{"metadata":{"finalizers":[]}}' --type=merge
        fi
    fi
done

sleep 3

echo ""
echo "Step 4/6: Starting Velero restore..."
RESTORE_NAME="restore-$(date +%Y%m%d-%H%M%S)"

velero restore create $RESTORE_NAME \
  --from-backup $BACKUP_NAME \
  --include-namespaces default \
  --restore-volumes=true \
  --wait

echo ""
echo "Step 5/6: Checking restore status..."
velero restore describe $RESTORE_NAME

echo ""
echo "📊 Restored resources:"
kubectl get pvc -n default
kubectl get statefulsets -n default
kubectl get pods -n default

echo ""
echo "Step 6/6: Re-enabling ArgoCD sync..."
kubectl patch application umami -n argocd --type merge -p '{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true}}}}'
kubectl patch application typesense -n argocd --type merge -p '{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true}}}}'

echo "⏳ Waiting for ArgoCD to sync and pods to be ready (max 180s)..."
sleep 10

# Attends que les pods soient prêts
kubectl wait --for=condition=ready pod/umami-postgres-0 -n default --timeout=180s 2>/dev/null || echo "⚠️ umami-postgres-0 not ready yet"
kubectl wait --for=condition=ready pod/typesense-0 -n default --timeout=180s 2>/dev/null || echo "⚠️ typesense-0 not ready yet"

echo ""
echo "✅ Disaster Recovery Complete!"
echo ""
echo "📊 Final Status:"
kubectl get pods -n default
kubectl get pvc -n default

echo ""
echo "🔍 Verification commands:"
echo "  # Check restored data:"
echo "  kubectl exec umami-postgres-0 -n default -- psql -U postgres -d umami -c 'SELECT COUNT(*) FROM website;'"
echo ""
echo "  # Check logs:"
echo "  kubectl logs umami-postgres-0 -n default"
echo "  kubectl logs typesense-0 -n default"
echo ""
echo "  # Check Velero restore details:"
echo "  velero restore describe $RESTORE_NAME --volume-details"