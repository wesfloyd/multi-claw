#!/bin/bash
# Install recommended Ollama models for M3 Mac (16GB RAM)
# Using models that ACTUALLY exist and fit

set -e

echo "🎯 Installing Ollama models for M3 Mac (16GB RAM)..."
echo ""

# Check Ollama
if ! command -v ollama &> /dev/null; then
    echo "❌ Ollama not found. Install: brew install ollama"
    exit 1
fi

if ! curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "⚠️  Starting Ollama..."
    ollama serve > /dev/null 2>&1 &
    sleep 3
fi

AVAILABLE_GB=$(df -g . | awk 'NR==2 {print $4}')
echo "💾 Available disk space: ${AVAILABLE_GB} GB"
echo ""

echo "📦 Currently installed models:"
ollama list || echo "  (none)"
echo ""

echo "Choose installation option:"
echo ""
echo "1) Minimal (2 models, ~14 GB) - Quick start"
echo "   - qwen2.5-coder:14b (9 GB) - Best coding model"
echo "   - llama3.2:8b (5 GB) - Fast general"
echo ""
echo "2) Balanced (4 models, ~24 GB) ⭐ RECOMMENDED"
echo "   - qwen2.5-coder:14b (9 GB) - Best coding"
echo "   - llama3.2:8b (5 GB) - Fast general"
echo "   - deepseek-coder-v2:16b-lite-instruct (6.4 GB) - Specialized"
echo "   - phi3:mini (2 GB) - Ultra-fast"
echo ""
echo "3) Comprehensive (6 models, ~33 GB)"
echo "   - All of Balanced set plus:"
echo "   - codellama:13b (7 GB) - Code completion"
echo "   - mistral:7b (4 GB) - General purpose"
echo ""
read -p "Enter choice [1-3]: " choice

install_model() {
    local model=$1
    echo ""
    echo "📥 Pulling $model..."
    if ollama pull "$model"; then
        echo "✅ $model installed"
    else
        echo "❌ Failed to install $model"
        return 1
    fi
}

case $choice in
  1)
    echo ""
    echo "Installing Minimal set..."
    install_model "qwen2.5-coder:14b"
    install_model "llama3.2:8b"
    ;;
  2)
    echo ""
    echo "Installing Balanced set (RECOMMENDED)..."
    install_model "qwen2.5-coder:14b"
    install_model "llama3.2:8b"
    install_model "deepseek-coder-v2:16b-lite-instruct"
    install_model "phi3:mini"
    ;;
  3)
    echo ""
    echo "Installing Comprehensive set..."
    install_model "qwen2.5-coder:14b"
    install_model "llama3.2:8b"
    install_model "deepseek-coder-v2:16b-lite-instruct"
    install_model "phi3:mini"
    install_model "codellama:13b"
    install_model "mistral:7b"
    ;;
  *)
    echo "Invalid choice"
    exit 1
    ;;
esac

echo ""
echo "============================================"
echo "✅ Installation complete!"
echo "============================================"
echo ""
echo "📊 Installed models:"
ollama list
echo ""
echo "💾 Disk usage:"
du -sh ~/.ollama/models/ 2>/dev/null || echo "  Unable to calculate"
echo ""
echo "🔥 Test a model:"
echo "  ollama run qwen2.5-coder:14b 'Write hello world in Python'"
echo ""
echo "📖 Start OpenClaw: ./scripts/start.sh"
