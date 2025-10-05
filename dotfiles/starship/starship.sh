# starship.sh - Starship prompt configuration
# This file is symlinked to shell.d/ and sourced by .bashrc

# Initialize Starship prompt if available
if command -v starship &> /dev/null; then
  eval "$(starship init bash)"
fi
