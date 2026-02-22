# Migration Plan — OpenClaw to New Instance

Migrate state, workspace, and credentials from the existing OpenClaw instance to the new
DigitalOcean droplet provisioned in `create-infra.md`.

**Prerequisites:** Complete all steps in `create-infra.md` before starting here.

---

## Overview

| Step | Where | Action |
|------|-------|--------|
| 0 | Old instance | Stop gateway, fix permissions, create archives |
| 1 | New instance | **Manual: Install OpenClaw** (you run this) |
| 2 | Local machine | SCP archives from old to new via Tailscale relay |
| 3 | New instance | Restore archives, fix permissions |
| 4 | New instance | Run `openclaw doctor`, start gateway, verify |
| 5 | New instance | Set missing credentials from old `.env` |
| 6 | Old instance | Disable gateway, power off droplet |

---

## Step 0 — Backup Old Instance

SSH into the **old** instance as root, stop the gateway via systemd:

```bash
ssh root@<old-tailscale-ip>
systemctl stop openclaw-gateway.service
systemctl is-active openclaw-gateway.service   # confirm: inactive
```

Fix ownership before archiving (root-owned backup files will cause tar errors):

```bash
chown -R openclaw:openclaw /home/openclaw/.openclaw
```

Switch to openclaw user and create archives (whole state dir — per docs requirement):

```bash
su - openclaw
cd ~

# Archive full state dir — only exclude large regeneratable media
tar -czf openclaw-migrate-state.tgz \
  --exclude='.openclaw/media/inbound/*' \
  --exclude='.openclaw/media/outbound/*' \
  .openclaw/

# Archive workspace — skip node_modules
tar -czf openclaw-migrate-workspace.tgz \
  --exclude='.openclaw/workspace/node_modules' \
  .openclaw/workspace/

ls -lh openclaw-migrate-state.tgz openclaw-migrate-workspace.tgz
```

---

## Step 1 — Install OpenClaw on New Instance

> **PAUSE — Manual action required.**
>
> Claude Code stops here. Run the OpenClaw install on the new instance yourself.

SSH into the **new** instance as the openclaw user:

```bash
ssh root@<new-tailscale-ip>
su - openclaw
```

Run the installer:

```bash
curl -fsSL https://openclaw.ai/install.sh | bash
```

**Known issue — PATH not set during install:** If Node.js was pre-installed system-wide
(as done in `create-infra.md`), the installer may print "Skipping onboarding" because
`openclaw` isn't on PATH mid-script. If this happens, install manually — the npm prefix
is already configured in `.npmrc`:

```bash
npm install -g openclaw
export PATH="$HOME/.npm-global/bin:$PATH"
openclaw
```

After install, confirm OpenClaw is working:

```bash
openclaw --version
openclaw status
```

Then stop the gateway before restore:

```bash
openclaw gateway stop
```

> **Resume here once install is confirmed complete and gateway is stopped.**

---

## Step 2 — Copy Archives to New Instance

From your **local machine**, relay the archives via Tailscale (avoids needing SSH keys
between the two remote instances):

```bash
scp -3 openclaw@<old-tailscale-ip>:~/openclaw-migrate-state.tgz openclaw@<new-tailscale-ip>:~/
scp -3 openclaw@<old-tailscale-ip>:~/openclaw-migrate-workspace.tgz openclaw@<new-tailscale-ip>:~/
```

Verify arrival on the new instance:

```bash
ssh openclaw@<new-tailscale-ip> "ls -lh ~/openclaw-migrate-*.tgz"
```

---

## Step 3 — Restore on New Instance

Extract archives over the freshly-installed state dir:

```bash
ssh openclaw@<new-tailscale-ip>
cd ~
tar -xzf openclaw-migrate-state.tgz
tar -xzf openclaw-migrate-workspace.tgz
```

