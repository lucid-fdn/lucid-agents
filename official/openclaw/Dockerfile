FROM node:20-slim

RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Install OpenClaw from npm (always latest)
RUN npm install -g openclaw@latest

# Create workspace
RUN mkdir -p /workspace
WORKDIR /workspace

# Default config
RUN mkdir -p /root/.openclaw
COPY openclaw.json /root/.openclaw/openclaw.json

EXPOSE 18789

HEALTHCHECK --interval=30s --timeout=5s CMD curl -f http://localhost:18789/health || exit 1

CMD ["openclaw", "start", "--headless"]
