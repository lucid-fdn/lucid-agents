#!/bin/bash
set -e

# Generate openclaw.json from env vars at container startup
# This means users configure via env vars, not by editing files inside the container

CONFIG_DIR="/root/.openclaw"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"
mkdir -p "$CONFIG_DIR"

# Build config JSON from env vars
cat > "$CONFIG_FILE" << EOFCONFIG
{
  "agent": {
    "model": "${OPENCLAW_MODEL:-anthropic/claude-sonnet-4-6}"
  },
  "gateway": {
    "host": "0.0.0.0",
    "port": ${PORT:-18789}
  }
}
EOFCONFIG

# Write provider API keys to .env if provided
ENV_FILE="$CONFIG_DIR/.env"
> "$ENV_FILE"  # Clear

# LLM provider keys
[ -n "$ANTHROPIC_API_KEY" ] && echo "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY" >> "$ENV_FILE"
[ -n "$OPENAI_API_KEY" ] && echo "OPENAI_API_KEY=$OPENAI_API_KEY" >> "$ENV_FILE"

# Messaging channel tokens
[ -n "$TELEGRAM_BOT_TOKEN" ] && echo "TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN" >> "$ENV_FILE"
[ -n "$DISCORD_BOT_TOKEN" ] && echo "DISCORD_BOT_TOKEN=$DISCORD_BOT_TOKEN" >> "$ENV_FILE"
[ -n "$SLACK_BOT_TOKEN" ] && echo "SLACK_BOT_TOKEN=$SLACK_BOT_TOKEN" >> "$ENV_FILE"
[ -n "$SLACK_SIGNING_SECRET" ] && echo "SLACK_SIGNING_SECRET=$SLACK_SIGNING_SECRET" >> "$ENV_FILE"
[ -n "$SIGNAL_PHONE_NUMBER" ] && echo "SIGNAL_PHONE_NUMBER=$SIGNAL_PHONE_NUMBER" >> "$ENV_FILE"
[ -n "$WHATSAPP_PHONE_ID" ] && echo "WHATSAPP_PHONE_ID=$WHATSAPP_PHONE_ID" >> "$ENV_FILE"
[ -n "$WHATSAPP_TOKEN" ] && echo "WHATSAPP_TOKEN=$WHATSAPP_TOKEN" >> "$ENV_FILE"

echo "[Lucid] OpenClaw config generated from env vars"
echo "[Lucid]   Model: ${OPENCLAW_MODEL:-anthropic/claude-sonnet-4-6}"
echo "[Lucid]   Port: ${PORT:-18789}"
[ -n "$TELEGRAM_BOT_TOKEN" ] && echo "[Lucid]   Telegram: connected"
[ -n "$DISCORD_BOT_TOKEN" ] && echo "[Lucid]   Discord: connected"
[ -n "$SLACK_BOT_TOKEN" ] && echo "[Lucid]   Slack: connected"

# Start OpenClaw gateway in headless mode
exec openclaw gateway --port "${PORT:-18789}" --verbose
