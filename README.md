# Multi-Claw: OpenClaw Multi-Environment Deployment

Production deployment of OpenClaw on DigitalOcean.

## Documentation

- **[do/](./do/)** - DigitalOcean production deployment

## DigitalOcean Deployment (Active)

**Live Instance: `openclaw-prod`**
- **IP:** `YOUR_DROPLET_IP` (kept in local `.env` as `DROPLET_IP`)
- **Size:** 4GB RAM, 2 vCPU, 80GB NVMe SSD
- **Cost:** $28/month
- **Status:** Active

**Documentation:** See [do/DIGITALOCEAN_SETUP.md](./do/DIGITALOCEAN_SETUP.md)

Quick start after SSH:
```bash
ssh root@YOUR_DROPLET_IP
# Follow steps in do/DIGITALOCEAN_SETUP.md (Steps 2-10)
```

**Key Guides:**
- [SETUP.md](./do/SETUP.md) - Complete installation and operations guide
- [README.md](./do/README.md) - Quick reference and common commands

## Resources

- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [Anthropic API Docs](https://docs.anthropic.com/)
- [Telegram Bot API](https://core.telegram.org/bots/api)
