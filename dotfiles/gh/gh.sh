#!/usr/bin/env bash
# GitHub CLI shell configuration

# GitHub CLI shell completion
if command -v gh >/dev/null 2>&1; then
  eval "$(gh completion -s bash)"
fi

# Useful aliases
alias ghpr='gh pr list'
alias ghprc='gh pr create'
alias ghprv='gh pr view'
alias ghrc='gh repo clone'
alias ghrv='gh repo view'
