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
    if [[ -f "$c/verge.yaml" || -f "$c/profiles.yaml" ]]; then printf '%s\n' "$c"; return; fi
  done
  exit 1
}

APP_HOME="$(detect_home)"
VERGE_YAML="$APP_HOME/verge.yaml"
CONFIG_YAML="$APP_HOME/config.yaml"
RUNTIME_YAML="$APP_HOME/clash-verge.yaml"
GLOBAL_SCRIPT="$APP_HOME/profiles/Script.js"

echo "Clash Verge Rev home: $APP_HOME"
echo

echo "== GUI/control settings =="
grep -E '^(enable_tun_mode|enable_system_proxy|verge_mixed_port):' "$VERGE_YAML" 2>/dev/null || true
grep -E '^mode:' "$CONFIG_YAML" 2>/dev/null || true
echo

echo "== Global Script =="
if [[ -f "$GLOBAL_SCRIPT" ]] && grep -q 'Managed by clash-ai-whitelist' "$GLOBAL_SCRIPT"; then
  echo "OK: managed Script.js installed"
else
  echo "WARN: managed Script.js not detected"
fi
echo

echo "== Runtime rules =="
if [[ -f "$RUNTIME_YAML" ]]; then
  for d in chatgpt.com github.com huggingface.co claude.ai grok.com; do
    if grep -Fq "$d" "$RUNTIME_YAML"; then echo "OK: $d"; else echo "MISS: $d"; fi
  done
  if grep -Eq '^[[:space:]]*-[[:space:]]*MATCH,DIRECT[[:space:]]*$' "$RUNTIME_YAML"; then echo "OK: MATCH,DIRECT"; else echo "MISS: MATCH,DIRECT"; fi
else
  echo "Runtime file not found yet: $RUNTIME_YAML"
  echo "Open/restart Clash Verge Rev and activate the current profile, then rerun."
fi
echo

PORT="$(awk -F': *' '/^verge_mixed_port:/ {print $2; exit}' "$VERGE_YAML" 2>/dev/null || true)"
PORT="${PORT:-7897}"

echo "== Optional HTTP proxy reachability (127.0.0.1:${PORT}) =="
if command -v curl >/dev/null 2>&1; then
  for url in https://chatgpt.com https://github.com https://huggingface.co; do
    code="$(curl -x "http://127.0.0.1:${PORT}" -L -sS -o /dev/null -w '%{http_code}' --max-time 8 "$url" 2>/dev/null || true)"
    if [[ -n "$code" && "$code" != "000" ]]; then echo "OK: $url -> HTTP $code"; else echo "FAIL: $url"; fi
  done
else
  echo "curl not installed; skipping network checks."
fi
