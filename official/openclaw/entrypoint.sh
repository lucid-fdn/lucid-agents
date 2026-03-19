#!/bin/bash
set -e

# Generate openclaw config from env vars at container startup
# Users configure via lucid launch --agent openclaw (interactive prompts or --env flags)

CONFIG_DIR="/home/node/.openclaw"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"
WORKSPACE_DIR="/home/node/workspace"
mkdir -p "$CONFIG_DIR" "$WORKSPACE_DIR"

PORT="${PORT:-18789}"

# OpenClaw uses CLAUDE_AI_SESSION_KEY for Claude auth
# We map ANTHROPIC_API_KEY → CLAUDE_AI_SESSION_KEY for better DX
[ -n "$ANTHROPIC_API_KEY" ] && export CLAUDE_AI_SESSION_KEY="${CLAUDE_AI_SESSION_KEY:-$ANTHROPIC_API_KEY}"

# Build channels config based on which tokens are provided
CHANNELS=""

# Telegram — env var TELEGRAM_BOT_TOKEN, webhook mode for Docker
if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
  WEBHOOK_URL="${AGENT_URL:-http://localhost:$PORT}"
  CHANNELS="$CHANNELS
    \"telegram\": {
      \"enabled\": true,
      \"botToken\": \"$TELEGRAM_BOT_TOKEN\",
      \"dmPolicy\": \"open\"
    },"
fi

# Discord
if [ -n "$DISCORD_BOT_TOKEN" ]; then
  CHANNELS="$CHANNELS
    \"discord\": {
      \"enabled\": true,
      \"botToken\": \"$DISCORD_BOT_TOKEN\"
    },"
fi

# Slack
if [ -n "$SLACK_BOT_TOKEN" ]; then
  CHANNELS="$CHANNELS
    \"slack\": {
      \"enabled\": true,
      \"botToken\": \"$SLACK_BOT_TOKEN\",
      \"signingSecret\": \"${SLACK_SIGNING_SECRET:-}\"
    },"
fi

# Remove trailing comma from channels
CHANNELS=$(echo "$CHANNELS" | sed '$ s/,$//')

# Write config file (JSON5 format that OpenClaw expects)
cat > "$CONFIG_FILE" << EOFCONFIG
{
  "agent": {
    "model": "${OPENCLAW_MODEL:-anthropic/claude-opus-4-6}"
  },
  "gateway": {
    "host": "0.0.0.0",
    "port": $PORT
  },
  "workspace": "$WORKSPACE_DIR",
  "channels": {
    $CHANNELS
  }
}
EOFCONFIG

echo "[Lucid] OpenClaw config generated"
echo "[Lucid]   Model: ${OPENCLAW_MODEL:-anthropic/claude-opus-4-6}"
echo "[Lucid]   Port: $PORT"
[ -n "$CLAUDE_AI_SESSION_KEY" ] && echo "[Lucid]   Claude: configured"
[ -n "$OPENAI_API_KEY" ] && echo "[Lucid]   OpenAI: configured"
[ -n "$TELEGRAM_BOT_TOKEN" ] && echo "[Lucid]   Telegram: connected (long-polling)"
[ -n "$DISCORD_BOT_TOKEN" ] && echo "[Lucid]   Discord: connected"
[ -n "$SLACK_BOT_TOKEN" ] && echo "[Lucid]   Slack: connected"
[ -z "$CLAUDE_AI_SESSION_KEY" ] && [ -z "$OPENAI_API_KEY" ] && echo "[Lucid]   WARNING: No LLM key. Set ANTHROPIC_API_KEY or OPENAI_API_KEY."

# Start OpenClaw gateway
exec openclaw gateway --port "$PORT" --verbose
