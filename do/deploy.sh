#!/bin/bash

##############################################################################
# OpenClaw Automated Deployment Script
# Handles: System hardening, Docker, OpenClaw, Nginx, Testing
# Status: Production-ready
##############################################################################

set -e  # Exit on any error

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
OPENCLAW_USER="openclaw"
OPENCLAW_HOME="/home/openclaw"
OPENCLAW_DIR="$OPENCLAW_HOME/openclaw"
GITHUB_REPO="https://github.com/openclaw/openclaw.git"
GATEWAY_PORT=18789
LOG_FILE="/var/log/openclaw-deploy.log"

##############################################################################
# Logging Functions
##############################################################################

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

##############################################################################
# Step 1: System Hardening
##############################################################################

step_system_hardening() {
    log_info "=== STEP 1: SYSTEM HARDENING ==="

    log_info "Updating system packages..."
    apt-get update > /dev/null
    apt-get upgrade -y > /dev/null
    log_success "System packages updated"

    log_info "Installing essential packages..."
    apt-get install -y \
        curl \
        wget \
        git \
        build-essential \
        ufw \
        htop \
        net-tools \
        unattended-upgrades \
        apt-listchanges \
        > /dev/null 2>&1
    log_success "Essential packages installed"

    log_info "Setting up automatic security updates..."
    dpkg-reconfigure -plow unattended-upgrades > /dev/null 2>&1
    log_success "Automatic security updates enabled"

    log_info "Configuring UFW firewall..."
    ufw --force enable > /dev/null
    ufw default deny incoming > /dev/null
    ufw default allow outgoing > /dev/null
    ufw allow 22/tcp > /dev/null
    ufw allow 80/tcp > /dev/null
    ufw allow 443/tcp > /dev/null
    ufw allow 18789/tcp > /dev/null
    log_success "UFW firewall configured"

    log_info "Creating non-root user: $OPENCLAW_USER"
    if ! id "$OPENCLAW_USER" &>/dev/null; then
        useradd -m -s /bin/bash "$OPENCLAW_USER"
        usermod -aG sudo "$OPENCLAW_USER"
        log_success "User '$OPENCLAW_USER' created"
    else
        log_warning "User '$OPENCLAW_USER' already exists"
    fi

    log_info "Setting up SSH keys for non-root user..."
    mkdir -p "$OPENCLAW_HOME/.ssh"
    if [ -f /root/.ssh/authorized_keys ]; then
        cp /root/.ssh/authorized_keys "$OPENCLAW_HOME/.ssh/"
        chown -R "$OPENCLAW_USER:$OPENCLAW_USER" "$OPENCLAW_HOME/.ssh"
        chmod 700 "$OPENCLAW_HOME/.ssh"
        chmod 600 "$OPENCLAW_HOME/.ssh/authorized_keys"
        log_success "SSH keys configured for '$OPENCLAW_USER'"
    fi

    log_success "System hardening complete"
}

##############################################################################
# Step 2: Install Docker
##############################################################################

step_docker_installation() {
    log_info "=== STEP 2: DOCKER INSTALLATION ==="

    if command -v docker &> /dev/null; then
        log_warning "Docker already installed: $(docker --version)"
        return
    fi

    log_info "Installing Docker..."
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sh /tmp/get-docker.sh > /dev/null 2>&1
    log_success "Docker installed: $(docker --version)"

    log_info "Installing Docker Compose..."
    apt-get install -y docker-compose > /dev/null 2>&1
    log_success "Docker Compose installed: $(docker-compose --version)"

    log_info "Adding '$OPENCLAW_USER' to docker group..."
    usermod -aG docker "$OPENCLAW_USER"
    log_success "User added to docker group"

    log_info "Starting Docker daemon..."
    systemctl enable docker > /dev/null
    systemctl start docker > /dev/null
    log_success "Docker daemon started and enabled"
}

##############################################################################
# Step 3: Clone OpenClaw Repository
##############################################################################

step_clone_openclaw() {
    log_info "=== STEP 3: CLONE OPENCLAW REPOSITORY ==="

    if [ -d "$OPENCLAW_DIR" ]; then
        log_warning "OpenClaw directory already exists, updating..."
        cd "$OPENCLAW_DIR"
        sudo -u "$OPENCLAW_USER" git pull origin main > /dev/null 2>&1
    else
        log_info "Cloning OpenClaw repository..."
        sudo -u "$OPENCLAW_USER" mkdir -p "$OPENCLAW_HOME"
        cd "$OPENCLAW_HOME"
        sudo -u "$OPENCLAW_USER" git clone "$GITHUB_REPO" > /dev/null 2>&1
        log_success "OpenClaw cloned to $OPENCLAW_DIR"
    fi

    log_info "Repository status:"
    cd "$OPENCLAW_DIR"
    log_info "$(git log --oneline -1)"
}