Fix ownership as root (critical — gateway won't start if permissions are wrong):

```bash
ssh root@<new-tailscale-ip>
chown -R openclaw:openclaw /home/openclaw/.openclaw
```

---

## Step 4 — Run Doctor and Start Gateway

```bash
ssh openclaw@<new-tailscale-ip>
openclaw doctor --yes
```

Enable systemd linger so the user service survives logout (run as root):

```bash
ssh root@<new-tailscale-ip>
loginctl enable-linger openclaw
```

Apply doctor fixes and start the gateway:

```bash
ssh openclaw@<new-tailscale-ip>
openclaw doctor --fix
openclaw gateway start
```

Verify:

```bash
openclaw status
curl -s http://localhost:18789/health
```

---

## Step 5 — Set Missing Credentials from Old `.env`

The state archive migrates all credentials stored in `openclaw.json`. However, some keys
were only in the old instance's app `.env` file and need to be set manually.

First, copy the old `.env` to your local machine:

```bash
# On your local machine
scp -3 root@<old-tailscale-ip>:/home/openclaw/openclaw/.env ./openclaw-old.env
```

> **Important:** Add `openclaw-old.env` to `.gitignore` immediately — it contains secrets.

Then set each missing value on the new instance:

```bash
# Telegram bot token (was only in .env, not in openclaw.json)
openclaw config set channels.telegram.botToken "YOUR_TOKEN"

# Provider API keys not in openclaw.json
openclaw config set env.vars.ANTHROPIC_API_KEY "YOUR_KEY"
openclaw config set env.vars.OPENROUTER_API_KEY "YOUR_KEY"

# Other env-only values
openclaw config set env.vars.PROTON_EMAIL "YOUR_EMAIL"
openclaw config set env.vars.PROTON_PASSWORD "YOUR_PASSWORD"
```

Keys already migrated via `openclaw.json` (no action needed):
- NVIDIA_API_KEY, XAI_API_KEY, Twilio credentials, AgentMail credentials, GitHub credentials

Restart the gateway to pick up the new values:

```bash
openclaw gateway restart
openclaw status   # Telegram should show: ON / OK
```

---

## Step 6 — Cut Over and Power Off Old Instance

Disable the gateway on the old instance:

```bash
ssh root@<old-tailscale-ip>
systemctl stop openclaw-gateway.service
systemctl disable openclaw-gateway.service
```

Power off the old droplet via doctl:

```bash
doctl compute droplet-action power-off <old-droplet-id> --wait
```

Once the new instance is fully validated, destroy the old droplet to stop billing:

```bash
doctl compute droplet delete <old-droplet-id>
```

---

## Step 7 — Set Up OpenAI Codex Subscription (Post-Migration)

After migration is stable, set up OpenAI Codex via subscription as primary model:

```bash
ssh openclaw@<new-tailscale-ip>
openclaw models auth login --provider openai-codex
# Follow the OAuth flow — sign in with your ChatGPT account
```

Set as primary model:

```bash
openclaw config set agents.defaults.model.primary "openai-codex/gpt-5.3-codex"
openclaw gateway restart
openclaw status   # confirm: default gpt-5.3-codex
```

---

## Rollback

The old instance remains powered off (not destroyed) until validation is complete.
To roll back:

1. Power on old droplet: `doctl compute droplet-action power-on <old-droplet-id> --wait`
2. Re-enable gateway: `ssh root@<old-tailscale-ip> "systemctl enable --now openclaw-gateway.service"`
3. Stop gateway on new instance: `openclaw gateway stop`

---

## Checklist

- [ ] Old gateway stopped before archiving
- [ ] Permissions fixed before archiving (`chown -R openclaw:openclaw ~/.openclaw`)
- [ ] Full `~/.openclaw/` archived (not partial)
- [ ] OpenClaw manually installed on new instance
- [ ] Archives transferred via `scp -3` local relay
- [ ] Archives extracted, permissions fixed
- [ ] `openclaw doctor` run, linger enabled
- [ ] Gateway running and healthy (`/health` responds)
- [ ] Missing `.env` credentials set on new instance
- [ ] Telegram: ON / OK in `openclaw status`
- [ ] Test message sent via Telegram successfully
- [ ] OpenAI Codex subscription authenticated
- [ ] Primary model set to `openai-codex/gpt-5.3-codex`
- [ ] Old droplet powered off
- [ ] Old droplet destroyed (after validation period)
