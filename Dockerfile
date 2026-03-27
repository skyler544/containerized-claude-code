FROM debian:trixie

# Install only the CLI tools you want Claude to have access to.
RUN apt update && apt install -y --no-install-recommends \
    ca-certificates \
    composer \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

# The install script drops the binary into /root/.local/bin/claude, so
# symlink it into /usr/local/bin so it's on $PATH for everyone
RUN curl -fsSL https://claude.ai/install.sh | bash \
    && ln -s /root/.local/bin/claude /usr/local/bin/claude

# Create a non-root user so Claude can't modify system files even inside the container
# Match this UID to your host user's UID (run 'id youruser' on the host to check).
# This ensures the container user can read/write bind-mounted files.
ARG HOST_UID=1000
RUN useradd -m -u $HOST_UID claude

# without this claude complains every time you run it, probably because it tries
# to update itself
ENV PATH="/home/claude/.local/bin:$PATH"

USER claude
WORKDIR /home/claude/workspace

ENTRYPOINT ["claude"]
