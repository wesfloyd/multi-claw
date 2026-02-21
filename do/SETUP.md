# OpenClaw DigitalOcean Setup Guide

Complete installation guide for OpenClaw on DigitalOcean from scratch.

## Prerequisites

- DigitalOcean account with billing enabled
- SSH key pair for server access
- API keys: Anthropic, OpenRouter (optional: NVIDIA)
- Domain name (optional but recommended for HTTPS)
- 15 minutes setup time

## Installation

### Step 1: Create DigitalOcean Droplet

1. **Create Droplet**
   - OS: Ubuntu 24.04 LTS (Noble)
   - Size: s-2vcpu-4gb-intel ($28/month)
   - Region: Choose closest to users
   - Enable monitoring and daily backups
   - Add your SSH key

2. **SSH Access**
   ```bash
   ssh root@YOUR_DROPLET_IP
   ```

### Step 2: Initial Server Hardening

```bash
# Update system packages
apt-get update && apt-get upgrade -y

# Create non-root user
useradd -m -s /bin/bash openclaw
usermod -aG sudo openclaw

# Copy SSH key to new user
mkdir -p /home/openclaw/.ssh
cp /root/.ssh/authorized_keys /home/openclaw/.ssh/
chown -R openclaw:openclaw /home/openclaw/.ssh
chmod 700 /home/openclaw/.ssh
chmod 600 /home/openclaw/.ssh/authorized_keys

# Configure UFW firewall
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 18789/tcp
ufw --force enable
```

### Step 3: Install Node.js v22

OpenClaw requires Node.js >= 22.12.0

```bash
# Install Node.js v22
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs

# Verify installation
node --version  # Should show v22.x.x
npm --version   # Should show v10.x.x

# Install pnpm
npm install -g pnpm
pnpm --version
```

### Step 4: Clone OpenClaw Repository

```bash
# Switch to openclaw user
su - openclaw

# Clone repository
cd /home/openclaw
git clone https://github.com/openclaw/openclaw.git
cd openclaw
```

### Step 5: Configure Environment

Create `/home/openclaw/openclaw/.env`:

```bash
# OpenClaw Configuration
NODE_ENV=production
OPENCLAW_PORT=18789

# LLM Configuration
ANTHROPIC_API_KEY=your-anthropic-api-key-here
OPENCLAW_MODEL=openrouter/moonshotai/kimi-k2.5

# Web Search (Perplexity Sonar via OpenRouter)
OPENROUTER_API_KEY=your-openrouter-api-key-here

# NVIDIA (optional fallback provider for Kimi)
NVIDIA_API_KEY=your-nvidia-api-key-here

# Telegram Bot
TELEGRAM_BOT_TOKEN=your-telegram-bot-token-here

# Security
SESSION_SECRET=$(openssl rand -base64 32)
OPENCLAW_GATEWAY_TOKEN=$(openssl rand -hex 32)
```

**DO NOT commit this file to git!**

### Step 6: Build OpenClaw

```bash
cd /home/openclaw/openclaw

# Install dependencies (~2 minutes)
pnpm install

# Build application (~3 minutes)
pnpm build

# Verify build
ls -la dist/
```

### Step 7: Initialize Configuration

```bash
# Run doctor to create initial config
node dist/index.js doctor --fix

# Configure gateway mode
node dist/index.js config set gateway.mode local
node dist/index.js config set gateway.port 18789
```

Edit `~/.openclaw/openclaw.json` (see openclaw.json.template for full config):

```json
{
  "gateway": {
    "mode": "local",
    "port": 18789
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "openrouter/moonshotai/kimi-k2.5",
        "fallbacks": [
          "nvidia/moonshotai/kimi-k2.5",
          "anthropic/claude-sonnet-4-5-20250929"
        ]
      }
    }
  },
  "models": {
    "mode": "merge",
    "providers": {
      "nvidia": {
        "api": "openai-completions",
        "baseUrl": "https://integrate.api.nvidia.com/v1",
        "apiKey": "${NVIDIA_API_KEY}",
        "models": [
          {
            "id": "moonshotai/kimi-k2.5",
            "name": "Kimi K2.5 (NVIDIA)"
          }
        ]
      }
    }
  },
  "tools": {
    "web": {
      "search": {
        "enabled": true,
        "provider": "perplexity",
        "perplexity": {
          "baseUrl": "https://openrouter.ai/api/v1",
          "model": "perplexity/sonar-pro"
        }
      }
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "name": "your_bot_name",
      "allowFrom": ["YOUR_TELEGRAM_USER_ID"]
    }
  },
  "plugins": {
    "entries": {
      "telegram": {
        "enabled": true
      }
    }
  }
}
```

