# bat.sh - bat (better cat) configuration
# This file is symlinked to shell.d/ and sourced by .bashrc

# Alias cat to bat with no paging for command-line use
# Use 'bat' directly when you want paging/full features
alias cat="bat --paging=never --style=plain"

# Convenient bat aliases
alias batcat="bat"  # Full bat with paging and line numbers
alias batp="bat --paging=always"  # Force paging

# bat theme (uses bat's config file at ~/.config/bat/config)
# Catppuccin theme will be set there when available