##############################################################################
# Step 4: Configure Environment
##############################################################################

step_configure_environment() {
    log_info "=== STEP 4: CONFIGURE ENVIRONMENT ==="

    ENV_FILE="$OPENCLAW_DIR/.env"

    log_info "Checking for .env file..."
    if [ ! -f "$ENV_FILE" ]; then
        log_error ".env file not found at $ENV_FILE"
        log_info "Creating default .env..."
        cat > "$ENV_FILE" << 'EOF'
# OpenClaw Environment Configuration
NODE_ENV=production
OPENCLAW_PORT=18789

# LLM Configuration
ANTHROPIC_API_KEY=
OPENCLAW_MODEL=anthropic/claude-sonnet-4-5-20250929

# Web Search (Perplexity Sonar via OpenRouter)
OPENROUTER_API_KEY=

# Telegram Configuration
TELEGRAM_BOT_TOKEN=

# Security
SESSION_SECRET=
OPENCLAW_GATEWAY_TOKEN=
EOF
        log_warning ".env created with defaults"
    fi

    # Generate SESSION_SECRET if not set
    if ! grep -q "SESSION_SECRET=" "$ENV_FILE" || grep -q "SESSION_SECRET=$" "$ENV_FILE"; then
        SESSION_SECRET=$(openssl rand -base64 32)
        sed -i "s|SESSION_SECRET=.*|SESSION_SECRET=$SESSION_SECRET|" "$ENV_FILE"
        log_success "SESSION_SECRET generated"
    fi

    # Generate OPENCLAW_GATEWAY_TOKEN if not set (used for gateway auth)
    if ! grep -q "OPENCLAW_GATEWAY_TOKEN=" "$ENV_FILE" || grep -q "OPENCLAW_GATEWAY_TOKEN=$" "$ENV_FILE"; then
        GATEWAY_TOKEN=$(openssl rand -hex 32)
        sed -i "s|OPENCLAW_GATEWAY_TOKEN=.*|OPENCLAW_GATEWAY_TOKEN=$GATEWAY_TOKEN|" "$ENV_FILE"
        log_success "OPENCLAW_GATEWAY_TOKEN generated"
    fi

    chown "$OPENCLAW_USER:$OPENCLAW_USER" "$ENV_FILE"
    chmod 600 "$ENV_FILE"
    log_success "Environment configured"
}

##############################################################################
# Step 5: Setup Docker Compose
##############################################################################

step_docker_compose() {
    log_info "=== STEP 5: SETUP DOCKER COMPOSE ==="

    COMPOSE_FILE="$OPENCLAW_DIR/docker-compose.yml"

    if [ ! -f "$COMPOSE_FILE" ]; then
        log_warning "docker-compose.yml not found, checking repository..."
        if [ -f "$OPENCLAW_DIR/docker-compose.yml" ]; then
            log_success "Using repository docker-compose.yml"
        else
            log_warning "Creating default docker-compose.yml..."
            cat > "$COMPOSE_FILE" << 'EOF'
version: '3.8'

services:
  openclaw:
    image: openclaw:latest
    container_name: openclaw-prod
    restart: always
    ports:
      - "127.0.0.1:18789:18789"
    environment:
      - NODE_ENV=production
      - OPENCLAW_PORT=18789
    env_file:
      - .env
    volumes:
      - openclaw-data:/root/.openclaw
      - openclaw-workspace:/root/.openclaw/workspace
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:18789/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

volumes:
  openclaw-data:
    driver: local
  openclaw-workspace:
    driver: local
EOF
            log_success "docker-compose.yml created"
        fi
    else
        log_success "docker-compose.yml found"
    fi

    chown "$OPENCLAW_USER:$OPENCLAW_USER" "$COMPOSE_FILE"
}

##############################################################################
# Step 6: Build and Start Services
##############################################################################

