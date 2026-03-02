# OpenClaw × GitHub Copilot

> Use your existing **GitHub Copilot subscription** to power your OpenClaw AI agent — no separate Anthropic or OpenAI API keys needed.

If you already pay for GitHub Copilot, you have access to Claude Opus, Sonnet, Haiku, GPT-5.2, and Gemini 3 — this repo lets you use all of them inside OpenClaw on WhatsApp, Discord, or any channel you have configured.

---

## What this does

OpenClaw normally requires you to configure API keys for providers like Anthropic or OpenAI directly. This setup runs a small local proxy (Docker container) that sits between OpenClaw and GitHub's servers, translating the API calls so your Copilot subscription does the work.

```
You (WhatsApp / Discord / Web)
           │
           ▼
    OpenClaw gateway
           │
           ▼  (Anthropic messages format)
   copilot-proxy  ← this repo
           │
           ▼  (GitHub Copilot API)
    GitHub Copilot backend
    ┌──────────────────────────┐
    │  Claude Opus 4.5         │
    │  Claude Sonnet 4.5       │
    │  Claude Haiku 4.5        │
    │  GPT-5.2                 │
    │  Gemini 3 Pro Preview    │
    └──────────────────────────┘
```

---

## Requirements

- **GitHub Copilot subscription** (Individual, Business, or Enterprise)
- **OpenClaw** installed and running ([openclaw.ai](https://openclaw.ai))
- **Docker + Docker Compose** installed

---

## Setup

### 1. Clone this repo on the machine running OpenClaw

```bash
git clone https://github.com/shaike1/openclaw-copilot-setup.git
cd openclaw-copilot-setup
```

### 2. Run the setup script

```bash
bash setup.sh
```

The script will:
1. **Build and start the proxy** — Docker container on port `3002`
2. **Authenticate with GitHub** — opens a device-flow login (you visit a URL and enter a code)
3. **Patch your OpenClaw config** — adds `copilot-proxy` as a provider in `~/.openclaw/openclaw.json`
4. **Restart the OpenClaw gateway** — picks up the new config

> **Custom port?** `bash setup.sh 3005` runs the proxy on port 3005 instead.

### 3. Authenticate with GitHub Copilot

During step 2 the script will print something like:

```
→ Open: https://github.com/login/device
→ Code: ABCD-1234
```

Open that URL in your browser, enter the code, and approve access. This links the proxy to your GitHub Copilot account. You only need to do this once — the token is saved in a Docker volume.

### 4. Verify in your chat

Send this to your OpenClaw agent (WhatsApp, Discord, etc.):

```
/models copilot-proxy
```

You should see:

```
Models for copilot-proxy:
- claude-opus-4-5
- claude-sonnet-4-5
- claude-haiku-4-5
- gpt-5.2
- gemini-3-pro-preview
```

---

## Switching models

```
/model copilot-proxy/claude-sonnet-4-5   ← full model ID
/model Sonnet                            ← short alias
/model Opus
/model Haiku
/model GPT5
/model Gemini3
```

### All available models and aliases

| Model | Alias | Best for |
|---|---|---|
| `copilot-proxy/claude-opus-4-5` | `Opus` | Complex reasoning, long tasks |
| `copilot-proxy/claude-sonnet-4-5` | `Sonnet` | Balanced — fast and capable |
| `copilot-proxy/claude-haiku-4-5` | `Haiku` | Quick replies, simple tasks |
| `copilot-proxy/gpt-5.2` | `GPT5` | OpenAI GPT-5 generation |
| `copilot-proxy/gemini-3-pro-preview` | `Gemini3` | Google Gemini 3 |

---

## Troubleshooting

**`/models` doesn't show `copilot-proxy`**
- Make sure the proxy container is running: `docker ps | grep copilot`
- Restart the OpenClaw gateway: `systemctl --user restart openclaw-gateway.service`
- Re-run `bash setup.sh` — it's safe to run multiple times

**Proxy container not starting**
```bash
cd openclaw-copilot-setup/proxy
docker compose logs
```

**Token expired / authentication error**
```bash
curl http://127.0.0.1:3002/auth/initiate
# Visit the URL and code it prints, then try again
```

**OpenClaw is on a different machine than the proxy**
- Change `127.0.0.1` to the proxy machine's IP in `setup.sh` (the `PROXY_HOST` variable) before running

---

## Manual config (skip the script)

If you prefer to patch `~/.openclaw/openclaw.json` by hand, add this under `models.providers`:

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

---

## What's in this repo

```
openclaw-copilot-setup/
├── setup.sh        ← automated installer
├── README.md       ← this file
└── proxy/          ← proxy server source (TypeScript + Docker)
    ├── src/        ← Express server, GitHub Copilot auth, API translation
    ├── Dockerfile
    └── docker-compose.yml
```

The proxy is a TypeScript/Express server that:
- Authenticates with GitHub using OAuth device flow
- Automatically refreshes your Copilot token
- Translates Anthropic `messages` API calls → GitHub Copilot API calls
- Also supports OpenAI `chat/completions` format (for other tools)

---

## Disclaimer

This is for personal/educational use. Ensure your usage complies with [GitHub Copilot's Terms of Service](https://docs.github.com/en/site-policy/github-terms/github-terms-for-additional-products-and-features#github-copilot).

---

## Credits

Proxy based on [ClaudeCode-Copilot-Proxy](https://github.com/shyamsridhar123/ClaudeCode-Copilot-Proxy) (MIT License).
