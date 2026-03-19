#!/bin/bash
set -e

# Generate openclaw config from env vars at container startup
# Users configure via lucid launch --agent openclaw (interactive prompts or --env flags)

CONFIG_DIR="/home/node/.openclaw"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"
WORKSPACE_DIR="/home/node/workspace"
mkdir -p "$CONFIG_DIR" "$WORKSPACE_DIR"

# Build config JSON from env vars
# OpenClaw uses CLAUDE_AI_SESSION_KEY for Claude auth, not ANTHROPIC_API_KEY
# We map ANTHROPIC_API_KEY → CLAUDE_AI_SESSION_KEY for DX
CLAUDE_KEY="${CLAUDE_AI_SESSION_KEY:-$ANTHROPIC_API_KEY}"

cat > "$CONFIG_FILE" << EOFCONFIG
{
  "agent": {
    "model": "${OPENCLAW_MODEL:-anthropic/claude-opus-4-6}"
  },
  "gateway": {
    "host": "0.0.0.0",
    "port": ${PORT:-18789}
  },
  "workspace": "$WORKSPACE_DIR"
}
EOFCONFIG

# Export keys as env vars (OpenClaw reads from process.env)
[ -n "$CLAUDE_KEY" ] && export CLAUDE_AI_SESSION_KEY="$CLAUDE_KEY"
[ -n "$OPENAI_API_KEY" ] && export OPENAI_API_KEY="$OPENAI_API_KEY"

echo "[Lucid] OpenClaw config generated"
echo "[Lucid]   Model: ${OPENCLAW_MODEL:-anthropic/claude-opus-4-6}"
echo "[Lucid]   Port: ${PORT:-18789}"
[ -n "$CLAUDE_KEY" ] && echo "[Lucid]   Claude: configured"
[ -n "$OPENAI_API_KEY" ] && echo "[Lucid]   OpenAI: configured"
[ -z "$CLAUDE_KEY" ] && [ -z "$OPENAI_API_KEY" ] && echo "[Lucid]   WARNING: No LLM API key set. Set ANTHROPIC_API_KEY or OPENAI_API_KEY."

# Start OpenClaw gateway in headless mode
exec openclaw gateway --port "${PORT:-18789}" --verbose
