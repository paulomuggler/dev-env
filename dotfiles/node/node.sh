#!/usr/bin/env bash
# Node.js shell configuration

# Add npm global bin to PATH if node is installed
if command -v npm >/dev/null 2>&1; then
  # Get npm global bin directory and add to PATH if not already there
  NPM_GLOBAL_BIN="$(npm bin -g 2>/dev/null)"
  if [[ -n "$NPM_GLOBAL_BIN" ]] && [[ ":$PATH:" != *":$NPM_GLOBAL_BIN:"* ]]; then
    export PATH="$NPM_GLOBAL_BIN:$PATH"
  fi
fi

# Optional: Set default npm global install location to user directory
# Uncomment if you want to avoid using sudo for global npm installs
# export NPM_CONFIG_PREFIX="$HOME/.npm-global"
# export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
