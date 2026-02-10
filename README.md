# Multi-Claw: OpenClaw Multi-Environment Deployment

Production and development deployments of OpenClaw across multiple environments:
- **DigitalOcean (Production)**: Secure from-scratch installation (4GB Intel droplet)
- **Local Mac (Development)**: MacBook Pro M3 with Docker + native Ollama for hybrid AI

## Documentation

- **[do/](./do/)** - DigitalOcean production deployment
- **[local/](./local/)** - Local Mac development deployment

## DigitalOcean Deployment (Active)

**Live Instance: `openclaw-prod`**
- **IP:** `YOUR_DROPLET_IP` (kept in local `.env` as `DROPLET_IP`)
- **Size:** 4GB RAM, 2 vCPU, 80GB NVMe SSD
- **Cost:** $28/month
- **Status:** ✅ Active

**Documentation:** See [do/DIGITALOCEAN_SETUP.md](./do/DIGITALOCEAN_SETUP.md)

Quick start after SSH:
```bash
ssh root@YOUR_DROPLET_IP
# Follow steps in do/DIGITALOCEAN_SETUP.md (Steps 2-10)
```

**Key Guides:**
- [SETUP.md](./do/SETUP.md) - Complete installation and operations guide
- [README.md](./do/README.md) - Quick reference and common commands

---

## Local Mac Deployment (Development)

Below is the local development setup for MacBook Pro M3:

## Architecture

```
┌─────────────────────────────────────┐
│  MacBook Pro M3 (16GB)              │
│                                     │
│  ┌───────────────┐  ┌────────────┐  │
│  │ Ollama (native)│  │ Telegram   │  │
│  │ :11434         │  │ Bot API    │  │
│  └───────┬───────┘  └─────┬──────┘  │
│          │                │         │
│  ┌───────┴────────────────┴──────┐  │
│  │  Docker                       │  │
│  │  ┌─────────────────────────┐  │  │
│  │  │ OpenClaw Gateway        │  │  │
│  │  │ :18789 (Control UI)     │  │  │
│  │  │ connects to host Ollama │  │  │
│  │  │ + hosted API fallback   │  │  │
│  │  └─────────────────────────┘  │  │
│  │  Volume: ~/.openclaw/ (state) │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

## Features

- **Native Ollama** on Mac with Metal GPU acceleration
- **Hybrid model config**: Local models (qwen2.5-coder, mistral) + hosted Claude Sonnet
- **Telegram** messaging integration
- **Persistent state** via `~/.openclaw/` (workspace, conversation history)
- **Easy management** via startup/teardown scripts

## Prerequisites

- MacBook Pro M3 (or Apple Silicon Mac)
- Docker Desktop for Mac
- Ollama installed natively

## Quick Start

### Step 1: Install Ollama

```bash
# Install from https://ollama.com or via Homebrew
brew install ollama

# Pull recommended models
ollama pull qwen2.5-coder:14b  # 14B coding model (fits in 16GB RAM)
ollama pull mistral:7b          # Lightweight 7B model (fast fallback)

# Verify installation
ollama list
ollama run mistral:7b "Hello, test message"
```

### Step 2: Set up Telegram Bot

1. Open Telegram and message [@BotFather](https://t.me/botfather)
2. Create a new bot: `/newbot`
3. Follow prompts to name your bot
4. Save the bot token (looks like `123456789:ABCdefGHIjklMNOpqrsTUVwxyz`)
5. Get your Telegram user ID:
   - Message [@userinfobot](https://t.me/userinfobot)
   - Save your user ID (numeric)

### Step 3: Configure Environment

```bash
# Clone this repository (if not already done)
cd ~/github/multi-claw

# Copy environment template
cp .env.example .env

# Edit .env with your actual keys
nano .env  # or use your preferred editor
```

Fill in your `.env` file:

```bash
# Required: Anthropic API key for hosted Claude models
ANTHROPIC_API_KEY=sk-ant-your-actual-key-here

