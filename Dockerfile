FROM node:22-trixie-slim AS installer

RUN npm install -g \
    @openai/codex \
    @zed-industries/codex-acp \
    && mkdir /out \
    && find /usr/local/lib/node_modules -type f -name codex -exec cp '{}' /out/codex ';' \
    && find /usr/local/lib/node_modules -type f -name codex-acp -exec cp '{}' /out/codex-acp ';'


FROM debian:trixie-slim AS runtime

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        bash \
        bubblewrap \
        ca-certificates \
        curl \
        git \
        ripgrep \
    && rm -rf /var/lib/apt/lists/*

COPY --from=installer /out/codex /usr/local/bin/codex
COPY --from=installer /out/codex-acp /usr/local/bin/codex-acp
COPY managed_config.toml /etc/codex/managed_config.toml

RUN useradd --create-home --shell /bin/bash codex
USER codex

ENV CODEX_HOME=/home/codex/.codex
WORKDIR /workspace

CMD ["codex"]
