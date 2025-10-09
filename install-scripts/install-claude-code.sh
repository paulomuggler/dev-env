#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Claude Code Installation Script
# Installs Anthropic's Claude Code CLI (agentic coding assistant)
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions (loads bashlog, bash-utility)
source "${SCRIPT_DIR}/../libs/utils.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_claude_code() {
  log info "=== Installing Claude Code ==="

  # Check if already installed
  if ! check_installed claude; then
    # Dry-run check
    if dry_run_report "Would install Claude Code via npm"; then
      return 0
    fi

    # Install via npm globally
    log info "Installing Claude Code via npm..."
    if npm install -g @anthropic-ai/claude-code; then
      report_changed "Claude Code installed successfully"
    else
      report_failed "Failed to install Claude Code via npm"
      return 1
    fi

    # Verify installation
    if ! check_installed claude; then
      report_failed "Claude Code installation verification failed"
      return 1
    fi
  fi

  # Display authentication info
  log info ""
  log info "Claude Code has been installed successfully!"
  log info ""
  log info "To authenticate Claude Code:"
  log info "  1. Run 'claude' in your terminal"
  log info "  2. Follow the OAuth authentication flow"
  log info "  3. Select your preferred terminal style"
  log info ""
  log info "You can verify your installation with: claude doctor"
  log info ""
  log info "Usage:"
  log info "  - Start Claude Code: claude"
  log info "  - Use with lazy-llm: lazy-llm -t claude"
  log info ""

  return 0
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

# Ensure we're on macOS
if ! is_macos; then
  report_failed "This script currently only supports macOS"
  exit 1
fi

# Ensure Node.js is available (required for npm)
if ! check::command_exists npm; then
  report_failed "Node.js/npm is required but not installed. Please install Node.js first"
  exit 1
fi

# Check Node.js version (requires 18+)
NODE_VERSION=$(node --version | sed 's/v//' | cut -d. -f1)
if [[ ${NODE_VERSION} -lt 18 ]]; then
  report_failed "Claude Code requires Node.js 18 or higher. Current version: $(node --version)"
  exit 1
fi

# Run installation
install_claude_code
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== Claude Code installation complete ==="
else
  log error "=== Claude Code installation failed ==="
fi

exit "${exit_code}"
