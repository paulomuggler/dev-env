#!/usr/bin/env bash
# GitLab CLI shell configuration

# GitLab CLI shell completion
if command -v glab >/dev/null 2>&1; then
  eval "$(glab completion -s bash)"
fi

# Useful aliases
alias glmr='glab mr list'
alias glmrc='glab mr create'
alias glmrv='glab mr view'
alias glrc='glab repo clone'
alias glrv='glab repo view'
