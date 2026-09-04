### Containerized Claude Code
This is a proof-of-concept container for Claude Code. No guarantees that this is good at all 🤣 That said, it works so far!

The project consists of a `Dockerfile` and a `claude` wrapper script. The wrapper script gives `claude` a dedicated home directory mounted to `$HOME/.cache/claude-home/` where it can output all of its many json files. The host's current working directory is mounted to `/home/claude/workspace/` in the container.

### Setup
- Build the container: `./rebuild-claude-container`
- Symlink the wrapper script: `ln -s $REPO_LOCATION/claude $HOME/.local/bin/claude`
- If needed, mark the script as executable: `chmod +x $REPO_LOCATION/claude`

### Usage
Run `./test-claude-wrapper` after changing the wrapper: it states the behavior
below as assertions and checks them against a fake podman, so no container
starts.

Run `claude` from any directory you want to work in. The oauth flow should happen automatically on first run, but you may need to manually copy/paste the auth link and token.

### Secret masking
A bind mount cannot leave out a sub-path, so each secret under the working
directory is covered by a second mount: a file by a read-only `/dev/null` (or a
`{}` stub for `.json`), a directory by an empty read-only tmpfs. The name stays
visible, the content does not.

Masked by default: `.env` and `.env.*`, `.netrc`, `.npmrc`, `.pgpass`,
`.htpasswd`, `.dockercfg`, `*.pem`, `*.key`, `*.p12`, `*.pfx`, `*.jks`,
`*.keystore`, SSH private keys, `credentials`/`credentials.json`,
`service-account*.json`, `secrets.{yml,yaml,json}`, `.claude/settings*.json`,
and the directories `.ssh`, `.gnupg`, `.aws`, `.kube`, `.docker`, `.gcloud`,
`secrets`, `secret`.

Templates stay visible: `.env.example`, `.env.sample`, `.env.dist`,
`.env.template`, `*.pem.example`, `*.key.example`.

The search goes 6 levels deep and skips `.git`, `node_modules`, `vendor`,
`dist`, `build` and `.cache`. To change the lists, edit the `SECRET_*` arrays
in the *Secret masking* section of the `claude` script.

A mask covers the working tree, not the history. If a masked file is committed,
the container still reads it with `git show` — rotate such a secret and drop it
from history.

### Git state in the container
The container gets a private copy of the git dir, mounted read-only at
`.git`, so `git log`, `git diff` and `git status` work while
`git add`/`commit`/`push` fail. The copy is made at every start with hardlinks
and lives in `.git/claude-snapshot.<pid>`; old ones are removed on the next run.
Because it is a snapshot, a commit or a branch switch made on the host during a
session shows up only after a restart.

The copy also carries the state that keeps the wrapper's own mounts out of
`git status`: `skip-worktree` for tracked paths that a mask covers, and exclude
entries for masked paths git does not track and for `planning/`. Real
uncommitted work stays visible, because only masked paths — all of them
read-only — get that bit.
