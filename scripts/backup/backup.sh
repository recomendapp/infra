#!/usr/bin/env bash
set -e

NAME="manual-backup-$(date +%Y%m%d-%H%M%S)"

echo "Creating backup: $NAME"
velero backup create "$NAME"

echo ""
echo "Tracking progress..."
echo "Press CTRL+C to stop watching (backup continues in background)"
echo ""

watch -n 2 "velero backup get | grep $NAME"
