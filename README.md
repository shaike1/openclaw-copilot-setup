# OpenClaw + GitHub Copilot

Use your GitHub Copilot subscription as an AI provider inside [OpenClaw](https://openclaw.ai).

## How it works

```
Your chat (WhatsApp/Discord)
        │
        ▼
  OpenClaw gateway
        │  (anthropic-messages API)
        ▼
  copilot proxy (Docker)   ←── authenticates with GitHub Copilot
        │
        ▼
  GitHub Copilot backend
  (Claude Opus/Sonnet/Haiku, GPT-5.2, Gemini 3)
```

## Requirements

- Docker + Docker Compose
- OpenClaw installed and running
- GitHub account with an active Copilot subscription

## Quick Setup

```bash
git clone <this-repo>
cd openclaw-copilot-setup
bash setup.sh
```

Optional: specify a custom proxy port (default `3002`):
```bash
bash setup.sh 3005
```

The script will:
1. Build and start the proxy via Docker
2. Walk you through GitHub OAuth device-flow login
3. Patch `~/.openclaw/openclaw.json` to add `copilot-proxy` as a provider
4. Restart the OpenClaw gateway

## Usage in OpenClaw chat

```
/models copilot-proxy                   → list available Copilot models
/model copilot-proxy/claude-sonnet-4-5  → switch to Sonnet
/model Sonnet                           → switch using alias
/model GPT5
/model Gemini3
```

## Available models

| Model ID | Alias |
|---|---|
| `copilot-proxy/claude-opus-4-5` | `Opus` |
| `copilot-proxy/claude-sonnet-4-5` | `Sonnet` |
| `copilot-proxy/claude-haiku-4-5` | `Haiku` |
| `copilot-proxy/gpt-5.2` | `GPT5` |
| `copilot-proxy/gemini-3-pro-preview` | `Gemini3` |

## Manual config (optional)

Add to `~/.openclaw/openclaw.json` under `models.providers`:

```json
"copilot-proxy": {
  "baseUrl": "http://127.0.0.1:3002",
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
```

And under `agents.defaults.models`:

```json
"copilot-proxy/claude-opus-4-5":      {"alias": "Opus"},
"copilot-proxy/claude-sonnet-4-5":    {"alias": "Sonnet"},
"copilot-proxy/claude-haiku-4-5":     {"alias": "Haiku"},
"copilot-proxy/gpt-5.2":              {"alias": "GPT5"},
"copilot-proxy/gemini-3-pro-preview": {"alias": "Gemini3"}
```

Then restart: `systemctl --user restart openclaw-gateway.service`

## Credits

Proxy source based on [ClaudeCode-Copilot-Proxy](https://github.com/shyamsridhar123/ClaudeCode-Copilot-Proxy) (MIT License).
