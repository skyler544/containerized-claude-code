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
as empty), a directory by an empty tmpfs. The name still shows in a listing, but
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
at the top of the *Secret masking* section in the `claude` script. Run with
`CLAUDE_MASK_VERBOSE=1` to see which paths were hidden.
