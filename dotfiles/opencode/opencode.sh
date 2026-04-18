# opencode.sh - OpenCode configuration
# This file is symlinked to shell.d/ and sourced by .bashrc

# Add opencode to PATH
if [[ -d "$HOME/.opencode/bin" ]]; then
  export PATH="$HOME/.opencode/bin:$PATH"
fi

# Load opencode completion
if command -v opencode >/dev/null 2>&1; then
  source <(opencode completion)
fi
