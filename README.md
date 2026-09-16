# Clash AI Whitelist

A one-click Linux configuration for Clash Verge Rev:

**Proxy only AI / algorithm-engineering services; keep everything else DIRECT.**

Included services:
- OpenAI / ChatGPT / Codex
- GitHub / Copilot / GHCR
- Hugging Face / Xet / LFS
- Claude / Anthropic
- Gemini / Google AI Studio / Colab
- Grok / xAI
- OpenRouter, Together, Groq, Mistral, Replicate, Perplexity, Cohere
- Cursor, Windsurf, Codeium, Sourcegraph
- VS Code Marketplace
- Docker, NVIDIA NGC
- PyPI, npm, crates.io, Conda
- W&B, GitLab
- RunPod, Modal, Vast.ai, Lambda
- arXiv, OpenReview, Papers with Code, Semantic Scholar, Kaggle
- PyTorch / TensorFlow sites

## Quick start

```bash
chmod +x scripts/*.sh
./scripts/install.sh --proxy-group "🔰 选择节点"
./scripts/status.sh
```

The installer:
1. Detects the Clash Verge Rev data directory.
2. Stops the GUI briefly to avoid config overwrite.
3. Backs up existing config.
4. Installs a **Global Extend Script**.
5. Enables Rule mode.
6. Enables TUN and System Proxy by default.
7. Restarts Clash Verge Rev when possible.

All domains not on the whitelist end at:

```text
MATCH,DIRECT
```

## Options

```bash
./scripts/install.sh --help
```

Examples:

```bash
# Different proxy group
./scripts/install.sh --proxy-group "🚀 节点选择"

# Keep current TUN state
./scripts/install.sh --no-tun

# Use TUN but do not enable the desktop system proxy
./scripts/install.sh --no-system-proxy

# Preview only
./scripts/install.sh --dry-run
```

## Rollback

```bash
./scripts/uninstall.sh
```

The installer creates timestamped backups under:

```text
<Clash Verge Rev data dir>/ai-whitelist-backups/
```

## Install as a Codex skill

Copy this whole directory to your Codex skills directory, for example:

```bash
mkdir -p ~/.codex/skills
cp -r clash-ai-whitelist ~/.codex/skills/
```

Then you can ask your coding agent to use `$clash-ai-whitelist` to inspect, configure, verify, or roll back the proxy setup.

## Important

`profiles.yaml` can contain subscription URLs/tokens. This project reads only enough to confirm that the standard global `Script` profile entry exists and deliberately does **not** rewrite or print that file.
