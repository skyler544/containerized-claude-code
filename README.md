### Containerized Claude Code
This is a proof-of-concept container for Claude Code. No guarantees that this is good at all 🤣 That said, it works so far!

The project consists of a `Dockerfile` and a `claude` wrapper script. The wrapper script gives `claude` a dedicated home directory mounted to `$HOME/.cache/claude-home/` where it can output all of its many json files. The host's current working directory is mounted to `/home/claude/workspace/` in the container.

### Setup
- Build the container: `./rebuild-claude-container`
- Symlink the wrapper script: `ln -s $REPO_LOCATION/claude $HOME/.local/bin/claude`
- If needed, mark the script as executable: `chmod +x $REPO_LOCATION/claude`

### Usage
Run `claude` from any directory you want to work in. The oauth flow should happen automatically on first run, but you may need to manually copy/paste the auth link and token.

### Secret masking
The working directory is bind-mounted as a whole, and a bind mount cannot leave
out a sub-path. To keep secrets out of the container, the wrapper covers each
one with a second mount: a file is replaced by a read-only `/dev/null` (it reads
as empty), a directory by an empty read-only tmpfs. The name still shows in a
listing, but
the content is not available.

Masked by default: `.env` and `.env.*`, `.netrc`, `.npmrc`, `.pgpass`,
`.htpasswd`, `.dockercfg`, `*.pem`, `*.key`, `*.p12`, `*.pfx`, `*.jks`,
`*.keystore`, SSH private keys, `credentials`/`credentials.json`,
`service-account*.json`, `secrets.{yml,yaml,json}`, and the directories `.ssh`,
`.gnupg`, `.aws`, `.kube`, `.docker`, `.gcloud`, `secrets`, `secret`.

Templates stay visible: `.env.example`, `.env.sample`, `.env.dist`,
`.env.template`, `*.pem.example`, `*.key.example`.

The search goes 6 levels deep and skips `.git`, `node_modules`, `vendor`,
`dist`, `build` and `.cache`. To change the lists, edit the `SECRET_*` arrays
at the top of the *Secret masking* section in the `claude` script.

The wrapper prints nothing at startup: Claude Code takes over the screen at
once, so any message would only flash by. To see which paths a directory gets,
look at the mount list with `podman inspect` while a session runs.

### Git state in the container
The container does not get the live `.git` dir. At every start the wrapper makes
a private copy under `.git/claude-snapshot.<pid>` and mounts that read-only, so
`git log`, `git diff` and `git status` work while `git add`/`commit`/`push` still
fail. The copy is made with hardlinks, so the object store is not duplicated,
and the files the wrapper writes to (`index`, `info/exclude`) are unlinked first
so the host repository is never modified.

The copy carries the state that keeps the mounts of this wrapper out of
`git status`:

- `skip-worktree` on every tracked path that a mask covers, so the masked (empty)
  content does not read as a modification or a deletion.
- an exclude entry for every masked path that git does not track, and for
  `planning/`, so nothing reads as untracked.

Real uncommitted work stays visible: only paths that the same run masks get the
`skip-worktree` bit, and every mask is read-only (`/dev/null`, the `{}` stub, or
a read-only tmpfs), so no change made in the container can be swallowed. The
wrapper refuses to start if a mask is not read-only.

Two limits:

- It is a **snapshot**. A commit or a branch switch on the host during a running
  session is not visible in the container until the next start.
- A mask hides the worktree file, not the history behind it. Where a masked path
  is tracked, the container still reads the committed content with `git show`.
  Only an untracked path is fully hidden. To protect a committed secret, rotate
  it and remove it from history.

Old snapshots are removed at the next start: the directory name carries the PID
of the wrapper, which `exec` hands to the container, so a snapshot with a dead
PID belongs to a finished session. Anything older than a day is removed as well.
