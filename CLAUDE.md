# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Multi-Claw is a deployment orchestration system for **OpenClaw**, an AI agent platform with Telegram bot integration, deployed on DigitalOcean.

## Commands

### DigitalOcean Production

```bash
# Full automated deployment (10-step script)
./do/deploy.sh

# On the server (as openclaw user):
systemctl status openclaw-gateway.service
systemctl restart openclaw-gateway.service
journalctl -u openclaw-gateway.service -f
curl -I http://localhost:18789/
```

### SSH to Production

```bash
ssh root@165.245.137.3   # via 1Password SSH agent
ssh root@100.108.242.113 # via Tailscale
# App runs as `openclaw` user — always use: su - openclaw
```

## Architecture

### Model Fallback Chain

**Production**: OpenRouter Kimi K2.5 (primary) → NVIDIA Kimi K2.5 (fallback) → Anthropic Claude Sonnet 4.5 (fallback)

### Networking

- OpenClaw gateway listens on port **18789** (Control UI + WebSocket)
- Tailscale enabled for private SSH (openclaw-prod: `100.108.242.113`)
- Nginx reverse proxy on ports 80/443 with WebSocket support

### Data Persistence

All state in `~/.openclaw/`: config (`openclaw.json`), workspace, conversations, archives.

## Key Files

| File | Purpose |
|------|---------|
| `do/deploy.sh` | Automated 10-step production deployment script |
| `do/openclaw.json.template` | Production config template |
| `do/nginx.conf.template` | Nginx reverse proxy template |
| `do/.env.example` | Environment variable template |

## Important Conventions

- **Never commit `.env` files** — they contain API keys (Anthropic, OpenRouter, NVIDIA, Telegram)
- **Run app commands as `openclaw` user on production**, not root (prevents permission issues)
- Config files use `*.template` suffix in `do/` — actual configs are generated from these during deployment
- OpenClaw uses `pnpm` as its package manager (relevant for production builds)
