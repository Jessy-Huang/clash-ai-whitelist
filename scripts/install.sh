#!/usr/bin/env bash
set -Eeuo pipefail

PREFERRED_GROUP="${CLASH_PROXY_GROUP:-🔰 选择节点}"
ENABLE_TUN=1
ENABLE_SYSTEM_PROXY=1
RESTART_APP=1
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage:
  ./scripts/install.sh [options]

Options:
  --proxy-group NAME       Preferred Clash proxy group (default: "🔰 选择节点")
  --no-tun                 Do not change TUN switch
  --no-system-proxy        Do not change system proxy switch
  --no-restart             Do not restart Clash Verge Rev
  --dry-run                Show detected paths and planned changes only
  -h, --help               Show help

Environment:
  CLASH_VERGE_HOME         Override Clash Verge Rev application data directory
  CLASH_PROXY_GROUP        Same as --proxy-group
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --proxy-group) PREFERRED_GROUP="${2:?missing proxy group name}"; shift 2 ;;
    --no-tun) ENABLE_TUN=0; shift ;;
    --no-system-proxy) ENABLE_SYSTEM_PROXY=0; shift ;;
    --no-restart) RESTART_APP=0; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
ASSET_SCRIPT="$PROJECT_DIR/assets/Script.js"

detect_home() {
  if [[ -n "${CLASH_VERGE_HOME:-}" ]]; then
    [[ -d "$CLASH_VERGE_HOME" ]] || { echo "CLASH_VERGE_HOME does not exist: $CLASH_VERGE_HOME" >&2; exit 1; }
    printf '%s\n' "$CLASH_VERGE_HOME"; return
  fi
  local candidates=(
    "$HOME/.local/share/io.github.clash-verge-rev.clash-verge-rev"
    "$HOME/.config/io.github.clash-verge-rev.clash-verge-rev"
    "$HOME/.config/clash-verge-rev"
  )
  local c
  for c in "${candidates[@]}"; do
    if [[ -f "$c/verge.yaml" || -f "$c/profiles.yaml" ]]; then printf '%s\n' "$c"; return; fi
  done
  local found=""
  found="$(find "$HOME/.config" "$HOME/.local/share" -maxdepth 3 -type f -name verge.yaml 2>/dev/null | grep -E 'clash-verge|clash_verge|io\.github\.clash-verge-rev' | head -n1 || true)"
  if [[ -n "$found" ]]; then dirname "$found"; return; fi
  echo "Could not find Clash Verge Rev data directory." >&2
  echo "Set it explicitly, for example:" >&2
  echo "  CLASH_VERGE_HOME=~/.local/share/io.github.clash-verge-rev.clash-verge-rev $0" >&2
  exit 1
}

APP_HOME="$(detect_home)"
PROFILES_DIR="$APP_HOME/profiles"
VERGE_YAML="$APP_HOME/verge.yaml"
CONFIG_YAML="$APP_HOME/config.yaml"
PROFILES_YAML="$APP_HOME/profiles.yaml"
GLOBAL_SCRIPT="$PROFILES_DIR/Script.js"

echo "Clash Verge Rev home : $APP_HOME"
echo "Preferred proxy group: $PREFERRED_GROUP"
echo "TUN                  : $([[ $ENABLE_TUN -eq 1 ]] && echo enable || echo unchanged)"
echo "System proxy         : $([[ $ENABLE_SYSTEM_PROXY -eq 1 ]] && echo enable || echo unchanged)"
echo

[[ -f "$ASSET_SCRIPT" ]] || { echo "Missing asset: $ASSET_SCRIPT" >&2; exit 1; }
[[ -f "$PROFILES_YAML" ]] || { echo "profiles.yaml not found: $PROFILES_YAML" >&2; exit 1; }
mkdir -p "$PROFILES_DIR"

if ! grep -Eq '^[[:space:]]*-[[:space:]]*uid:[[:space:]]*["'\''"]?Script["'\''"]?[[:space:]]*$' "$PROFILES_YAML"; then
  echo "Global Script profile entry was not found in profiles.yaml." >&2
  echo "For safety, this installer will not rewrite profiles.yaml automatically." >&2
  echo "Open Clash Verge Rev once and create/open 'Global Extend Script', then rerun." >&2
  exit 1
fi

if [[ $DRY_RUN -eq 1 ]]; then
  echo "[dry-run] Would back up:"
  [[ -f "$GLOBAL_SCRIPT" ]] && echo "  $GLOBAL_SCRIPT"
  [[ -f "$VERGE_YAML" ]] && echo "  $VERGE_YAML"
  [[ -f "$CONFIG_YAML" ]] && echo "  $CONFIG_YAML"
  echo "[dry-run] Would install managed global Script.js."
  echo "[dry-run] Would set mode=rule and requested GUI switches."
  exit 0
