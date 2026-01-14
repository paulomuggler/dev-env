# -----------------------------------------------------------------------------
# dev-env Shell Integration for Omarchy
#
# This file is sourced AFTER Omarchy's default bash config, allowing
# dev-env tool configurations to layer on top of Omarchy defaults.
#
# Source this from ~/.bashrc:
#   source ~/.config/devenv/devenv-shell.sh
# -----------------------------------------------------------------------------

# Load tool-specific configurations from ~/.shell.d/
# These provide dev-env tool integrations (tmux, lazy-llm plugins, etc.)
if [[ -d ~/.shell.d ]]; then
  for config in ~/.shell.d/*.sh; do
    if [[ -f "${config}" ]]; then
      source "${config}"
    fi
  done
fi

# Load custom environment variables (API keys, etc.)
if [[ -f ~/.bash_env ]]; then
  source ~/.bash_env
fi

# Load custom functions if separate from Omarchy's
if [[ -f ~/.bash_functions ]] && [[ ! -L ~/.bash_functions ]]; then
  source ~/.bash_functions
fi
