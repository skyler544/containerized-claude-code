FROM alpine:latest

# Install only the CLI tools you want Claude to have access to.
RUN apk add --no-cache \
    bash \
    ca-certificates \
    coreutils \
    curl \
    diffutils \
    findutils \
    gawk \
    git \
    grep \
    sed

# must install as root, otherwise the bind mount of the claude home dir will overwrite the binary
RUN curl -fsSL https://claude.ai/install.sh | bash \
    && cp /root/.local/bin/claude /usr/local/bin/claude \
    && chmod 755 /usr/local/bin/claude

# git needs a private index in the container, because the git dir is read only
# and the wrapper keeps some paths out of the working tree
COPY container-git /usr/local/bin/git
RUN chmod 755 /usr/local/bin/git

# run claude as a non-root user; --userns=keep-id in the launcher maps the host
# user's UID to the same UID inside the container
RUN adduser -D claude
USER claude

WORKDIR /home/claude/workspace

# stop claude complaining about not being on path
ENV PATH="/home/claude/.local/bin:$PATH"

ENTRYPOINT ["/usr/local/bin/claude"]
