# opencode.sh - OpenCode configuration
# This file is symlinked to shell.d/ and sourced by .bashrc

# Add opencode to PATH
if [[ -d "$HOME/.opencode/bin" ]]; then
  export PATH="$HOME/.opencode/bin:$PATH"
fi

# Load opencode completion. Cached: `opencode completion` boots the whole JS
# runtime and takes over a second, which is most of a slow login shell on its
# own. Run `devenv_cache_clear` after upgrading opencode in place.
if command -v opencode >/dev/null 2>&1; then
  devenv_cache_eval opencode-completion opencode completion
fi
