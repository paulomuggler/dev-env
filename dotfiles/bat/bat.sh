# bat.sh - bat (better cat) configuration
# This file is symlinked to shell.d/ and sourced by .bashrc

# On Ubuntu/Debian, bat is installed as 'batcat'
# Create bat alias to point to batcat if needed
if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
  alias bat="batcat"
fi

# Alias cat to bat with no paging for command-line use
# Use 'bat' directly when you want paging/full features
if command -v bat >/dev/null 2>&1 || command -v batcat >/dev/null 2>&1; then
  alias cat="bat --paging=never --style=plain"

  # Convenient bat aliases
  alias batp="bat --paging=always"  # Force paging
fi

# bat theme (uses bat's config file at ~/.config/bat/config)
# Catppuccin theme will be set there when available
