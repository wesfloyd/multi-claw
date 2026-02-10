# OpenClaw Deployment Plan & Progress

## Remaining Steps

- [ ] **Test Telegram bot** - Send message to your bot, verify response
- [ ] **Test Control UI** - Open dashboard, verify agent works
- [ ] **Test local Ollama model** - Switch agent to ollama/qwen2.5-coder:14b, send query
- [ ] **Commit final config** - Commit fixed openclaw.json and docker-compose.yml

## Completed Steps

- [x] **1. Repo scaffolding** - docker-compose.yml, scripts, configs, .gitignore
- [x] **2. Install Ollama** - Native on Mac, Metal GPU acceleration
- [x] **3. Pull models** - qwen2.5-coder:14b (9 GB) installed
- [x] **4. Configure .env** - ANTHROPIC_API_KEY + TELEGRAM_BOT_TOKEN set
- [x] **5. Create Telegram bot** - Bot created, token obtained
- [x] **6. Update openclaw.json** - Telegram user ID added
- [x] **7. Fix Docker image** - Changed to alpine/openclaw:latest
- [x] **8. Fix volume mount** - /home/node/.openclaw (not /root)
- [x] **9. Fix config format** - Ran openclaw doctor --fix, set gateway.mode local
- [x] **10. Set gateway token** - OPENCLAW_GATEWAY_TOKEN configured
- [x] **11. Approve Telegram pairing** - User approved
- [x] **12. Start OpenClaw** - Gateway running on port 18789

## Issues Encountered & Fixed

| Issue | Fix |
|-------|-----|
| Docker image `openclaw/openclaw` not found | Use `alpine/openclaw:latest` |
| Volume mounted to wrong path `/root/.openclaw` | Changed to `/home/node/.openclaw` |
| Config fields wrong (`id` without `name`, `description` invalid) | Added required fields per OpenClaw schema |
| `agents.defaults.model` must be object not string | Use `{"primary": "..."}` |
| Gateway token required | Generated and set `OPENCLAW_GATEWAY_TOKEN` |
| `gateway.mode` not set | Set to `local` via `openclaw config set` |
| Telegram "not enabled yet" | Ran `openclaw doctor --fix` to enable |

## Current Status

- Gateway: **RUNNING** on ws://127.0.0.1:18789
- Agent model: anthropic/claude-sonnet-4-20250514
- Telegram: Bot started
- Ollama: qwen2.5-coder:14b available at host.docker.internal:11434

## Dashboard URL

http://127.0.0.1:18789/?token=YOUR_GATEWAY_TOKEN

## Architecture

- Ollama: Native on Mac (port 11434)
- OpenClaw: Docker container (port 18789)
- Docker → Ollama via host.docker.internal
- State persists in ~/.openclaw/ (host Mac)
- Models stored in ~/.ollama/models/ (host Mac, 9 GB used)

## Disk Usage

- Disk total: 770 GB
- Disk used: ~252 GB (243 + 9 GB models)
- Disk free: ~518 GB