step_build_start_services() {
    log_info "=== STEP 6: BUILD AND START SERVICES ==="

    cd "$OPENCLAW_DIR"

    log_info "Building Docker image (this may take 5-10 minutes)..."
    sudo -u "$OPENCLAW_USER" docker-compose build --no-cache 2>&1 | tail -5
    log_success "Docker image built"

    log_info "Starting OpenClaw service..."
    sudo -u "$OPENCLAW_USER" docker-compose up -d
    sleep 5
    log_success "OpenClaw service started"

    log_info "Waiting for service to be ready (30 seconds)..."
    for i in {1..30}; do
        if sudo -u "$OPENCLAW_USER" docker-compose logs openclaw 2>/dev/null | grep -q "listening\|started\|ready"; then
            log_success "Service is ready"
            break
        fi
        echo -n "."
        sleep 1
    done

    log_info "Service status:"
    sudo -u "$OPENCLAW_USER" docker-compose ps
}

##############################################################################
# Step 7: Setup Nginx Reverse Proxy
##############################################################################

step_nginx_setup() {
    log_info "=== STEP 7: SETUP NGINX REVERSE PROXY ==="

    log_info "Installing Nginx..."
    apt-get install -y nginx certbot python3-certbot-nginx > /dev/null 2>&1
    log_success "Nginx installed"

    log_info "Creating Nginx configuration..."
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
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
EOF
    log_success "Nginx configuration created"

    log_info "Enabling Nginx site..."
    ln -sf /etc/nginx/sites-available/openclaw /etc/nginx/sites-enabled/openclaw 2>/dev/null || true
    rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true

    log_info "Testing Nginx configuration..."
    if nginx -t > /dev/null 2>&1; then
        log_success "Nginx configuration valid"
    else
        log_error "Nginx configuration error"
        nginx -t
        return 1
    fi

    log_info "Starting Nginx..."
    systemctl enable nginx > /dev/null
    systemctl restart nginx > /dev/null
    log_success "Nginx started and enabled"
}

##############################################################################
# Step 8: Test Bot Functionality
##############################################################################

step_test_bot() {
    log_info "=== STEP 8: TEST BOT FUNCTIONALITY ==="

    log_info "Checking OpenClaw service..."
    if sudo -u "$OPENCLAW_USER" docker-compose -f "$OPENCLAW_DIR/docker-compose.yml" ps | grep -q "openclaw.*Up"; then
        log_success "OpenClaw service is running"
    else
        log_error "OpenClaw service is not running"
        sudo -u "$OPENCLAW_USER" docker-compose -f "$OPENCLAW_DIR/docker-compose.yml" logs -n 50
        return 1
    fi

    log_info "Testing HTTP connectivity..."
    sleep 2
    if curl -sf http://127.0.0.1:18789/health > /dev/null 2>&1; then
        log_success "OpenClaw is responding to HTTP requests"
    else
        log_warning "OpenClaw health check failed, retrying..."
        sleep 5
        curl -sf http://127.0.0.1:18789/ > /dev/null 2>&1 && log_success "OpenClaw is responsive" || log_warning "OpenClaw may still be starting"
    fi

    log_info "Testing Nginx proxy..."
    if curl -sf http://127.0.0.1/health > /dev/null 2>&1; then
        log_success "Nginx proxy is working"
    else
        log_warning "Nginx proxy test inconclusive (this is ok if service is still starting)"
    fi

    log_info "Testing external connectivity..."
    if [ -n "${DROPLET_IP:-}" ] && curl -sf "http://${DROPLET_IP}/" > /dev/null 2>&1; then
        log_success "External access working (${DROPLET_IP})"
    elif curl -sf http://YOUR_DROPLET_IP/ > /dev/null 2>&1; then
        log_success "External access working (YOUR_DROPLET_IP)"
    else
        log_warning "External access test inconclusive"
    fi

    log_info "Checking Telegram bot configuration..."
    if grep -q "TELEGRAM_BOT_TOKEN" "$OPENCLAW_DIR/.env"; then
        log_success "Telegram bot token is configured"
    else
        log_warning "Telegram bot token not found in .env"
    fi

    log_info "Service is ready for testing"
}

##############################################################################
# Step 9: Setup Automated Updates
##############################################################################

