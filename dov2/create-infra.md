# Create Infrastructure — DigitalOcean v2

Provision a new DigitalOcean droplet matching the production specs and prepare it for OpenClaw.

---

## Droplet Specs

Match the existing production instance exactly:

| Parameter | Value |
|-----------|-------|
| Region | ATL1 (Atlanta) |
| Image | Ubuntu 24.04 LTS x64 |
| Size | 2 vCPU, 4GB RAM (Intel regular) |
| Hostname | `openclaw-prod-v2` (or similar) |
| Authentication | SSH key (same key as existing droplet) |

---

## Step 1 — Create Droplet

Via the DigitalOcean control panel or CLI (`doctl`):

```bash
# Using doctl (DigitalOcean CLI)
doctl compute droplet create openclaw-prod-v2 \
  --region atl1 \
  --image ubuntu-24-04-x64 \
  --size s-2vcpu-4gb-intel \
  --ssh-keys <your-ssh-key-fingerprint> \
  --wait
```

Or create manually via the web UI with the same specs.

Note the new droplet's IP address — you'll need it in subsequent steps.

---

## Step 2 — Initial SSH Access

```bash
ssh root@<new-droplet-ip>
```

Verify you're on the right machine:

```bash
hostnamectl
lsb_release -a
```

---

## Step 3 — System Updates

Run full apt upgrades before installing anything:

```bash
apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y
apt-get autoremove -y
apt-get autoclean
```

Reboot if a kernel upgrade was installed:

```bash
# Check if reboot needed
ls /var/run/reboot-required 2>/dev/null && echo "REBOOT REQUIRED" || echo "No reboot needed"

# Reboot if needed, then reconnect
reboot
```

---

## Step 4 — Install Essential Packages

```bash
apt-get install -y \
  curl \
  wget \
  git \
  build-essential \
  ufw \
  htop \
  net-tools \
  unattended-upgrades \
  apt-listchanges
```

Enable automatic security updates:

```bash
dpkg-reconfigure -plow unattended-upgrades
```

---

## Step 5 — Configure Firewall

```bash
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 18789/tcp
ufw status verbose
```

---

## Step 6 — Install Tailscale

```bash
curl -fsSL https://tailscale.com/install.sh | sh

# Authenticate (opens a URL — paste into browser)
tailscale up

# Verify and note the Tailscale IP
tailscale ip -4
tailscale status
```

After connecting, confirm SSH via Tailscale works from your local machine:

```bash
# From your local machine
ssh root@<new-tailscale-ip>
```

---

## Step 7 — Install Claude Code

Install Node.js (required for Claude Code CLI):

```bash
# Install Node.js via NodeSource
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs
node --version
npm --version
```

Install Claude Code globally:

```bash
npm install -g @anthropic-ai/claude-code
claude --version
```

Authenticate Claude Code (requires Anthropic API key or subscription):

```bash
# Run as the user who will use it (root or openclaw)
claude
# Follow the auth flow in the terminal
```

---

## Step 8 — Create openclaw User

```bash
# Create user
useradd -m -s /bin/bash openclaw
usermod -aG sudo openclaw

# Copy SSH keys from root
mkdir -p /home/openclaw/.ssh
cp /root/.ssh/authorized_keys /home/openclaw/.ssh/
chown -R openclaw:openclaw /home/openclaw/.ssh
chmod 700 /home/openclaw/.ssh
chmod 600 /home/openclaw/.ssh/authorized_keys
```

**Important:** Pre-configure the npm global prefix for the openclaw user. Because Node.js is
installed system-wide (as root), the OpenClaw installer will detect it but may fail to place
the binary correctly without this prefix set in advance.

Also add the PATH to both `.bashrc` (interactive shells) and `.profile` (login shells and
non-interactive SSH commands) — both are required.

```bash
# Run as root — sets up npm prefix and PATH for openclaw user
sudo -u openclaw bash -c '
  mkdir -p /home/openclaw/.npm-global
  npm config set prefix "/home/openclaw/.npm-global"
  echo "export PATH=\"\$HOME/.npm-global/bin:\$PATH\"" >> /home/openclaw/.bashrc
  echo "export PATH=\"\$HOME/.npm-global/bin:\$PATH\"" >> /home/openclaw/.profile
'
```

---

## Step 9 — Verify Infrastructure

Run these checks before proceeding to migration:

```bash
# OS and hardware
lsb_release -a
nproc && free -h && df -h /

# Network
curl -s https://ifconfig.me   # public IP
tailscale ip -4               # tailscale IP

# Services
ufw status
systemctl status tailscaled

# Installed tools
node --version
npm --version
claude --version
```

All checks passing? Proceed to `migration-plan.md`.
