### Containerized Claude Code

This is a mostly vibe-coded proof-of-concept debian container for Claude Code.

No guarantees that this is good at all 🤣

This consists of a Dockerfile and a wrapper `claude` script for starting claude inside the container in a subdirectory of your mounted workspace.

### Setup
I've restricted it to my workspace directory, and the path to this repository is also hardcoded in the wrapper script. If you want to try this you can use my structure but you will probably want to change these paths:

- Projects directory: `~/workspace`
- Repo location: `~/build/programming/claude`

After cloning you should run `mkdir -p $REPO_LOCATION/claude-home/workspace` to make the workspace directory for the container.

Next, build the container: `docker build --build-arg HOST_UID=$(id -u) -t claude-cli:latest "$HOME/build/programming/claude/"`

Finally, symlink the wrapper script: `ln -s $REPO_LOCATION/claude $HOME/.local/bin/claude`

### Usage
The oauth flow should happen automatically when you run `claude` but you will probably need to manually copy/paste the auth link and auth token.
