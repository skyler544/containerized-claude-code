FROM --platform=linux/amd64 node:22-trixie-slim AS acp-builder

ARG CODEX_ACP_VERSION=1.12.0
ARG BUN_VERSION=1.3.6

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        ca-certificates \
        curl \
    && rm -rf /var/lib/apt/lists/* \
    && npm install --global "bun@${BUN_VERSION}"

WORKDIR /src

RUN curl -fsSL \
        "https://github.com/agentclientprotocol/codex-acp/archive/refs/tags/v${CODEX_ACP_VERSION}.tar.gz" \
        | tar -xz --strip-components=1 \
    && npm ci \
    && npm run bundle:linux-x64


FROM --platform=linux/amd64 debian:trixie-slim AS codex-installer

ARG CODEX_VERSION=0.154.0

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        ca-certificates \
        curl \
    && rm -rf /var/lib/apt/lists/* \
    && curl -fsSL https://chatgpt.com/codex/install.sh -o /tmp/install-codex.sh \
    && CODEX_HOME=/opt/codex-home \
        CODEX_INSTALL_DIR=/opt/bin \
        CODEX_NON_INTERACTIVE=1 \
        sh /tmp/install-codex.sh --release "${CODEX_VERSION}" \
    && rm /tmp/install-codex.sh


FROM --platform=linux/amd64 debian:trixie-slim

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        bash \
        bubblewrap \
        ca-certificates \
        curl \
        git \
        ripgrep \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /home/node

COPY --from=codex-installer /opt /opt
COPY --from=acp-builder \
    /src/dist/bin/codex-acp-x64-linux \
    /usr/local/bin/codex-acp
COPY managed_config.toml /etc/codex/managed_config.toml

ENV CODEX_HOME=/home/node/.codex \
    CODEX_PATH=/opt/bin/codex \
    PATH=/opt/bin:${PATH}

WORKDIR /workspace

CMD ["codex"]
