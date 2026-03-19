#!/bin/bash
set -e

# Generate OpenClaw config from env vars at container startup.
# Full reference: https://docs.openclaw.ai/gateway/configuration-reference

CONFIG_DIR="/home/node/.openclaw"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"
WORKSPACE_DIR="/home/node/workspace"
mkdir -p "$CONFIG_DIR" "$WORKSPACE_DIR" "$WORKSPACE_DIR/skills"

PORT="${PORT:-18789}"

# Map ANTHROPIC_API_KEY → CLAUDE_AI_SESSION_KEY (OpenClaw's internal name)
[ -n "$ANTHROPIC_API_KEY" ] && export CLAUDE_AI_SESSION_KEY="${CLAUDE_AI_SESSION_KEY:-$ANTHROPIC_API_KEY}"

# --- Build channels config ---
CHANNELS=""

# Telegram (long-polling, dmPolicy open for Docker)
if [ -n "$TELEGRAM_BOT_TOKEN" ]; then
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
      \"token\": { \"source\": \"env\", \"provider\": \"default\", \"id\": \"DISCORD_BOT_TOKEN\" },
      \"groupPolicy\": \"open\"
    },"
fi

# Slack (socket mode if app token provided, http mode otherwise)
if [ -n "$SLACK_BOT_TOKEN" ]; then
  SLACK_MODE="socket"
  SLACK_EXTRA=""
  if [ -n "$SLACK_APP_TOKEN" ]; then
    SLACK_EXTRA="\"appToken\": \"$SLACK_APP_TOKEN\","
  else
    SLACK_MODE="http"
    if [ -n "$SLACK_SIGNING_SECRET" ]; then
      SLACK_EXTRA="\"signingSecret\": \"$SLACK_SIGNING_SECRET\","
    fi
  fi
  CHANNELS="$CHANNELS
    \"slack\": {
      \"enabled\": true,
      \"mode\": \"$SLACK_MODE\",
      \"botToken\": \"$SLACK_BOT_TOKEN\",
      $SLACK_EXTRA
      \"dmPolicy\": \"open\"
    },"
fi

# WebChat (always enabled for browser access)
CHANNELS="$CHANNELS
    \"webchat\": {
      \"enabled\": true
    }"

# Remove trailing comma issues
CHANNELS=$(echo "$CHANNELS" | sed 's/,$//')

# --- Build tools config ---
TOOLS_EXTRA=""
if [ -n "$BRAVE_API_KEY" ]; then
  TOOLS_EXTRA="\"webSearch\": { \"provider\": \"brave\", \"apiKey\": \"$BRAVE_API_KEY\" },"
fi

# --- Build messages config ---
MESSAGES_EXTRA=""
if [ -n "$ELEVENLABS_API_KEY" ]; then
  MESSAGES_EXTRA="\"tts\": { \"provider\": \"elevenlabs\", \"apiKey\": \"$ELEVENLABS_API_KEY\" },"
fi

# --- Write config ---
cat > "$CONFIG_FILE" << EOFCONFIG
{
  "agent": {
    "model": "${OPENCLAW_MODEL:-anthropic/claude-opus-4-6}",
    "timezone": "${OPENCLAW_TZ:-UTC}"
  },
  "gateway": {
    "bind": "lan",
    "port": $PORT
  },
  "workspace": "$WORKSPACE_DIR",
  "channels": {
    $CHANNELS
  },
  "tools": {
    $TOOLS_EXTRA
    "allowList": ["*"]
  },
  "messages": {
    $MESSAGES_EXTRA
    "queue": { "mode": "collect" }
  },
  "sessions": {
    "scope": "per-sender"
  }
}
EOFCONFIG

# --- Status output ---
echo "[Lucid] OpenClaw configured from env vars"
echo "[Lucid]   Model: ${OPENCLAW_MODEL:-anthropic/claude-opus-4-6}"
echo "[Lucid]   Port: $PORT"
echo "[Lucid]   Timezone: ${OPENCLAW_TZ:-UTC}"
echo "[Lucid]   Gateway bind: lan (Docker-compatible)"
echo "[Lucid]   WebChat: enabled (http://localhost:$PORT)"
[ -n "$CLAUDE_AI_SESSION_KEY" ] && echo "[Lucid]   Claude: configured"
[ -n "$OPENAI_API_KEY" ] && echo "[Lucid]   OpenAI: configured"
[ -n "$TELEGRAM_BOT_TOKEN" ] && echo "[Lucid]   Telegram: connected (long-polling, open DMs)"
[ -n "$DISCORD_BOT_TOKEN" ] && echo "[Lucid]   Discord: connected"
[ -n "$SLACK_BOT_TOKEN" ] && echo "[Lucid]   Slack: connected (${SLACK_MODE})"
[ -n "$BRAVE_API_KEY" ] && echo "[Lucid]   Web search: enabled (Brave)"
[ -n "$ELEVENLABS_API_KEY" ] && echo "[Lucid]   Voice TTS: enabled (ElevenLabs)"

# Install skills from LUCID_SKILLS env var
if [ -n "$LUCID_SKILLS" ]; then
  echo "[Lucid] Installing skills..."
  IFS=',' read -ra SKILLS <<< "$LUCID_SKILLS"
  for skill in "${SKILLS[@]}"; do
    skill=$(echo "$skill" | xargs)  # trim whitespace
    if [ -n "$skill" ]; then
      echo "[Lucid]   Installing: $skill"
      openclaw skills install "$skill" 2>/dev/null || \
        clawhub install "$skill" 2>/dev/null || \
        echo "[Lucid]   Skill $skill not found"
    fi
  done
  echo "[Lucid] Skills installed"
fi

# Start OpenClaw gateway
exec openclaw gateway --port "$PORT" --verbose
