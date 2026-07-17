FROM node:22-trixie-slim

RUN npm install -g \
    @openai/codex \
    @agentclientprotocol/codex-acp

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        bash \
        bubblewrap \
        ca-certificates \
        curl \
        git \
        ripgrep \
    && rm -rf /var/lib/apt/lists/*

COPY managed_config.toml /etc/codex/managed_config.toml

ENV CODEX_HOME=/home/node/.codex
WORKDIR /workspace

CMD ["codex"]
