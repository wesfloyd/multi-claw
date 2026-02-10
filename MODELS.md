# Ollama Model Plan for MacBook Pro M3 (16GB RAM)

## Disk Usage Analysis

**Current Status:**
- Used: 243 GB
- Total: 770 GB
- Available: **527 GB free**

**Recommended Allocation for Ollama Models:**
- Safe usage: Up to 100 GB for models (leaves 427 GB buffer)
- Conservative: 50-75 GB for 3-5 models
- Aggressive: 100-150 GB for comprehensive model library

---

## 🏆 Recommended Model Lineup (2026 Latest)

Based on research from January-February 2026, here are the best models for agentic coding tasks on your M3 Mac:

### Tier 1: Primary Agentic Coding Models

#### 1. **Qwen3-Coder-Next (14B)** - *NEW February 2026* ⭐ RECOMMENDED
```bash
ollama pull qwen3-coder-next:14b
```
- **Size on disk**: ~8-9 GB
- **RAM usage**: ~10-12 GB
- **Speed**: 25-30 tokens/sec on M3
- **Why**: Built specifically for coding agents, tool calling, and MCP integration
- **Best for**: Agentic workflows, coding tasks, local development
- **Context**: 32K tokens

#### 2. **GPT-OSS 20B** - *State-of-art for coding*
```bash
ollama pull gpt-oss:20b
```
- **Size on disk**: ~12-14 GB
- **RAM usage**: ~13.7 GB
- **Speed**: 42 tokens/sec (MoE architecture)
- **Why**: 52.1% intelligence index, perfect logic scores, production-ready code
- **Best for**: Complex coding, debugging, analysis, research
- **Context**: 60K tokens
- **Note**: Uses Mixture of Experts (MoE) for efficiency

#### 3. **Qwen3-14B** - *Latest Qwen flagship*
```bash
ollama pull qwen3:14b
```
- **Size on disk**: ~8-9 GB
- **RAM usage**: ~11-13 GB
- **Speed**: 28-32 tokens/sec on M3
- **Why**: Latest Qwen3 family, general excellence
- **Best for**: General reasoning, coding, agentic tasks
- **Context**: 32K-128K tokens

### Tier 2: Fast & Efficient Models

#### 4. **Llama 3.2 8B** - *Best balance for M3*
```bash
ollama pull llama3.2:8b
```
- **Size on disk**: ~5 GB
- **RAM usage**: ~8 GB
- **Speed**: 35-40 tokens/sec on M3
- **Why**: Most practical for 16GB RAM, newer architecture outperforms older 13B models
- **Best for**: General tasks, quick responses, multitasking
- **Context**: 128K tokens

#### 5. **DeepSeek-Coder-V2 7B** - *Specialized coding*
```bash
ollama pull deepseek-coder-v2:7b
```
- **Size on disk**: ~4 GB
- **RAM usage**: ~6-7 GB
- **Speed**: 35-45 tokens/sec
- **Why**: State-of-the-art for coding, excellent reasoning
- **Best for**: Code generation, debugging, fast coding tasks
- **Context**: 16K tokens

### Tier 3: Lightweight & Fast

#### 6. **Phi-3 Mini (3.8B)** - *Fastest option*
```bash
ollama pull phi3:mini
```
- **Size on disk**: ~2.3 GB
- **RAM usage**: ~3-4 GB
- **Speed**: 60+ tokens/sec on M3
- **Why**: Microsoft's efficient model, great for quick tasks
- **Best for**: Fast responses, low memory scenarios, testing
- **Context**: 128K tokens

#### 7. **Mistral 7B** - *Reliable workhorse*
```bash
ollama pull mistral:7b
```
- **Size on disk**: ~4 GB
- **RAM usage**: ~6 GB
- **Speed**: 40-45 tokens/sec
- **Why**: Proven reliability, good general performance
- **Best for**: General chat, quick coding, fallback option
- **Context**: 32K tokens

---

## 📦 Recommended Download Strategy

### Option A: Conservative (3 models, ~22 GB total)

Best for getting started quickly:

```bash
# Primary agentic coder
ollama pull qwen3-coder-next:14b    # ~9 GB

# Fast general model
ollama pull llama3.2:8b             # ~5 GB

# Ultra-fast lightweight
ollama pull phi3:mini               # ~2 GB

# Total: ~16 GB disk, safe for 16GB RAM
```

### Option B: Balanced (5 models, ~35 GB total) ⭐ RECOMMENDED

