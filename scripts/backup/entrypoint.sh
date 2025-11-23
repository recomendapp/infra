#!/usr/bin/env bash
set -e

# --- Guards ---------------------------------------------------------------

if ! command -v velero >/dev/null 2>&1; then
    echo "❌ velero command not found. Install Velero first."
    exit 1
fi

if ! kubectl get ns velero >/dev/null 2>&1; then
    echo "❌ Velero namespace not found."
    exit 1
fi

if ! kubectl -n velero get deploy/velero >/dev/null 2>&1; then
    echo "❌ Velero deployment missing."
    exit 1
fi

if ! kubectl -n velero rollout status deploy/velero --timeout=30s >/dev/null 2>&1; then
    echo "❌ Velero not ready."
    exit 1
fi

# --- Menu ----------------------------------------------------------------

choice=$(
  printf "Create Backup\nRestore\nList Backups\nStatus\n" \
  | fzf --height=40% --border --prompt="Velero: " --layout=reverse
)

[ -z "$choice" ] && exit 1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$choice" in
  "Create Backup")
	exec "$SCRIPT_DIR/backup.sh"
	;;
  "List Backups")
    exec "$SCRIPT_DIR/list.sh"
    ;;
  "Restore")
    exec "$SCRIPT_DIR/restore/entrypoint.sh"
    ;;
  "Status")
    exec "$SCRIPT_DIR/status.sh"
    ;;
esac
