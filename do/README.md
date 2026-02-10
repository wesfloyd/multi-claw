# OpenClaw DigitalOcean Deployment

Production OpenClaw deployment on DigitalOcean droplet.

## Deployment Details

**Bot**: @your_bot_username
**IP**: YOUR_DROPLET_IP
**Region**: YOUR_REGION
**Specs**: 2 vCPU, 4GB RAM (Intel)
**OS**: Ubuntu 24.04 LTS
**Port**: 18789

**Model Configuration**:
- Primary: Kimi K2.5 (via OpenRouter)
- Fallback: NVIDIA Kimi K2.5, Claude Sonnet 4.5
- Web Search: Perplexity Sonar Pro (via OpenRouter)

## Quick Access

```bash
# SSH to droplet
ssh root@YOUR_DROPLET_IP

# View logs
journalctl -u openclaw.service -f

# Restart service
systemctl restart openclaw.service

# Health check
curl http://YOUR_DROPLET_IP:18789/health
```

## Documentation

See [SETUP.md](./SETUP.md) for complete installation guide covering:
1. Prerequisites
2. Installation (10 steps)
3. Telegram Configuration
4. Operations & Monitoring
5. Troubleshooting
6. Security Hardening
7. Optional: DNS & HTTPS

## Template Files

Configuration templates for deployment:

- [.env.example](./.env.example) - Environment variables template
- [openclaw.json.template](./openclaw.json.template) - OpenClaw config template
- [nginx.conf.template](./nginx.conf.template) - Nginx reverse proxy config (if exists)

## Configuration Files

**On droplet:**
- `/home/openclaw/openclaw/.env` - Environment variables (API keys, secrets)
- `/home/openclaw/.openclaw/openclaw.json` - OpenClaw configuration
- `/etc/systemd/system/openclaw.service` - systemd service definition

**Gitignored (local only):**
- `.env.connection` - Connection details and quick commands

## Common Commands

```bash
# Service management
systemctl status openclaw.service
systemctl restart openclaw.service
journalctl -u openclaw.service -f
journalctl -u openclaw.service -n 100 --no-pager

# Configuration
nano /home/openclaw/.openclaw/openclaw.json
nano /home/openclaw/openclaw/.env

# Monitoring
htop
df -h
free -h
ss -tulpn | grep 18789

# Updates
cd /home/openclaw/openclaw
git pull origin main
pnpm install && pnpm build
systemctl restart openclaw.service

# Backup
tar -czf ~/openclaw-backup-$(date +%Y%m%d).tar.gz /home/openclaw/.openclaw
```

## API Dashboards

- Anthropic: https://console.anthropic.com/settings/cost
- OpenRouter: https://openrouter.ai/credits

## Support

For troubleshooting, see [SETUP.md](./SETUP.md) Troubleshooting section or check:
- [OpenClaw Docs](https://docs.openclaw.ai)
- [OpenClaw GitHub Issues](https://github.com/openclaw/openclaw/issues)
