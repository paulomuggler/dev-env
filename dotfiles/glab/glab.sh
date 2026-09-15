#!/usr/bin/env bash
# GitLab CLI shell configuration

# GitLab CLI shell completion (cached; see 00-devenv-cache.sh)
if command -v glab >/dev/null 2>&1; then
  devenv_cache_eval glab-completion glab completion -s bash
fi

# Useful aliases
alias glmr='glab mr list'
alias glmrc='glab mr create'
alias glmrv='glab mr view'
alias glrc='glab repo clone'
alias glrv='glab repo view'
