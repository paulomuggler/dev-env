# nvim.sh - Neovim configuration and aliases
# This file is symlinked to shell.d/ and sourced by .bashrc

# Neovim configuration functions

# Plain Neovim without any configuration
# Uses minimal or no config for debugging/quick edits
nvim_plain() {
  # Option 1: Use a minimal config directory if it exists
  if [[ -d "$HOME/.config/nvim-plain" ]]; then
    NVIM_APPNAME=nvim-plain nvim "$@"
  else
    # Option 2: Start with no config (completely clean)
    nvim --clean "$@"
  fi
}

# LazyVim is the default - just use 'nvim' directly
# Keeping this function for backward compatibility with existing aliases
lazyvim_func() {
  nvim "$@"
}

# Neovim aliases
# LazyVim is the default, so 'nvim' uses LazyVim
alias lazyvim='nvim'

# Plain nvim without any configuration (for debugging/quick edits)
alias nvim-plain='nvim_plain'
