#!/usr/bin/env bash
set -e

json=$(velero backup get -o json 2>/dev/null || true)

if echo "$json" | jq -e '.kind == "BackupList"' >/dev/null 2>&1; then
    backups=$(echo "$json" | jq -r '.items[].metadata.name')
fi

if echo "$json" | jq -e '.kind == "Backup"' >/dev/null 2>&1; then
    backups=$(echo "$json" | jq -r '.metadata.name')
fi

[ -z "$backups" ] && { echo "❌ No backups found."; exit 1; }

choice=$(
  printf "%s\n" $backups \
    | fzf --height=40% --border --prompt="Select backup: " --layout=reverse
)

[ -z "$choice" ] && exit 1

echo "$choice"
