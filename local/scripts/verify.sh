#!/bin/bash

# OpenClaw Deployment Verification Script

set -e

echo "🔍 OpenClaw Deployment Verification"
echo "===================================="
echo ""

ERRORS=0
WARNINGS=0

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

function check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

function check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS++))
}

function check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

# Check 1: .env file exists
echo "Checking environment configuration..."
if [ -f .env ]; then
    check_pass ".env file exists"

    # Check for required keys
    if grep -q "ANTHROPIC_API_KEY=" .env && ! grep -q "ANTHROPIC_API_KEY=sk-ant-your" .env; then
        check_pass "ANTHROPIC_API_KEY is set"
    else
        check_warn "ANTHROPIC_API_KEY not configured in .env"
    fi

    if grep -q "TELEGRAM_BOT_TOKEN=" .env && ! grep -q "TELEGRAM_BOT_TOKEN=your-telegram" .env; then
        check_pass "TELEGRAM_BOT_TOKEN is set"
    else
        check_warn "TELEGRAM_BOT_TOKEN not configured in .env"
    fi
else
    check_fail ".env file not found (copy from .env.example)"
fi
echo ""

# Check 2: Ollama installation
echo "Checking Ollama installation..."
if command -v ollama &> /dev/null; then
    check_pass "Ollama is installed"

    # Check if Ollama is running
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        check_pass "Ollama is running on port 11434"

        # Check for recommended models
        if ollama list | grep -q "qwen2.5-coder:14b"; then
            check_pass "qwen2.5-coder:14b model is installed"
        else
            check_warn "qwen2.5-coder:14b not installed (run: ollama pull qwen2.5-coder:14b)"
        fi

        if ollama list | grep -q "mistral:7b"; then
            check_pass "mistral:7b model is installed"
        else
            check_warn "mistral:7b not installed (run: ollama pull mistral:7b)"
        fi
    else
        check_warn "Ollama not running (run: ollama serve)"
    fi
else
    check_fail "Ollama not installed (install from https://ollama.com)"
fi
echo ""

# Check 3: Docker
echo "Checking Docker installation..."
if command -v docker &> /dev/null; then
    check_pass "Docker is installed"

    if docker compose version &> /dev/null; then
        check_pass "Docker Compose is available"
    else
        check_fail "Docker Compose not available"
    fi

    # Check if Docker daemon is running
    if docker info &> /dev/null; then
        check_pass "Docker daemon is running"
    else
        check_fail "Docker daemon not running"
    fi
else
    check_fail "Docker not installed"
fi
echo ""

# Check 4: Docker Compose file
echo "Checking Docker configuration..."
if [ -f docker-compose.yml ]; then
    check_pass "docker-compose.yml exists"

    # Check for host.docker.internal
    if grep -q "host.docker.internal" docker-compose.yml; then
        check_pass "docker-compose.yml configured for host Ollama access"
    else
        check_warn "docker-compose.yml may not be configured for host Ollama access"
    fi
else
    check_fail "docker-compose.yml not found"
fi
echo ""

# Check 5: OpenClaw configuration
echo "Checking OpenClaw configuration..."
if [ -f openclaw.json ]; then
    check_pass "openclaw.json exists"

    # Check if it's been copied to ~/.openclaw/
    if [ -f ~/.openclaw/openclaw.json ]; then
        check_pass "openclaw.json copied to ~/.openclaw/"
    else
        check_warn "openclaw.json not yet copied to ~/.openclaw/ (will happen on first start)"
    fi
else
    check_fail "openclaw.json not found"
fi
echo ""

# Check 6: Scripts
echo "Checking management scripts..."
if [ -x scripts/start.sh ]; then
    check_pass "start.sh is executable"
else
    check_warn "start.sh not executable (run: chmod +x scripts/start.sh)"
fi

if [ -x scripts/stop.sh ]; then
    check_pass "stop.sh is executable"
else
    check_warn "stop.sh not executable (run: chmod +x scripts/stop.sh)"
fi
echo ""

# Check 7: Docker container status (if running)
echo "Checking OpenClaw container status..."
if docker compose ps | grep -q "openclaw-gateway"; then
    if docker compose ps | grep -q "openclaw-gateway.*Up"; then
        check_pass "OpenClaw Gateway container is running"

        # Check if port is accessible
        if curl -s http://127.0.0.1:18789/ > /dev/null 2>&1; then
            check_pass "Control UI is accessible at http://127.0.0.1:18789/"
        else
            check_warn "Control UI not accessible (container may be starting)"
        fi
    else
        check_warn "OpenClaw Gateway container exists but is not running"
    fi
else
    check_warn "OpenClaw Gateway container not created (run: ./scripts/start.sh)"
fi
echo ""

# Check 8: Network connectivity from Docker to host
echo "Checking Docker to host connectivity..."
if docker info &> /dev/null; then
    # Only test if Docker is running
    if docker run --rm curlimages/curl:latest curl -s http://host.docker.internal:11434/api/tags > /dev/null 2>&1; then
        check_pass "Docker containers can reach host Ollama via host.docker.internal"
    else
        check_warn "Cannot verify Docker to host connectivity (Ollama may not be running)"
    fi
fi
echo ""

# Summary
echo "===================================="
echo "Verification Summary"
echo "===================================="
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}All checks passed!${NC} 🎉"
    echo "You're ready to start OpenClaw with: ./scripts/start.sh"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
    echo "System is functional but some optional components are missing."
    echo "Review warnings above and fix if needed."
    exit 0
else
    echo -e "${RED}Errors: $ERRORS${NC}"
    echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
    echo ""
    echo "Please fix the errors above before starting OpenClaw."
    exit 1
fi
