# fzf.sh - fzf (fuzzy finder) configuration
# This file is symlinked to shell.d/ and sourced by .bashrc

# Initialize fzf key bindings and fuzzy completion if available
if command -v fzf &> /dev/null; then
  eval "$(fzf --bash)"
fi

# Configure fzf's Ctrl+R preview window
export FZF_CTRL_R_OPTS="--preview 'echo {}' --height=40% --border"

# Additional fzf options
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
