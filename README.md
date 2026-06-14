# Containerized Codex

## What?

This repository runs the Codex CLI and Codex ACP adapter inside a rootless Podman container, mounting the host's current directory as the workspace.
- `codex` runs the interactive Codex CLI.
- `codex-acp` runs the stdio-based ACP adapter.

## Why?

Codex is allowed to execute commands without approval prompts or its own nested sandbox. The host is protected by the containerization and the explicit workspace context mounted inside it.

## How?

The wrappers expect this repository at `$HOME/build/programming/containerized-agents`. Use this path or change the scripts to match your setup. Build the shared image and add the wrappers to your path:

```sh
./rebuild-codex-container
ln -s "$HOME/build/programming/containerized-agents/codex" "$HOME/.local/bin/codex"
ln -s "$HOME/build/programming/containerized-agents/codex-acp" "$HOME/.local/bin/codex-acp"
```

Run `codex` from the project directory you want it to edit:

```sh
cd "$PROJECT"
codex
```

Each invocation:

- mounts the current directory into the container as read-write;
- overlays the workspace's `.git` path read-only when it exists;
- mounts `$HOME/planning` read-only at `<workspace>/planning` when it exists;
- mounts `$HOME/.cache/codex-home` for Codex's state files;
- copies this repository's `AGENTS.md` into that persistent home when newer;
- runs with the host UID/GID, all capabilities dropped, and no new privileges.

The managed Codex configuration disables approval prompts and Codex's sandbox. The `codex` wrapper also passes `--dangerously-bypass-approvals-and-sandbox`.

`codex-acp` uses the same workspace and mounts, keeps container stdin attached for ACP communication, and stops the container when the ACP client exits or the wrapper is signaled. Known to work with [xenodium/agent-shell](https://github.com/xenodium/agent-shell); other ACP clients may or may not work as expected.
