# tmux.sh - Tmux configuration and environment settings
# This file is symlinked to shell.d/ and sourced by .bashrc

# Fix TERM mismatch between tmux and the shell
# tmux uses screen-256color as default-terminal, so we match it
if [[ -n "$TMUX" ]]; then
  export TERM=screen-256color
fi
