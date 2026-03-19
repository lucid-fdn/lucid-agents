FROM node:22-slim

RUN apt-get update && apt-get install -y curl git && rm -rf /var/lib/apt/lists/*

# Install OpenClaw from npm (Node 22 required)
RUN npm install -g openclaw@latest --unsafe-perm

# Create workspace + config dirs as node user
RUN mkdir -p /home/node/.openclaw /home/node/workspace && chown -R node:node /home/node
WORKDIR /home/node/workspace

# Entrypoint generates config from env vars at runtime
COPY --chown=node:node entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER node

EXPOSE 18789

HEALTHCHECK --interval=30s --timeout=5s CMD curl -f http://localhost:18789/healthz || exit 1

ENTRYPOINT ["/entrypoint.sh"]
