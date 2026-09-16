#!/usr/bin/env bash
set -Eeuo pipefail

detect_home() {
  if [[ -n "${CLASH_VERGE_HOME:-}" ]]; then printf '%s\n' "$CLASH_VERGE_HOME"; return; fi
  local candidates=(
    "$HOME/.local/share/io.github.clash-verge-rev.clash-verge-rev"
    "$HOME/.config/io.github.clash-verge-rev.clash-verge-rev"
    "$HOME/.config/clash-verge-rev"
  )
  local c
  for c in "${candidates[@]}"; do
    if [[ -d "$c/ai-whitelist-backups" ]]; then printf '%s\n' "$c"; return; fi
  done
  exit 1
}

APP_HOME="$(detect_home)"
BACKUP_ROOT="$APP_HOME/ai-whitelist-backups"
LATEST="$(find "$BACKUP_ROOT" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort -r | head -n1 || true)"
[[ -n "$LATEST" ]] || { echo "No backup found under $BACKUP_ROOT" >&2; exit 1; }

BACKUP_DIR="$BACKUP_ROOT/$LATEST"
MANIFEST="$BACKUP_DIR/manifest.env"
[[ -f "$MANIFEST" ]] || { echo "Backup manifest missing: $MANIFEST" >&2; exit 1; }

# shellcheck disable=SC1090
source "$MANIFEST"

GLOBAL_SCRIPT="$APP_HOME/profiles/Script.js"
VERGE_YAML="$APP_HOME/verge.yaml"
CONFIG_YAML="$APP_HOME/config.yaml"

WAS_RUNNING=0
if pgrep -x clash-verge >/dev/null 2>&1; then
  WAS_RUNNING=1; pkill -TERM -x clash-verge || true; sleep 1
elif pgrep -x clash-verge-rev >/dev/null 2>&1; then
  WAS_RUNNING=1; pkill -TERM -x clash-verge-rev || true; sleep 1
fi

restore_one() {
  local existed="$1" backup="$2" dest="$3"
  if [[ "$existed" == "1" ]]; then cp -a "$backup" "$dest"; else rm -f "$dest"; fi
}

restore_one "${SCRIPT_EXISTED:-0}" "$BACKUP_DIR/Script.js" "$GLOBAL_SCRIPT"
restore_one "${VERGE_EXISTED:-0}" "$BACKUP_DIR/verge.yaml" "$VERGE_YAML"
restore_one "${CONFIG_EXISTED:-0}" "$BACKUP_DIR/config.yaml" "$CONFIG_YAML"

if [[ $WAS_RUNNING -eq 1 ]]; then
  if command -v clash-verge >/dev/null 2>&1; then nohup clash-verge >/tmp/clash-verge-ai-whitelist.log 2>&1 &
  elif command -v clash-verge-rev >/dev/null 2>&1; then nohup clash-verge-rev >/tmp/clash-verge-ai-whitelist.log 2>&1 &
  fi
fi

echo "Restored backup: $BACKUP_DIR"
