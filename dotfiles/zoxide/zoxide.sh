# zoxide.sh - zoxide (smart cd) configuration
# This file is symlinked to shell.d/ and sourced by .bashrc

# Omarchy 4's own bash init already runs `zoxide init bash`.
if declare -F __zoxide_z >/dev/null 2>&1; then
  :
elif command -v zoxide &>/dev/null; then
  devenv_cache_eval zoxide zoxide init bash
fi
