FROM debian:trixie

# Install only the CLI tools you want Claude to have access to.
# Add or remove packages here to control what's available.
RUN apt update && apt install -y --no-install-recommends \
    curl \
    wget \
    jq \
    ripgrep \
    fd-find \
    ca-certificates \
    php \
    composer \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

# fd-find installs as 'fdfind'; alias it to 'fd'
RUN ln -s /usr/bin/fdfind /usr/local/bin/fd

# Install Claude CLI as root — the install script drops the binary into
# /root/.local/bin/claude, so we symlink it into /usr/local/bin so it's
# on PATH for all users (including the non-root 'claude' user below).
RUN curl -fsSL https://claude.ai/install.sh | bash \
    && ln -s /root/.local/bin/claude /usr/local/bin/claude

# Create a non-root user so Claude can't modify system files even inside the container
# Match this UID to your host user's UID (run 'id youruser' on the host to check).
# This ensures the container user can read/write bind-mounted files.
ARG HOST_UID=1000
RUN useradd -m -u $HOST_UID claude

USER claude
ENV PATH="/home/claude/.local/bin:$PATH"
WORKDIR /home/claude/workspace

ENTRYPOINT ["claude"]
