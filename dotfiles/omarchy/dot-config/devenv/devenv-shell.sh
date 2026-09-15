# -----------------------------------------------------------------------------
# dev-env Shell Integration for Omarchy
#
# For hosts that keep their own ~/.bashrc and just append:
#   source ~/.config/devenv/devenv-shell.sh
#
# When dev-env's own .bashrc is stowed over ~/.bashrc it already loads all of
# this in the right order, so this file is a no-op there. Loading ~/.shell.d a
# second time is not merely wasteful -- every tool init subprocess runs again.
# -----------------------------------------------------------------------------

if [[ -n "${DEVENV_SHELL_D_LOADED:-}" ]]; then
  return 0
fi

DEVENV_SHELL_D_LOADED=1

# Load custom environment variables (API keys, etc.)
if [[ -f ~/.bash_env ]]; then
  source ~/.bash_env
fi

# Load custom functions if separate from Omarchy's
if [[ -f ~/.bash_functions ]] && [[ ! -L ~/.bash_functions ]]; then
  source ~/.bash_functions
fi

# Load tool-specific configurations from ~/.shell.d/
# These provide dev-env tool integrations (tmux, lazy-llm plugins, etc.)
if [[ -d ~/.shell.d ]]; then
  for config in ~/.shell.d/*.sh; do
    if [[ -f "${config}" ]]; then
      source "${config}"
    fi
  done
  unset config
fi
