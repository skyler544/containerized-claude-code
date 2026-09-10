### Containerized Claude Code
This is a proof-of-concept container for Claude Code. No guarantees that this is good at all 🤣 That said, it works so far!

The project consists of a `Dockerfile`, a `claude` wrapper script for the host,
and a `container-git` shim that the image installs as the container's `git`. The wrapper script gives `claude` a dedicated home directory mounted to `$HOME/.cache/claude-home/` where it can output all of its many json files. The host's current working directory is mounted to `/home/claude/workspace/` in the container.

### Setup
- Build the container: `./rebuild-claude-container`
- Symlink the wrapper script: `ln -s $REPO_LOCATION/claude $HOME/.local/bin/claude`
- If needed, mark the script as executable: `chmod +x $REPO_LOCATION/claude`

### Usage
Run `./test-claude-wrapper` after changing the wrapper. It states the behavior
below as assertions. Most of them run against a fake podman and start no
container. The last section starts one real container with the same arguments
and reads the result from inside, because the arguments alone do not prove what
the kernel does with them. That section needs the image, thus build it first.

`CLAUDE_PRINT_COMMAND=1 claude` prints the command that the wrapper would run,
one argument per line, and starts nothing.

Run `claude` from any directory you want to work in. The oauth flow should happen automatically on first run, but you may need to manually copy/paste the auth link and token.

### Secret masking
No secret of the host is mounted into the container. A bind mount cannot leave
out a sub-path, thus each secret gets a second mount that covers it:

- A secret file gets `/dev/null`. It reads as empty, and a write to it goes
  nowhere.
- A secret directory gets an empty directory of the session. It reads as empty.
- A settings file gets no name at all. `.claude/settings*.json` decides how the
  agent works, thus an empty file is not sufficient. The wrapper puts an empty
  directory over the directory that holds these files, and it mounts each other
  entry of that directory back on top. `.claude/commands` and the rest stay
  live, and the settings files are gone.

Every mask is a bind mount. A tmpfs does not work here: podman applies a
`--tmpfs` before the bind mount of the working directory, thus that bind mount
covers the tmpfs again and the host's files come back. This is not visible in
the arguments of podman, only in a container.

A write to a masked path never reaches the project. A write to a masked file
goes to `/dev/null`. A write in a masked directory goes to the session
directory under `~/.cache/claude-home/.mask/`, and the next start removes it.

Masked by default: `.env` and `.env.*`, `.netrc`, `.npmrc`, `.pgpass`,
`.htpasswd`, `.dockercfg`, `*.pem`, `*.key`, `*.p12`, `*.pfx`, `*.jks`,
`*.keystore`, SSH private keys, `credentials`/`credentials.json`,
`service-account*.json`, `secrets.{yml,yaml,json}`, and the directories `.ssh`,
`.gnupg`, `.aws`, `.kube`, `.docker`, `.gcloud`, `secrets`, `secret`.

Hidden by default, name included: `.claude/settings*.json`.

Templates stay visible: `.env.example`, `.env.sample`, `.env.dist`,
`.env.template`, `*.pem.example`, `*.key.example`.

The search goes 6 levels deep and skips `.git`, `node_modules`, `vendor`,
`dist`, `build` and `.cache`. To change the lists, edit the `SECRET_*` arrays
in the *Secret masking* section of the `claude` script.

A mask stays visible in other ways: a masked file is a character device, a
masked directory is empty, and a remounted symlink is a directory. The memory
file of the container, `~/.cache/claude-home/.claude/CLAUDE.md`, holds a rule
that tells the agent to accept this state, to leave it out of its reports, and
to say nothing about the masking itself.

A mask covers the working tree, not the history. If a masked file is committed,
the container still reads it with `git show`. Rotate such a secret and remove
it from the history.

### Git state in the container
The container gets the host's own git dir. The wrapper mounts it read-only at
`.git`. All read commands work, for example `git log`, `git diff` and
`git status`. All writes fail, thus `git add`, `git commit` and `git push` stop
at the mount.

The mount is live. A branch switch, a commit or a rebase on the host is visible
immediately. The working tree is live too, thus the two always agree.

A path that the wrapper keeps out of the container must not show up as work.
Two mechanisms do this, and neither one writes in the host's repository:

- The container has its own `git`, a shim at `/usr/local/bin/git` from
  `container-git`. It gives git a private index in `/tmp`, which is a copy of
  the host index with a skip-worktree bit on each excluded path. Git thus
  reports neither a change nor a deletion for them. The shim compares the inode,
  the size and the time of the host index against the copy, and it builds the
  copy again as soon as the host writes its index. A branch switch on the host
  stays correct in the same second.
- An exclude file over `.git/info/exclude` covers the excluded paths that git
  does not track, and `planning/`. The host's own rules come first in that file
  and keep their effect.

Real work stays visible. A repository whose only difference from `HEAD` is an
excluded path reports nothing at all.

The wrapper writes the exclusion list and the exclude files to
`~/.cache/claude-home/.mask/session.<pid>`. Each session gets one directory,
and a directory whose process is gone is removed at the next start. The
container reads the list through `CLAUDE_MASK_DIR`. In the host's git dir the
wrapper changes almost nothing. It creates an empty `info/exclude` if the
repository has none, because a mount needs a target, and it deletes the
`claude-session.*` copies from older versions.
