# lazygit.sh - Lazygit configuration
# This file is symlinked to shell.d/ and sourced by .bashrc

# Alias for quick access
alias lg='lazygit'

# Open lazygit in current directory
alias lgg='lazygit'

# Open lazygit in git root directory
alias lgr='cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)" && lazygit'
