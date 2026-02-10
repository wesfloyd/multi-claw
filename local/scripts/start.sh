#!/bin/bash
set -e

# OpenClaw Startup Script for Mac with Docker + native Ollama

echo "🚀 Starting OpenClaw local deployment..."

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ .env file not found!"
    echo "Please copy .env.example to .env and configure your API keys:"
    echo "  cp .env.example .env"
    echo "  # Then edit .env with your actual keys"
    exit 1
fi

# Source environment variables
source .env

# Check if Ollama is running
echo "🔍 Checking Ollama status..."
if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "⚠️  Ollama is not running on localhost:11434"
    echo "Starting Ollama..."

    # Try to start Ollama (Mac)
    if command -v ollama &> /dev/null; then
        ollama serve > /dev/null 2>&1 &
        sleep 3
        echo "✅ Ollama started"
    else
        echo "❌ Ollama not found. Please install from https://ollama.com"
        exit 1
    fi
else
    echo "✅ Ollama is running"
fi

# List available models
echo ""
echo "📦 Available Ollama models:"
ollama list

# Check if recommended models are installed
if ! ollama list | grep -q "qwen2.5-coder:14b"; then
    echo ""
    echo "⚠️  Recommended model qwen2.5-coder:14b not found"
    echo "Pull it with: ollama pull qwen2.5-coder:14b"
fi

if ! ollama list | grep -q "mistral:7b"; then
    echo "⚠️  Recommended model mistral:7b not found"
    echo "Pull it with: ollama pull mistral:7b"
fi

# Create ~/.openclaw directory if it doesn't exist
mkdir -p ~/.openclaw

# Copy openclaw.json to ~/.openclaw/ if not exists
if [ ! -f ~/.openclaw/openclaw.json ]; then
    echo ""
    echo "📝 Copying openclaw.json to ~/.openclaw/"
    cp openclaw.json ~/.openclaw/openclaw.json
fi

# Start Docker Compose
echo ""
echo "🐳 Starting OpenClaw Gateway in Docker..."
docker compose up -d

# Wait for service to be ready
echo ""
echo "⏳ Waiting for OpenClaw Gateway to start..."
sleep 5

# Check if service is running
if docker compose ps | grep -q "openclaw-gateway.*Up"; then
    echo "✅ OpenClaw Gateway is running"
    echo ""
    echo "🎉 OpenClaw is ready!"
    echo ""
    echo "📊 Control UI: http://127.0.0.1:${OPENCLAW_GATEWAY_PORT:-18789}/"
    echo "💬 Send a message to your Telegram bot to test"
    echo ""
    echo "📋 View logs: docker compose logs -f openclaw-gateway"
    echo "🛑 Stop: ./scripts/stop.sh"
else
    echo "❌ OpenClaw Gateway failed to start"
    echo "Check logs: docker compose logs openclaw-gateway"
    exit 1
fi