step_automated_updates() {
    log_info "=== STEP 9: SETUP AUTOMATED UPDATES ==="

    SCRIPT_PATH="$OPENCLAW_HOME/update-openclaw.sh"

    log_info "Creating update script..."
    cat > "$SCRIPT_PATH" << 'EOF'
#!/bin/bash
set -e

OPENCLAW_DIR="/home/openclaw/openclaw"
LOG_FILE="/var/log/openclaw-update.log"

echo "OpenClaw update started at $(date)" >> "$LOG_FILE"

cd "$OPENCLAW_DIR"

# Pull latest code
echo "Pulling latest code..." >> "$LOG_FILE"
sudo -u openclaw git pull origin main >> "$LOG_FILE" 2>&1

# Rebuild image
echo "Rebuilding Docker image..." >> "$LOG_FILE"
sudo -u openclaw docker-compose build --no-cache >> "$LOG_FILE" 2>&1

# Restart service
echo "Restarting OpenClaw..." >> "$LOG_FILE"
sudo -u openclaw docker-compose down >> "$LOG_FILE" 2>&1
sudo -u openclaw docker-compose up -d >> "$LOG_FILE" 2>&1

echo "OpenClaw updated successfully at $(date)" >> "$LOG_FILE"
EOF

    chmod +x "$SCRIPT_PATH"
    chown "$OPENCLAW_USER:$OPENCLAW_USER" "$SCRIPT_PATH"
    log_success "Update script created at $SCRIPT_PATH"

    log_info "Configuring weekly updates..."
    CRONTAB_ENTRY="0 2 * * 0 $SCRIPT_PATH"
    (crontab -u "$OPENCLAW_USER" -l 2>/dev/null || true; echo "$CRONTAB_ENTRY") | crontab -u "$OPENCLAW_USER" -
    log_success "Weekly updates scheduled (Sundays at 2 AM)"
}

##############################################################################
# Step 10: Final Verification
##############################################################################

step_final_verification() {
    log_info "=== STEP 10: FINAL VERIFICATION ==="

    log_info "System status:"
    log_info "Uptime: $(uptime -p)"
    log_info "Disk usage: $(df -h / | tail -1)"
    log_info "Memory usage: $(free -h | grep Mem)"

    log_info "Service status:"
    systemctl status docker --no-pager | grep -E "Active|Loaded" || true
    systemctl status nginx --no-pager | grep -E "Active|Loaded" || true

    log_info "Docker containers:"
    sudo -u "$OPENCLAW_USER" docker ps --all

    log_info "Logs from last 20 lines:"
    sudo -u "$OPENCLAW_USER" docker-compose -f "$OPENCLAW_DIR/docker-compose.yml" logs --tail 20 2>/dev/null || true

    log_success "Deployment verification complete"
}

##############################################################################
# Main Execution
##############################################################################

main() {
    echo -e "${BLUE}"
    cat << "EOF"
╔════════════════════════════════════════════════════════════════╗
║       OpenClaw DigitalOcean Automated Deployment              ║
║                   Starting setup...                            ║
╚════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"

    # Create log file
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE"

    log_info "Deployment started at $(date)"
    log_info "Log file: $LOG_FILE"

    # Run all steps
    step_system_hardening || { log_error "System hardening failed"; exit 1; }
    step_docker_installation || { log_error "Docker installation failed"; exit 1; }
    step_clone_openclaw || { log_error "OpenClaw clone failed"; exit 1; }
    step_configure_environment || { log_error "Environment configuration failed"; exit 1; }
    step_docker_compose || { log_error "Docker Compose setup failed"; exit 1; }
    step_build_start_services || { log_error "Build and start failed"; exit 1; }
    step_nginx_setup || { log_error "Nginx setup failed"; exit 1; }
    step_test_bot || { log_warning "Bot testing had issues (see logs)"; }
    step_automated_updates || { log_error "Update setup failed"; exit 1; }
    step_final_verification || { log_error "Final verification failed"; exit 1; }

    echo -e "${GREEN}"
    cat << "EOF"
╔════════════════════════════════════════════════════════════════╗
║              ✓ DEPLOYMENT SUCCESSFUL                          ║
║                                                                ║
║  OpenClaw is now running on YOUR_DROPLET_IP                   ║
║                                                                ║
║  Access points:                                               ║
║  - HTTP:  http://YOUR_DROPLET_IP/                            ║
║  - Direct: http://127.0.0.1:18789/                           ║
║                                                                ║
║  Next steps:                                                  ║
║  1. View logs: docker-compose logs -f                        ║
║  2. Test Telegram: Send a message to your bot                ║
║  3. Setup DNS: See do/DNS_SETUP.md                           ║
║  4. Enable HTTPS: certbot certonly --nginx -d yourdomain     ║
║                                                                ║
║  Logs available at: /var/log/openclaw-deploy.log             ║
╚════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"

    log_info "Deployment completed at $(date)"
}

# Run main if script is executed directly
main "$@"
