#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# OpenAI Codex CLI Installation Script
# Installs OpenAI's Codex CLI (lightweight coding agent)
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions (loads bashlog, bash-utility, platform, utils)
source "${SCRIPT_DIR}/../libs/linker.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_openai_codex() {
  log info "=== Installing OpenAI Codex CLI ==="

  # Check if already installed
  if ! check_installed codex; then
    # Dry-run check
    if dry_run_report "Would install OpenAI Codex via npm"; then
      return 0
    fi

    # Install via npm globally
    log info "Installing OpenAI Codex via npm..."
    if npm install -g @openai/codex; then
      report_changed "OpenAI Codex installed successfully"
    else
      report_failed "Failed to install OpenAI Codex via npm"
      return 1
    fi

    # Verify installation
    if ! check_installed codex; then
      report_failed "OpenAI Codex installation verification failed"
      return 1
    fi
  fi

  # Display authentication info
  log info ""
  log info "OpenAI Codex CLI has been installed successfully!"
  log info ""
  log info "To authenticate OpenAI Codex:"
  log info "  1. Run 'codex' in your terminal"
  log info "  2. Follow the 'Sign in with ChatGPT' flow"
  log info "  3. Your ChatGPT identity links to an API account in one step"
  log info ""
  log info "Credits for new users:"
  log info "  - Plus users: \$50 in API credits"
  log info "  - Free users: \$5 in API credits"
  log info ""
  log info "Features:"
  log info "  - Read, modify, and run code locally"
  log info "  - Source code never leaves your environment"
  log info "  - Built on OpenAI's latest reasoning models"
  log info ""
  log info "Platform support:"
  log info "  - macOS and Linux: Full support"
  log info "  - Windows: Experimental (use WSL recommended)"
  log info ""
  log info "Usage:"
  log info "  - Start Codex: codex"
  log info "  - Use with lazy-llm: lazy-llm -t codex"
  log info "  - Check installation: codex --version"
  log info ""

  return 0
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

# Validate platform (npm works on any supported platform)
validate_platform

# Ensure Node.js is available (required for npm)
if ! check::command_exists npm; then
  report_failed "Node.js/npm is required but not installed. Please install Node.js first"
  exit 1
fi

# Run installation
install_openai_codex
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== OpenAI Codex installation complete ==="
else
  log error "=== OpenAI Codex installation failed ==="
fi

exit "${exit_code}"
