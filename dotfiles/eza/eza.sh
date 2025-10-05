# eza.sh - eza (modern ls) configuration
# This file is symlinked to shell.d/ and sourced by .bashrc

# NOTE: We intentionally DON'T alias ls to eza
# Scripts and tools expect POSIX ls behavior
# Use eza directly or via these aliases

# Modern ls replacement aliases
alias ll='eza -la --git --icons'
alias la='eza -a --icons'
alias lt='eza --tree --level=2 --icons'
alias l='eza -1 --icons'
alias llt='eza -la --git --icons --tree --level=2'

# Tree views
alias tree='eza --tree --icons'
alias tree2='eza --tree --level=2 --icons'
alias tree3='eza --tree --level=3 --icons'

# Git-aware listing
alias lg='eza -la --git --git-ignore --icons'
