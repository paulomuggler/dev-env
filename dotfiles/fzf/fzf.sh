# fzf.sh - fzf (fuzzy finder) configuration
# This file is symlinked to shell.d/ and sourced by .bashrc

# Omarchy 4's own bash init already sources fzf's key-bindings and completion
# from /usr/share/fzf, so only initialise when nothing else has.
if command -v fzf &>/dev/null && ! declare -F __fzf_history__ >/dev/null 2>&1; then
  devenv_cache_eval fzf fzf --bash
fi

# Configure fzf's Ctrl+R preview window
export FZF_CTRL_R_OPTS="--preview 'echo {}' --height=40% --border"

# Additional fzf options
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
