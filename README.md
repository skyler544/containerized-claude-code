# Containerized Codex

This project provides small Podman wrappers for Codex and the Codex ACP
adapter. Run a wrapper from a project directory and that directory is mounted
as the container's writable workspace.

## Setup

The same image contains both `codex` and `codex-acp`:

```sh
./rebuild-codex-container
ln -s "$REPO_LOCATION/codex" "$HOME/.local/bin/codex"
ln -s "$REPO_LOCATION/codex-acp" "$HOME/.local/bin/codex-acp"
```

Both are native Rust binaries. Node.js and npm are used only in an intermediate
image stage to retrieve the binaries and are not present in the runtime image.

Run `codex` from any directory you want to work in. Its authentication,
configuration, sessions, and other state are persisted under
`$HOME/.cache/codex-home` by default.

The image's managed Codex configuration sets approval policy to `never` and
sandbox mode to `danger-full-access`, so both wrappers execute commands without
approval prompts or Codex's own nested sandbox. The `codex` wrapper also passes
`--dangerously-bypass-approvals-and-sandbox` explicitly. The Podman container,
restricted mounts, and read-only Git metadata are the safety boundary instead.

On startup the launcher copies the repo's `AGENTS.md` into that Codex home so
Codex gets global instructions without overriding any project-local `AGENTS.md`.

`codex-acp` uses the same image, state, current-directory workspace, and mount
policy. It communicates over stdio, so an ACP client should launch the wrapper
directly. The workspace and optional planning directory are mounted at their
exact host paths so absolute paths exchanged over ACP also resolve on the host.

Both wrappers:

- use `:z` on every bind mount for SELinux compatibility;
- overlay an existing workspace `.git` path read-only;
- mount `$HOME/planning` only when it exists, with its `.git` read-only when
  present;
- run rootless with the host UID/GID, all capabilities dropped, and
  `no-new-privileges`.

Set `CODEX_HOME_HOST` to use a different persistent host state directory.
