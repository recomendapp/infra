#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

backup=$("$SCRIPT_DIR/select-backup.sh")

echo "Selected backup: $backup"

echo "Restore: $backup"
read -p "Continue ? [y/N] " -n 1 -r
echo
[[ $REPLY =~ ^[Yy]$ ]] || exit 1

echo "Launching restore..."
velero restore create --from-backup "$backup"

echo ""
echo "Tracking progress..."
echo "Press CTRL+C to stop watching (restore continues in background)"
echo ""

watch -n 2 "velero restore get | grep $backup"
