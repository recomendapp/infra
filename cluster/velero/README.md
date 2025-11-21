# Velero - Backup et Restore du Cluster

Velero est configuré pour sauvegarder automatiquement votre cluster K3s sur Cloudflare R2.

## 📋 Configuration

### Secrets Infisical Requis
- `VELERO_R2_ACCESS_KEY_ID` - Access Key ID pour R2
- `VELERO_R2_SECRET_ACCESS_KEY` - Secret Access Key pour R2
- `VELERO_R2_BUCKET` - Nom du bucket R2
- `VELERO_R2_ACCOUNT_ID` - Account ID Cloudflare

### Backups Automatiques
- **Daily** : Tous les jours à 2h du matin (rétention 30 jours)
- **Weekly** : Tous les dimanches à 3h (rétention 90 jours)

## 🛠️ Installation CLI Velero

```bash
# macOS
brew install velero

# Linux
wget https://github.com/vmware-tanzu/velero/releases/download/v1.14.0/velero-v1.14.0-linux-amd64.tar.gz
tar -xvf velero-v1.14.0-linux-amd64.tar.gz
sudo mv velero-v1.14.0-linux-amd64/velero /usr/local/bin/
```

## 📊 Commandes Utiles

### Vérifier le statut
```bash
# Voir les backups
velero backup get

# Voir les schedules
velero schedule get

# Détails d'un backup
velero backup describe <backup-name>

# Logs d'un backup
velero backup logs <backup-name>
```

### Créer un backup manuel
```bash
# Backup de tout le cluster
velero backup create manual-backup-$(date +%Y%m%d-%H%M%S)

# Backup d'un namespace spécifique
velero backup create manual-umami --include-namespaces default

# Backup avec exclusions
velero backup create manual-backup --exclude-namespaces kube-system,argocd
```

### Restaurer un backup
```bash
# Lister les backups disponibles
velero backup get

# Restaurer un backup complet
velero restore create --from-backup <backup-name>

# Restaurer un namespace spécifique
velero restore create --from-backup <backup-name> \
  --include-namespaces default

# Voir le statut d'une restauration
velero restore get
velero restore describe <restore-name>
```

### Gestion des schedules
```bash
# Voir les schedules
velero schedule get

# Déclencher un backup schedulé manuellement
velero backup create --from-schedule daily

# Suspendre un schedule
velero schedule pause daily

# Reprendre un schedule
velero schedule unpause daily
```

## 🔧 Dépannage

### Vérifier la configuration
```bash
# Vérifier le BackupStorageLocation
kubectl get backupstoragelocation -n velero

# Détails du BSL
kubectl describe backupstoragelocation default -n velero

# Vérifier les secrets
kubectl get secret cloud-credentials -n velero
kubectl get secret velero-r2-config -n velero
```

### Logs Velero
```bash
# Logs du pod Velero
kubectl logs -n velero deployment/velero

# Logs du node-agent
kubectl logs -n velero daemonset/node-agent
```

### Tester la connexion R2
```bash
# Créer un backup de test
velero backup create test-backup --include-namespaces default

# Vérifier qu'il apparaît
velero backup get test-backup

# Supprimer le backup de test
velero backup delete test-backup --confirm
```

## 🚨 Scénarios de Restauration

### Restauration après désastre complet
1. Réinstaller le cluster K3s
2. Réinstaller ArgoCD et les outils de base
3. Réinstaller Velero avec les mêmes credentials R2
4. Restaurer le dernier backup :
```bash
velero restore create disaster-recovery \
  --from-backup daily-<timestamp> \
  --wait
```

### Restauration d'une application spécifique
```bash
# Supprimer l'application existante
kubectl delete namespace <app-namespace>

# Restaurer depuis le backup
velero restore create restore-app \
  --from-backup <backup-name> \
  --include-namespaces <app-namespace>
```

### Restauration de PersistentVolumes
Les PV sont automatiquement sauvegardés avec `defaultVolumesToFsBackup: true`.
```bash
# Vérifier les volumes dans un backup
velero backup describe <backup-name> --details

# Restaurer avec les volumes
velero restore create --from-backup <backup-name>
```

## 📈 Monitoring

### Métriques Prometheus (si activé)
```bash
# Port-forward vers Velero metrics
kubectl port-forward -n velero deployment/velero 8085:8085

# Accéder aux métriques
curl http://localhost:8085/metrics
```

### Alertes recommandées
- Backup failed pendant 2 exécutions consécutives
- BackupStorageLocation unavailable
- Aucun backup réussi depuis 48h

## 🔐 Sécurité

Les credentials R2 sont :
- Stockés dans Infisical
- Synchronisés via External Secrets Operator
- Jamais committés dans Git
- Utilisés uniquement par le pod Velero

## 📝 Notes

- Les backups excluent automatiquement `kube-system` pour éviter les conflits
- `defaultVolumesToFsBackup: true` active le backup des PV via file-system
- Les schedules utilisent la timezone UTC
- La rétention est gérée automatiquement par Velero