#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROFILES_DIR="$SCRIPT_DIR/profiles"

choice=$(
  ls "$PROFILES_DIR"/*.sh \
    | sed 's|.*/||' \
    | fzf --prompt="Select profile: " \
          --height=40% \
          --border \
          --layout=reverse
)

[ -z "$choice" ] && exit 1

exec "$PROFILES_DIR/$choice" "$@"
