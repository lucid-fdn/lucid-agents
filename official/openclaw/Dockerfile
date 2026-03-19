FROM node:22-slim

RUN apt-get update && apt-get install -y curl git && rm -rf /var/lib/apt/lists/*

# Install OpenClaw from npm (Node 22 required)
RUN npm install -g openclaw@latest --unsafe-perm

# Create workspace + config dirs
RUN mkdir -p /workspace /root/.openclaw
WORKDIR /workspace

# Entrypoint script that generates config from env vars at runtime
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 18789

HEALTHCHECK --interval=30s --timeout=5s CMD curl -f http://localhost:18789/health || exit 1

ENTRYPOINT ["/entrypoint.sh"]
