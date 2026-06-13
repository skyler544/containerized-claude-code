FROM alpine:latest AS installer

RUN apk add --no-cache \
    nodejs \
    npm

RUN npm install -g \
    @openai/codex \
    @zed-industries/codex-acp \
    && mkdir /out \
    && find /usr/local/lib/node_modules -type f -name codex -exec cp '{}' /out/codex ';' \
    && find /usr/local/lib/node_modules -type f -name codex-acp -exec cp '{}' /out/codex-acp ';' \
    && test -x /out/codex \
    && test -x /out/codex-acp

FROM alpine:latest

# Install only tools that should be available to Codex at runtime.
RUN apk add --no-cache \
    bash \
    bubblewrap \
    ca-certificates \
    curl \
    git \
    ripgrep

COPY --from=installer /out/codex /usr/local/bin/codex
COPY --from=installer /out/codex-acp /usr/local/bin/codex-acp

COPY managed_config.toml /etc/codex/managed_config.toml
RUN test -x /usr/local/bin/codex \
    && test -x /usr/local/bin/codex-acp \
    && test -f /etc/codex/managed_config.toml \
    && ! command -v node \
    && ! command -v npm

# --userns=keep-id in the launcher maps the host user's UID/GID to this user.
RUN adduser -D codex
USER codex

ENV CODEX_HOME=/home/codex/.codex
WORKDIR /workspace

CMD ["codex"]
