#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Homebrew Shell Configuration
# Bash completion and other Homebrew-specific shell integration
# -----------------------------------------------------------------------------

# Initialize Homebrew's bash completion (macOS only)
if [[ "$(uname -s)" == "Darwin" ]] && [[ -r /opt/homebrew/etc/profile.d/bash_completion.sh ]]; then
  source /opt/homebrew/etc/profile.d/bash_completion.sh
fi
