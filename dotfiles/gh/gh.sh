#!/usr/bin/env bash
# GitHub CLI shell configuration

# GitHub CLI shell completion.
# Cached: on Omarchy 4 `gh` is a mise shim that re-resolves the tool, which can
# cost seconds on a cold run. Run `devenv_cache_clear` after a gh upgrade that
# leaves the shim itself untouched.
if command -v gh >/dev/null 2>&1; then
  devenv_cache_eval gh-completion gh completion -s bash
fi

# Useful aliases
alias ghpr='gh pr list'
alias ghprc='gh pr create'
alias ghprv='gh pr view'
alias ghrc='gh repo clone'
alias ghrv='gh repo view'
