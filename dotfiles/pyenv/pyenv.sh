#!/usr/bin/env bash
# pyenv shell configuration

# Initialize pyenv if installed (generated init is cached; see 00-devenv-cache.sh)
if command -v pyenv >/dev/null 2>&1; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  devenv_cache_eval pyenv pyenv init - --no-rehash
fi