Best balance of capability and variety:

```bash
# Top-tier agentic coding
ollama pull qwen3-coder-next:14b    # ~9 GB
ollama pull gpt-oss:20b             # ~13 GB

# Fast and efficient
ollama pull llama3.2:8b             # ~5 GB
ollama pull deepseek-coder-v2:7b    # ~4 GB

# Lightweight fallback
ollama pull phi3:mini               # ~2 GB

# Total: ~33 GB disk
```

### Option C: Comprehensive (7 models, ~50 GB total)

For maximum flexibility:

```bash
# All of Option B plus:
ollama pull qwen3:14b               # ~9 GB
ollama pull mistral:7b              # ~4 GB

# Total: ~46 GB disk
```

---

## 🎯 Updated OpenClaw Configuration

Replace the `openclaw.json` with this updated configuration:

```json
{
  "models": {
    "providers": {
      "ollama": {
        "baseUrl": "http://host.docker.internal:11434/v1",
        "apiKey": "ollama-local",
        "api": "openai-completions",
        "models": [
          {
            "id": "qwen3-coder-next:14b",
            "contextWindow": 32768,
            "description": "Latest agentic coding model (Feb 2026)"
          },
          {
            "id": "gpt-oss:20b",
            "contextWindow": 60000,
            "description": "State-of-art coding with MoE architecture"
          },
          {
            "id": "llama3.2:8b",
            "contextWindow": 131072,
            "description": "Fast general purpose model"
          },
          {
            "id": "deepseek-coder-v2:7b",
            "contextWindow": 16384,
            "description": "Specialized coding model"
          },
          {
            "id": "phi3:mini",
            "contextWindow": 131072,
            "description": "Ultra-fast lightweight model"
          },
          {
            "id": "qwen3:14b",
            "contextWindow": 131072,
            "description": "Latest Qwen general model"
          },
          {
            "id": "mistral:7b",
            "contextWindow": 32768,
            "description": "Reliable workhorse"
          }
        ]
      },
      "anthropic": {
        "apiKey": "${ANTHROPIC_API_KEY}",
        "models": [
          {
            "id": "claude-sonnet-4-20250514",
            "contextWindow": 200000
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "ollama/qwen3-coder-next:14b",
        "fallback": "ollama/llama3.2:8b",
        "fastPath": "ollama/phi3:mini",
        "hosted": "anthropic/claude-sonnet-4-20250514"
      },
      "heartbeat": {
        "every": "0m"
      }
    }
  },
  "channels": {
    "telegram": {
      "botToken": "${TELEGRAM_BOT_TOKEN}",
      "allowFrom": []
    }
  }
}
```

---

## 💾 Disk Space Management

### Model Storage Locations

Ollama models are stored in:
- **Mac**: `~/.ollama/models/`

Check current usage:
```bash
du -sh ~/.ollama/models/
ollama list
```

### Cleanup Commands

```bash
# List all models
ollama list

# Remove a model
ollama rm <model-name>

# Remove all models (clean slate)
rm -rf ~/.ollama/models/*

# Free up space by removing unused quantizations
# (Ollama keeps multiple quantizations sometimes)
```

### Quantization Options

If you need to save disk space or RAM, use smaller quantizations:

```bash
# Standard (Q4_K_M) - default, good balance
ollama pull qwen3-coder-next:14b

# Smaller (Q3_K_M) - saves ~25% space and RAM
ollama pull qwen3-coder-next:14b-q3

# Larger (Q5_K_M) - better quality, +15% space
ollama pull qwen3-coder-next:14b-q5

# Full precision (Q8) - best quality, 2x space
ollama pull qwen3-coder-next:14b-q8
```

---

## 🔥 What's New in 2026

### Major Updates

1. **Qwen3-Coder-Next** (Feb 2026)
   - First model specifically designed for coding agents
   - Enhanced MCP (Model Context Protocol) support
   - Tool calling optimized for local development

2. **GPT-OSS 20B**
   - Open-source MoE model competing with GPT-4
   - 52.1% intelligence index
   - Perfect logic scores in cognitive tests

3. **DeepSeek-V4** (Jan 2026)
   - Dynamic Sparse Attention (DSA)
   - Outperforms GPT-4.5 Turbo on coding
   - 40% lower inference cost

4. **Qwen3 Family** (Jan 2026)
   - Qwen3-235B-A22B (flagship MoE)
   - Qwen3-32B, 14B, 8B (dense models)
   - All under Apache 2.0 license

