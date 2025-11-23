#!/usr/bin/env bash
set -e

echo "Velero pods:"
kubectl -n velero get pods

echo ""
echo "Backup locations:"
velero backup-location get
