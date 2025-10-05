# zoxide.sh - zoxide (smart cd) configuration
# This file is symlinked to shell.d/ and sourced by .bashrc

# Initialize zoxide if available
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init bash)"
fi