Get Telegram user ID from [@userinfobot](https://t.me/userinfobot)

### Step 8: Set Up systemd Service (System-Level)

Exit to root user and create service:

```bash
exit  # Exit from openclaw user

cat > /etc/systemd/system/openclaw-gateway.service << 'EOF'
[Unit]
Description=OpenClaw Gateway
After=network.target

[Service]
Type=simple
User=openclaw
Group=openclaw
Environment="PATH=/home/openclaw/.npm-global/bin:/usr/local/bin:/usr/bin:/bin"
Environment="HOME=/home/openclaw"
Environment="OPENCLAW_PORT=18789"
WorkingDirectory=/home/openclaw
ExecStart=/home/openclaw/.npm-global/bin/openclaw gateway run
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
systemctl daemon-reload
systemctl enable openclaw-gateway.service
systemctl start openclaw-gateway.service

# Check status
systemctl status openclaw-gateway.service
journalctl -u openclaw-gateway.service -f
```

### Step 9: Set Up Reverse Proxy (Optional)

For HTTPS and domain access:

```bash
# Install Nginx
apt-get install -y nginx certbot python3-certbot-nginx

# Create Nginx config (see nginx.conf.template for full version)
cat > /etc/nginx/sites-available/openclaw << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name _;

    location / {
        proxy_pass http://127.0.0.1:18789;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_cache_bypass $http_upgrade;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF

# Enable the site
ln -s /etc/nginx/sites-available/openclaw /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx

# Get SSL certificate (after DNS points to your IP)
# certbot certonly --nginx -d your-domain.com
```

### Step 10: Verification

```bash
# Health check
curl -I http://localhost:18789/
# Note: the gateway UI responds with HTML on `/`.

# View logs
journalctl -u openclaw-gateway.service -f

# Test Telegram bot
# Send message to your bot on Telegram
```

## Telegram Configuration

### Create Bot (if not already created)

1. Message [@BotFather](https://t.me/botfather)
2. Send: `/newbot`
3. Follow prompts to create bot
4. Save the bot token to `.env` as `TELEGRAM_BOT_TOKEN`

### Configure Bot

```bash
# Set commands
/setcommands
Select: @your_bot_username
Paste:
help - Show available commands
status - Check bot status
reset - Start a new conversation
model - Change AI model

# Set description
/setdescription
Select: @your_bot_username
Description:
OpenClaw AI Agent - Multi-tool coding assistant powered by Claude and local models.

# Set privacy mode
/setprivacy
Select: @your_bot_username
Choose: Enable
```

### Get Your Telegram User ID

1. Message [@userinfobot](https://t.me/userinfobot)
2. Copy the numeric ID
3. Add to `~/.openclaw/openclaw.json` in `channels.telegram.allowFrom` array

## Operations & Monitoring

### Service Management

```bash
# View status
systemctl status openclaw-gateway.service

# Restart service
systemctl restart openclaw-gateway.service

# View logs (real-time)
journalctl -u openclaw-gateway.service -f

# View recent logs
journalctl -u openclaw-gateway.service -n 100 --no-pager

# Search for errors
journalctl -u openclaw-gateway.service | grep -i error
```

### Configuration Management

```bash
# Edit OpenClaw config
nano /home/openclaw/.openclaw/openclaw.json

# Edit environment variables
nano /home/openclaw/openclaw/.env

# After editing, restart
systemctl restart openclaw-gateway.service
```

### Resource Monitoring

```bash
# CPU and memory usage
htop

# Disk usage
df -h

# Check process
ps aux | grep openclaw

# Network connections
ss -tulpn | grep 18789
```

### Backup Configuration

```bash
# Backup OpenClaw state
tar -czf ~/openclaw-backup-$(date +%Y%m%d).tar.gz /home/openclaw/.openclaw

# Download to local machine
scp root@YOUR_DROPLET_IP:~/openclaw-backup-*.tar.gz ~/Downloads/
```

### Updates

```bash
# SSH to droplet
ssh root@YOUR_DROPLET_IP

# Switch to openclaw user
su - openclaw
cd openclaw

# Pull latest changes
git pull origin main

# Install dependencies and rebuild
pnpm install
pnpm build

# Exit and restart
exit
systemctl restart openclaw-gateway.service
systemctl status openclaw-gateway.service
```

## Troubleshooting

### Service Won't Start

```bash
# Check logs
journalctl -u openclaw-gateway.service -n 50 --no-pager

# Common issues:
# 1. Wrong Node.js version
node --version  # Must be v22+

# 2. Missing gateway token
grep OPENCLAW_GATEWAY_TOKEN /home/openclaw/openclaw/.env

# 3. Config validation errors
su - openclaw -c "cd openclaw && node dist/index.js doctor"

# 4. Port already in use
lsof -i :18789
kill -9 PID
```

### Bot Not Responding

```bash
# 1. Check service is running
systemctl status openclaw-gateway.service

# 2. Check Telegram connection
journalctl -u openclaw-gateway.service | grep telegram | tail -20

# 3. Verify user ID in config
grep allowFrom /home/openclaw/.openclaw/openclaw.json

# 4. Check API keys are set
grep "TELEGRAM_BOT_TOKEN" /home/openclaw/openclaw/.env
```

### High Memory Usage

```bash
# Check memory
free -h

# Check OpenClaw process
ps aux | grep openclaw

# Restart if needed
systemctl restart openclaw-gateway.service
```

### Disk Space Issues

```bash
# Check usage
df -h

# Clean old logs (keep last 3 days)
journalctl --vacuum-time=3d

# Clean by size (keep last 500MB)
journalctl --vacuum-size=500M
```

### Network Connectivity

```bash
# Test local access
curl -I http://localhost:18789/

# Test from external IP
curl -I http://YOUR_DROPLET_IP:18789/

# Check Nginx logs
tail -f /var/log/nginx/error.log

# Verify firewall
ufw status numbered
```

## Security Hardening

### Enable Automatic Security Updates

```bash
apt-get install -y unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades
```

### Install fail2ban for SSH Protection

```bash
apt-get install -y fail2ban
systemctl enable fail2ban
systemctl start fail2ban
```

### SSH Hardening

Edit `/etc/ssh/sshd_config`:

```bash
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
X11Forwarding no
Protocol 2
```

Restart SSH:

```bash
systemctl restart sshd
```

### Firewall Best Practices

```bash
# Review current rules
ufw status numbered

# Only allow necessary ports
ufw default deny incoming
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 18789/tcp
```

### Secrets Management

- Never commit `.env` to git
- Rotate API keys quarterly
- Monitor API usage in dashboards
- Store backups securely

### Monitoring Checklist

- Check logs weekly for errors
- Review API quota usage
- Test backup restoration monthly
- Update system packages monthly
- Rotate API keys quarterly

## Optional: DNS & HTTPS

### Benefits of DNS

- Professional appearance (domain instead of IP)
- HTTPS/SSL certificates (Let's Encrypt)
- Easier to migrate droplets
- Better for webhooks

### Setup DNS

1. **Add domain in DigitalOcean dashboard**
   - Navigate to Networking → Domains
   - Click "Add Domain"
   - Enter your domain
   - Select your droplet

2. **Update domain registrar**
   - Point nameservers to:
     ```
     ns1.digitalocean.com
     ns2.digitalocean.com
     ns3.digitalocean.com
     ```

3. **Wait for propagation** (1-24 hours)
   ```bash
   nslookup yourdomain.com
   ```

4. **Get SSL certificate**
   ```bash
   certbot certonly --nginx -d yourdomain.com
   systemctl enable certbot.timer
   certbot renew --dry-run
   ```

5. **Update Nginx config**
   ```nginx
   server {
       listen 443 ssl http2;
       server_name yourdomain.com;

       ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
       ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;

       # ... rest of proxy config
   }
   ```

6. **Update OpenClaw config**
   ```json
   {
     "gateway": {
       "publicUrl": "https://yourdomain.com"
     }
   }
   ```

### Cost Summary

- Droplet: $28/month (4GB Intel)
- Domain: ~$10/year (~$1/month)
- SSL Certificate: FREE (Let's Encrypt)
- **Total: ~$29/month**

## Optional: Tailscale (Private SSH)

Install on the droplet:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up
tailscale status
```

SSH via Tailscale once connected:

```bash
ssh root@YOUR_TAILSCALE_IP
```

## Optional: Ollama

Install Ollama (system-wide under `/usr/local`):

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

## Quick Reference

```bash
# Service control
systemctl restart openclaw-gateway.service
systemctl status openclaw-gateway.service
journalctl -u openclaw-gateway.service -f

# Config files
nano /home/openclaw/.openclaw/openclaw.json
nano /home/openclaw/openclaw/.env

# Health check
curl -I http://localhost:18789/

# Resource monitoring
htop
df -h
free -h

# Backup
tar -czf ~/backup.tar.gz /home/openclaw/.openclaw
```

## Resources

- [OpenClaw Documentation](https://docs.openclaw.ai/start/openclaw)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [DigitalOcean Docs](https://docs.digitalocean.com)
- [Let's Encrypt](https://letsencrypt.org/)
