### Containerized Claude Code
This is a proof-of-concept container for Claude Code. No guarantees that this is good at all 🤣 That said, it works so far!

The project consists of a `Dockerfile` and a `claude` wrapper script. The wrapper script gives `claude` a dedicated home directory mounted to `$HOME/.cache/claude-home/` where it can output all of its many json files. The host's current working directory is mounted to `/home/claude/workspace/` in the container.

### Setup
- Build the container: `./rebuild-claude-container`
- Symlink the wrapper script: `ln -s $REPO_LOCATION/claude $HOME/.local/bin/claude`
- If needed, mark the script as executable: `chmod +x $REPO_LOCATION/claude`

### Usage
Run `claude` from any directory you want to work in. The oauth flow should happen automatically on first run, but you may need to manually copy/paste the auth link and token.
