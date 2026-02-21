# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Multi-Claw is a multi-environment deployment orchestration system for **OpenClaw**, an AI agent platform with Telegram bot integration. It manages two environments:

- **`do/`** — DigitalOcean production deployment (Ubuntu 24.04, 4GB Intel droplet)
- **`local/`** — Local Mac M3 development with Docker + Ollama hybrid AI stack

## Commands

### Local Development (Mac)

```bash
# Lifecycle
./local/scripts/start.sh            # Start Ollama + Docker
./local/scripts/stop.sh             # Stop services
./local/scripts/verify.sh           # Pre-flight checks (env, Ollama, Docker, config)
./local/scripts/install-models.sh   # Interactive Ollama model installer

# Logs & status
docker compose -f local/docker-compose.yml logs -f
docker compose -f local/docker-compose.yml ps

# Health check
curl -s http://localhost:18789/health
```

### DigitalOcean Production

```bash
# Full automated deployment (10-step script)
./do/deploy.sh

# On the server (as openclaw user):
systemctl status openclaw.service
systemctl restart openclaw.service
journalctl -u openclaw.service -f
curl -s http://localhost:18789/health
```

### SSH to Production

```bash
ssh root@165.245.137.3   # via 1Password SSH agent
# App runs as `openclaw` user — always use: su - openclaw
```

## Architecture

### Model Fallback Chains

**Local**: Anthropic Claude Sonnet (primary) → Ollama qwen2.5-coder:14b (fallback)
**Production**: OpenRouter Kimi K2.5 (primary) → NVIDIA Kimi K2.5 (fallback) → Anthropic Claude Sonnet 4.5 (fallback)

### Networking

- OpenClaw gateway listens on port **18789** (Control UI + WebSocket)
- Local: Docker container reaches Ollama via `host.docker.internal:11434`
- Production: Nginx reverse proxy on ports 80/443 with WebSocket support

### Data Persistence

All state in `~/.openclaw/`: config (`openclaw.json`), workspace, conversations, archives. Volume-mounted into Docker on local.

## Key Files

| File | Purpose |
|------|---------|
| `local/docker-compose.yml` | Local Docker composition for OpenClaw gateway |
| `local/openclaw.json` | Local OpenClaw config (models, Telegram, agents) |
| `do/deploy.sh` | Automated 10-step production deployment script |
| `do/openclaw.json.template` | Production config template |
| `do/nginx.conf.template` | Nginx reverse proxy template |
| `local/.env.example` / `do/.env.example` | Environment variable templates |

## Important Conventions

- **Never commit `.env` files** — they contain API keys (Anthropic, OpenRouter, NVIDIA, Telegram)
- **Run app commands as `openclaw` user on production**, not root (prevents permission issues)
- Config files use `*.template` suffix in `do/` — actual configs are generated from these during deployment
- OpenClaw uses `pnpm` as its package manager (relevant for production builds)
