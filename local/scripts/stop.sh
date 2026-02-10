#!/bin/bash
set -e

# OpenClaw Teardown Script

echo "🛑 Stopping OpenClaw..."

# Stop Docker Compose
docker compose down

echo "✅ OpenClaw Gateway stopped"
echo ""
echo "ℹ️  Note: Ollama is still running in the background"
echo "   To stop Ollama: pkill ollama"
echo ""
echo "💾 Your data is preserved in ~/.openclaw/"