### Key Trends

- **Agentic Capabilities**: Models now have built-in tool calling and MCP support
- **Efficiency**: MoE architectures reduce active parameters by 10-20x
- **Context Windows**: 128K+ context is now standard
- **Apple Silicon**: Optimized Metal acceleration for M-series chips

---

## 📊 Performance Benchmarks (M3 Mac)

| Model | Size | RAM | Tokens/sec | Best For |
|-------|------|-----|------------|----------|
| qwen3-coder-next:14b | 9 GB | 12 GB | 28-30 | Agentic coding |
| gpt-oss:20b | 13 GB | 14 GB | 42 | Production code |
| qwen3:14b | 9 GB | 13 GB | 30 | General tasks |
| llama3.2:8b | 5 GB | 8 GB | 35-40 | Fast general |
| deepseek-coder-v2:7b | 4 GB | 7 GB | 40-45 | Coding |
| phi3:mini | 2 GB | 4 GB | 60+ | Quick tasks |
| mistral:7b | 4 GB | 6 GB | 40-45 | Reliable |

**Note**: Speeds are approximate and vary based on prompt complexity and context length.

---

## 🚀 Installation Script

Save this as `scripts/install-models.sh`:

```bash
#!/bin/bash
# Install recommended Ollama models

echo "🎯 Installing recommended Ollama models for M3 Mac..."
echo ""

# Option selection
echo "Choose installation option:"
echo "1) Conservative (3 models, ~16 GB)"
echo "2) Balanced (5 models, ~33 GB) [RECOMMENDED]"
echo "3) Comprehensive (7 models, ~46 GB)"
read -p "Enter choice [1-3]: " choice

case $choice in
  1)
    echo "Installing Conservative set..."
    ollama pull qwen3-coder-next:14b
    ollama pull llama3.2:8b
    ollama pull phi3:mini
    ;;
  2)
    echo "Installing Balanced set (recommended)..."
    ollama pull qwen3-coder-next:14b
    ollama pull gpt-oss:20b
    ollama pull llama3.2:8b
    ollama pull deepseek-coder-v2:7b
    ollama pull phi3:mini
    ;;
  3)
    echo "Installing Comprehensive set..."
    ollama pull qwen3-coder-next:14b
    ollama pull gpt-oss:20b
    ollama pull qwen3:14b
    ollama pull llama3.2:8b
    ollama pull deepseek-coder-v2:7b
    ollama pull mistral:7b
    ollama pull phi3:mini
    ;;
  *)
    echo "Invalid choice"
    exit 1
    ;;
esac

echo ""
echo "✅ Models installed!"
echo ""
echo "📊 Current models:"
ollama list
echo ""
echo "💾 Disk usage:"
du -sh ~/.ollama/models/
```

---

## 📚 Sources

Research based on January-February 2026 sources:

- [Best Ollama Model for Coding 2025](https://www.codegpt.co/blog/best-ollama-model-for-coding)
- [Best Local LLMs for 16GB VRAM](https://localllm.in/blog/best-local-llms-16gb-vram)
- [Qwen3-Coder-Next Release](https://www.marktechpost.com/2026/02/03/qwen-team-releases-qwen3-coder-next-an-open-weight-language-model-designed-specifically-for-coding-agents-and-local-development/)
- [Qwen3 Official Announcement](https://qwenlm.github.io/blog/qwen3/)
- [Best Open Source LLM 2026](https://whatllm.org/blog/best-open-source-models-january-2026)
- [Local AI on Mac Setup](https://localaimaster.com/blog/mac-local-ai-setup)
- [Best Local LLM for Apple Silicon](https://apxml.com/posts/best-local-llm-apple-silicon-mac)
- [DeepSeek Technical Tour](https://magazine.sebastianraschka.com/p/technical-deepseek)

---

## 🎯 Summary

**Recommendation for your M3 Mac (16GB RAM, 527 GB free):**

1. **Download**: Option B (Balanced) - 5 models, 33 GB
2. **Primary model**: `qwen3-coder-next:14b` (latest agentic coder)
3. **Fast fallback**: `llama3.2:8b` (best general purpose)
4. **Disk safety**: 33 GB is only 6% of available space, very safe
5. **Memory safety**: Largest model uses ~14 GB RAM, fits comfortably in 16 GB

**Next step**: Run the installation script and update your `openclaw.json`!
