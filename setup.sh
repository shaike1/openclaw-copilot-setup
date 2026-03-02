#!/usr/bin/env bash
# openclaw-copilot-setup/setup.sh
# Adds GitHub Copilot models to your OpenClaw instance
# Usage: bash setup.sh [PROXY_PORT]
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROXY_PORT="${1:-3002}"
PROXY_HOST="127.0.0.1"
OPENCLAW_JSON="${HOME}/.openclaw/openclaw.json"

echo "=== OpenClaw + GitHub Copilot Setup ==="
echo ""

# ── 1. Start the proxy ────────────────────────────────────────────────────────
if ! curl -sf "http://${PROXY_HOST}:${PROXY_PORT}/health" > /dev/null 2>&1; then
  echo "[1/3] Starting copilot proxy on port ${PROXY_PORT}..."
  cd "${SCRIPT_DIR}/proxy"
  # Update port in docker-compose.yml
  sed -i "s/\"[0-9]*:3000\"/\"${PROXY_PORT}:3000\"/" docker-compose.yml
  docker compose up -d --build
  echo "Waiting for proxy to start..."
  for i in $(seq 1 15); do
    curl -sf "http://${PROXY_HOST}:${PROXY_PORT}/health" > /dev/null 2>&1 && break
    sleep 2
  done
  cd "${SCRIPT_DIR}"
else
  echo "[1/3] Proxy already running on port ${PROXY_PORT} ✓"
fi

# ── 2. Authenticate with GitHub Copilot ──────────────────────────────────────
echo ""
echo "[2/3] Authenticating with GitHub Copilot..."
AUTH_RESPONSE=$(curl -sf "http://${PROXY_HOST}:${PROXY_PORT}/auth/initiate" 2>/dev/null || true)
if [ -n "$AUTH_RESPONSE" ]; then
  echo "$AUTH_RESPONSE" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    uri = data.get('verification_uri') or data.get('verificationUri', '')
    code = data.get('user_code') or data.get('userCode', '')
    if uri:
        print(f'  → Open: {uri}')
        print(f'  → Code: {code}')
    else:
        print('  Already authenticated ✓')
except:
    print('  Already authenticated ✓')
" 2>/dev/null
else
  echo "  Already authenticated ✓"
fi
echo ""
read -p "Press Enter once you have completed GitHub authentication (or if already done)..."

# ── 3. Patch openclaw.json ────────────────────────────────────────────────────
echo ""
echo "[3/3] Updating ${OPENCLAW_JSON}..."

if [ ! -f "${OPENCLAW_JSON}" ]; then
  echo "ERROR: ${OPENCLAW_JSON} not found. Is OpenClaw installed?"
  exit 1
fi

cp "${OPENCLAW_JSON}" "${OPENCLAW_JSON}.bak"

python3 << PYEOF
import json

path = "${OPENCLAW_JSON}"
proxy_url = "http://${PROXY_HOST}:${PROXY_PORT}"

with open(path) as f:
    cfg = json.load(f)

cfg.setdefault("models", {}).setdefault("providers", {})
cfg["models"]["providers"]["copilot-proxy"] = {
    "baseUrl": proxy_url,
    "api": "anthropic-messages",
    "apiKey": "sk-dummy",
    "models": [
        {"id": "claude-opus-4-5",      "name": "Claude Opus 4.5 (Copilot)"},
        {"id": "claude-sonnet-4-5",    "name": "Claude Sonnet 4.5 (Copilot)"},
        {"id": "claude-haiku-4-5",     "name": "Claude Haiku 4.5 (Copilot)"},
        {"id": "gpt-5.2",              "name": "GPT-5.2 (Copilot)"},
        {"id": "gemini-3-pro-preview", "name": "Gemini 3 Pro Preview (Copilot)"}
    ]
}

cfg.setdefault("agents", {}).setdefault("defaults", {}).setdefault("models", {})
m = cfg["agents"]["defaults"]["models"]
m["copilot-proxy/claude-opus-4-5"]      = {"alias": "Opus"}
m["copilot-proxy/claude-sonnet-4-5"]    = {"alias": "Sonnet"}
m["copilot-proxy/claude-haiku-4-5"]     = {"alias": "Haiku"}
m["copilot-proxy/gpt-5.2"]              = {"alias": "GPT5"}
m["copilot-proxy/gemini-3-pro-preview"] = {"alias": "Gemini3"}

with open(path, "w") as f:
    json.dump(cfg, f, indent=2)

print("  openclaw.json updated ✓")
PYEOF

# ── 4. Restart OpenClaw gateway ───────────────────────────────────────────────
echo ""
echo "Restarting OpenClaw gateway..."
systemctl --user restart openclaw-gateway.service 2>/dev/null \
  || systemctl restart openclaw-gateway.service 2>/dev/null \
  || echo "  (Restart openclaw manually: systemctl --user restart openclaw-gateway.service)"

echo ""
echo "=== Done! ==="
echo ""
echo "In your OpenClaw chat, run:"
echo "  /models copilot-proxy                    — list Copilot models"
echo "  /model copilot-proxy/claude-sonnet-4-5  — switch to Sonnet"
echo "  /model Sonnet                            — switch using alias"
