# OpenClaw Quick Start Guide

## One-Time Setup (5 minutes)

### 1. Install Ollama
```bash
brew install ollama
ollama pull qwen2.5-coder:14b
ollama pull mistral:7b
```

### 2. Create Telegram Bot
1. Message [@BotFather](https://t.me/botfather) on Telegram
2. Run `/newbot` and follow prompts
3. Save the bot token
4. Message [@userinfobot](https://t.me/userinfobot) to get your user ID

### 3. Configure Environment
```bash
cp .env.example .env
# Edit .env with your API keys:
# - ANTHROPIC_API_KEY (from https://console.anthropic.com/)
# - TELEGRAM_BOT_TOKEN (from BotFather)

# Edit openclaw.json to add your Telegram user ID in allowFrom array
```

## Daily Usage

### Start Everything
```bash
./scripts/start.sh
```

### Check Status
```bash
# View logs
docker compose logs -f

# Check Ollama models
ollama list

# Test Ollama
curl http://localhost:11434/api/tags
```

### Stop Everything
```bash
./scripts/stop.sh
```

## Common Commands

### Ollama Model Management
```bash
# List installed models
ollama list

# Pull a new model
ollama pull codellama:13b

# Remove a model
ollama rm mistral:7b

# Test a model
ollama run qwen2.5-coder:14b "Write a hello world in Python"
```

### Docker Management
```bash
# View logs (real-time)
docker compose logs -f openclaw-gateway

# Restart gateway
docker compose restart openclaw-gateway

# Rebuild and restart
docker compose down
docker compose pull
docker compose up -d

# Check container status
docker compose ps
```

### Configuration
```bash
# Edit OpenClaw config
nano ~/.openclaw/openclaw.json

# View current config
cat ~/.openclaw/openclaw.json

# Backup workspace
tar -czf ~/openclaw-backup-$(date +%Y%m%d).tar.gz ~/.openclaw/
```

## Verification Checklist

After starting, verify:

- [ ] Ollama is running: `curl http://localhost:11434/api/tags`
- [ ] Docker container is up: `docker compose ps`
- [ ] Control UI accessible: http://127.0.0.1:18789/
- [ ] Telegram bot responds to test message
- [ ] Logs show no errors: `docker compose logs --tail=50`

## Troubleshooting Quick Fixes

### "Ollama connection refused"
```bash
# Start Ollama manually
ollama serve &
sleep 3
curl http://localhost:11434/api/tags
```

### "Docker container keeps restarting"
```bash
# Check logs for errors
docker compose logs openclaw-gateway

# Verify .env exists and has correct format
cat .env
```

### "Telegram bot not responding"
```bash
# Verify bot token
grep TELEGRAM_BOT_TOKEN .env

# Check if your user ID is in allowFrom
cat ~/.openclaw/openclaw.json | grep -A2 allowFrom

# View Telegram-related logs
docker compose logs openclaw-gateway | grep -i telegram
```

### "Out of memory"
```bash
# Use smaller models
ollama pull mistral:7b
ollama pull phi:2.7b

# Update ~/.openclaw/openclaw.json to use smaller models
# Restart: docker compose restart
```

## Model Recommendations

### For 16GB Mac (M3)
- **Best balance**: `qwen2.5-coder:14b` (14B, ~8GB RAM)
- **Fastest**: `mistral:7b` (7B, ~4GB RAM)
- **Smallest**: `phi:2.7b` (2.7B, ~1.6GB RAM)

### For Coding Tasks
- `qwen2.5-coder:14b` - Excellent for code generation
- `codellama:13b` - Good for code completion
- `deepseek-coder:6.7b` - Fast, good quality

### For General Chat
- `mistral:7b` - Great general purpose
- `llama2:13b` - Better reasoning
- `neural-chat:7b` - Conversational

## Accessing OpenClaw

### Control UI
http://127.0.0.1:18789/

### Telegram
Send messages to your bot (search for it by username in Telegram)

### API (if exposed)
```bash
# Example: list agents
curl http://localhost:18789/api/agents

# Health check
curl http://localhost:18789/health
```

## Data Locations

- **Config**: `~/.openclaw/openclaw.json`
- **Workspace**: `~/.openclaw/workspace/`
- **Conversations**: `~/.openclaw/conversations/`
- **Docker volumes**: Check `docker volume ls`

## Next Steps

1. Test local model: Send "Hello, use local model" via Telegram
2. Test hosted model: Send complex coding request
3. Explore workspace: `cd ~/.openclaw/workspace && ls -la`
4. Review documentation: See `README.md` for full details

## Getting Help

- Full docs: See `README.md`
- OpenClaw issues: https://github.com/openclaw/openclaw/issues
- Ollama docs: https://ollama.com
- Docker logs: `docker compose logs -f`