# Required: Telegram bot token from BotFather
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz

# Optional (defaults are fine)
OLLAMA_API_KEY=ollama-local
OLLAMA_BASE_URL=http://host.docker.internal:11434/v1
OPENCLAW_GATEWAY_PORT=18789
```

### Step 4: Configure Telegram Access

Edit `openclaw.json` to add your Telegram user ID:

```json
{
  "channels": {
    "telegram": {
      "botToken": "${TELEGRAM_BOT_TOKEN}",
      "allowFrom": ["YOUR_TELEGRAM_USER_ID"]
    }
  }
}
```

Replace `YOUR_TELEGRAM_USER_ID` with your numeric user ID from Step 2.

### Step 5: Start OpenClaw

```bash
# Start all services (Ollama + Docker)
./scripts/start.sh
```

This script will:
- Check if Ollama is running, start it if needed
- Verify recommended models are installed
- Create `~/.openclaw/` directory
- Copy `openclaw.json` to `~/.openclaw/`
- Start OpenClaw Gateway in Docker
- Display status and access URLs

### Step 6: Verify Deployment

1. **Control UI**: Open http://127.0.0.1:18789/ in your browser
2. **Telegram Bot**: Send a test message to your bot
3. **Logs**: Check Docker logs for activity:
   ```bash
   docker compose logs -f openclaw-gateway
   ```

## Configuration

### Model Configuration

The default `openclaw.json` configures hybrid models:

- **Primary**: `anthropic/claude-sonnet-4-20250514` (hosted, most capable)
- **Fallback**: `ollama/qwen2.5-coder:14b` (local, good for coding)
- **Fast local**: `ollama/mistral:7b` (lightweight, 7B)

To switch to local-only mode, edit `~/.openclaw/openclaw.json`:

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "ollama/qwen2.5-coder:14b",
        "fallback": "ollama/mistral:7b"
      }
    }
  }
}
```

### Adding More Ollama Models

```bash
# List available models
ollama list

# Pull additional models
ollama pull codellama:13b
ollama pull deepseek-coder:6.7b

# Update openclaw.json to register them
```

## Chatting with the Agent

### Via CLI (command line)

```bash
# Ask the agent a question
docker compose exec openclaw-gateway npx openclaw agent \
  --channel telegram --to YOUR_TELEGRAM_USER_ID \
  --message "What can you do?"

# With explicit thinking level
docker compose exec openclaw-gateway npx openclaw agent \
  --channel telegram --to YOUR_TELEGRAM_USER_ID \
  --thinking medium \
  --message "Write a Python fizzbuzz"

# Send the reply back to Telegram
docker compose exec openclaw-gateway npx openclaw agent \
  --channel telegram --to YOUR_TELEGRAM_USER_ID \
  --deliver \
  --message "Summarize today's tasks"

# JSON output (useful for scripting)
docker compose exec openclaw-gateway npx openclaw agent \
  --channel telegram --to YOUR_TELEGRAM_USER_ID \
  --json \
  --message "Hello"
```

### Via Telegram

Send a message to your bot in the Telegram app.

### Via Control UI

Open the dashboard in your browser:

```
http://127.0.0.1:18789/?token=YOUR_GATEWAY_TOKEN
```

Use the **Chat** tab to interact with the agent directly.

### Send a message (no agent processing)

```bash
# Send a plain message via Telegram
docker compose exec openclaw-gateway npx openclaw message send \
  --channel telegram --target YOUR_TELEGRAM_USER_ID \
  --message "Hello from CLI!"
```

## Management

### Start Services

```bash
./scripts/start.sh
```

### Stop Services

```bash
./scripts/stop.sh
```

### View Logs

```bash
# Real-time logs
docker compose logs -f openclaw-gateway

# Last 100 lines
docker compose logs --tail=100 openclaw-gateway
```

### Restart Services