fi

WAS_RUNNING=0
if pgrep -x clash-verge >/dev/null 2>&1; then
  WAS_RUNNING=1; echo "Stopping Clash Verge Rev UI to avoid config overwrite..."; pkill -TERM -x clash-verge || true
  for _ in $(seq 1 30); do pgrep -x clash-verge >/dev/null 2>&1 || break; sleep 0.2; done
elif pgrep -x clash-verge-rev >/dev/null 2>&1; then
  WAS_RUNNING=1; echo "Stopping Clash Verge Rev UI to avoid config overwrite..."; pkill -TERM -x clash-verge-rev || true
  for _ in $(seq 1 30); do pgrep -x clash-verge-rev >/dev/null 2>&1 || break; sleep 0.2; done
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_ROOT="$APP_HOME/ai-whitelist-backups"
BACKUP_DIR="$BACKUP_ROOT/$STAMP"
mkdir -p "$BACKUP_DIR"

backup_one() {
  local src="$1" key="$2"
  if [[ -f "$src" ]]; then cp -a "$src" "$BACKUP_DIR/$(basename "$src")"; printf '%s=1\n' "$key" >> "$BACKUP_DIR/manifest.env";
  else printf '%s=0\n' "$key" >> "$BACKUP_DIR/manifest.env"; fi
}

backup_one "$GLOBAL_SCRIPT" SCRIPT_EXISTED
backup_one "$VERGE_YAML" VERGE_EXISTED
backup_one "$CONFIG_YAML" CONFIG_EXISTED

echo "Backup created: $BACKUP_DIR"

python3 - "$ASSET_SCRIPT" "$GLOBAL_SCRIPT" "$PREFERRED_GROUP" <<'PY'
from pathlib import Path
import json, sys
src = Path(sys.argv[1]).read_text(encoding="utf-8")
dst = Path(sys.argv[2])
group = sys.argv[3]
escaped = json.dumps(group, ensure_ascii=False)
src = src.replace('"__PREFERRED_GROUP__"', escaped)
dst.write_text(src, encoding="utf-8")
PY

patch_top_level_scalar() {
  local file="$1" key="$2" value="$3"
  [[ -f "$file" ]] || return 0
  python3 - "$file" "$key" "$value" <<'PY'
from pathlib import Path
import re, sys
path = Path(sys.argv[1]); key = sys.argv[2]; value = sys.argv[3]
text = path.read_text(encoding="utf-8")
pattern = re.compile(rf'(?m)^(?![ \t]){re.escape(key)}:[^\n]*(?:\n|$)')
line = f"{key}: {value}\n"
if pattern.search(text): text = pattern.sub(line, text, count=1)
else:
    if text and not text.endswith("\n"): text += "\n"
    text += line
path.write_text(text, encoding="utf-8")
PY
}

patch_top_level_scalar "$CONFIG_YAML" "mode" "rule"
if [[ $ENABLE_TUN -eq 1 ]]; then patch_top_level_scalar "$VERGE_YAML" "enable_tun_mode" "true"; fi
if [[ $ENABLE_SYSTEM_PROXY -eq 1 ]]; then patch_top_level_scalar "$VERGE_YAML" "enable_system_proxy" "true"; fi

if command -v systemctl >/dev/null 2>&1; then
  if systemctl is-active --quiet clash-verge-service.service 2>/dev/null; then systemctl restart clash-verge-service.service 2>/dev/null || true; fi
fi

if [[ $RESTART_APP -eq 1 && $WAS_RUNNING -eq 1 ]]; then
  sleep 1
  if command -v clash-verge >/dev/null 2>&1; then nohup clash-verge >/tmp/clash-verge-ai-whitelist.log 2>&1 &
  elif command -v clash-verge-rev >/dev/null 2>&1; then nohup clash-verge-rev >/tmp/clash-verge-ai-whitelist.log 2>&1 &
  else echo "Clash Verge Rev binary not found in PATH; please reopen the app."; fi
fi

cat <<EOF

Installed successfully.

What was changed:
  1. Global Extend Script -> whitelist proxy rules
  2. All non-whitelisted traffic -> MATCH,DIRECT
  3. Rule mode -> enabled
  4. TUN -> $([[ $ENABLE_TUN -eq 1 ]] && echo enabled || echo unchanged)
  5. System proxy -> $([[ $ENABLE_SYSTEM_PROXY -eq 1 ]] && echo enabled || echo unchanged)

Backup:
  $BACKUP_DIR

Next:
  ./scripts/status.sh

Rollback:
  ./scripts/uninstall.sh
EOF