```bash
docker compose restart openclaw-gateway
```

### Check Status

```bash
# Docker service status
docker compose ps

# Ollama status
curl http://localhost:11434/api/tags
ollama list
```

## Data Persistence

All OpenClaw state is stored in `~/.openclaw/`:

```
~/.openclaw/
├── openclaw.json          # Configuration
├── workspace/             # Agent workspace (treat as git repo)
└── conversations/         # Chat history
```

**Backup recommendations**:
- Track `workspace/` in git for version control
- Backup `conversations/` periodically
- Keep `openclaw.json` in version control (template form)

## Troubleshooting

### Ollama Not Accessible from Docker

**Symptom**: OpenClaw can't reach Ollama models

**Solution**:
```bash
# Verify Ollama is running
curl http://localhost:11434/api/tags

# Test from Docker container
docker run --rm curlimages/curl:latest curl http://host.docker.internal:11434/api/tags
```

### Docker Container Won't Start

**Symptom**: `docker compose up` fails

**Solution**:
```bash
# Check logs
docker compose logs openclaw-gateway

# Verify .env file exists and has correct keys
cat .env

# Rebuild image
docker compose pull openclaw-gateway
```

### Telegram Bot Not Responding

**Symptom**: Messages to bot show no response

**Solution**:
1. Verify bot token in `.env` is correct
2. Check `allowFrom` in `openclaw.json` includes your user ID
3. Review Docker logs for Telegram errors:
   ```bash
   docker compose logs -f openclaw-gateway | grep -i telegram
   ```

### Out of Memory (16GB Mac)

**Symptom**: System slows down, Ollama crashes

**Solution**:
```bash
# Use smaller models
ollama pull mistral:7b      # Only 4GB
ollama pull phi:2.7b        # Only 1.6GB

# Update openclaw.json to use smaller models
# Stop other memory-intensive apps
```

### Model Download Fails

**Symptom**: `ollama pull` times out or fails

**Solution**:
```bash
# Check internet connection
# Try a smaller model first
ollama pull mistral:7b

# Or use a different mirror (if available)
```

## Advanced Usage

### Use OpenClaw with Claude Code (CLI)

This repo is designed to work with Claude Code:

```bash
# Ask Claude Code to help configure OpenClaw
claude "Add support for deepseek-coder model to openclaw.json"

# Debug issues
claude "Check why Telegram bot isn't responding"

# Extend functionality
claude "Create a health check script for all services"
```

### Custom Docker Compose Overrides

Create `docker-compose.override.yml` for local customizations:

```yaml
version: '3.8'
services:
  openclaw-gateway:
    environment:
      - DEBUG=true
    ports:
      - "18790:18790"  # Additional port
```

### Network Debugging

```bash
# Test Ollama from host
curl http://localhost:11434/v1/models

# Test from inside container
docker compose exec openclaw-gateway curl http://host.docker.internal:11434/v1/models
```

## Project Structure

```
multi-claw/
├── docker-compose.yml     # OpenClaw container definition
├── .env.example           # Environment template (copy to .env)
├── .gitignore             # Excludes .env, secrets
├── openclaw.json          # Default OpenClaw config (template)
├── README.md              # This file
└── scripts/
    ├── start.sh           # Startup script
    └── stop.sh            # Teardown script
```

## Resources

- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [Ollama Documentation](https://ollama.com)
- [Docker Desktop for Mac](https://docs.docker.com/desktop/mac/install/)
- [Anthropic API Docs](https://docs.anthropic.com/)
- [Telegram Bot API](https://core.telegram.org/bots/api)

## License

This repository is a deployment configuration for OpenClaw. See individual component licenses:
- OpenClaw: Check upstream repository
- Ollama: MIT License

## Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Test your changes on Mac M3
4. Submit a pull request

## Support

- Issues: https://github.com/openclaw/openclaw/issues
- Discussions: Check OpenClaw repository
- Telegram: Create a support chat via your bot
