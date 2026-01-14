#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Gemini CLI Installation Script
# Installs Google's Gemini CLI (AI agent for terminal)
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions (loads bashlog, bash-utility, platform, utils)
source "${SCRIPT_DIR}/../libs/linker.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_gemini_cli() {
  log info "=== Installing Gemini CLI ==="

  # Check if already installed
  if ! check_installed gemini; then
    # Dry-run check
    if dry_run_report "Would install Gemini CLI via npm"; then
      return 0
    fi

    # Install via npm globally
    log info "Installing Gemini CLI via npm..."
    if npm install -g @google/gemini-cli; then
      report_changed "Gemini CLI installed successfully"
    else
      report_failed "Failed to install Gemini CLI via npm"
      return 1
    fi

    # Verify installation
    if ! check_installed gemini; then
      report_failed "Gemini CLI installation verification failed"
      return 1
    fi
  fi

  # Display authentication info
  log info ""
  log info "Gemini CLI has been installed successfully!"
  log info ""
  log info "To use Gemini CLI:"
  log info "  1. Run 'gemini' in your terminal"
  log info "  2. Authenticate with your Google account"
  log info "  3. Start chatting with Gemini 2.5 Pro"
  log info ""
  log info "Features:"
  log info "  - 1M token context window"
  log info "  - Built-in Google Search grounding"
  log info "  - File operations and shell commands"
  log info "  - MCP (Model Context Protocol) support"
  log info ""
  log info "Free tier: 60 requests/min, 1000 requests/day"
  log info ""
  log info "Usage:"
  log info "  - Start Gemini CLI: gemini"
  log info "  - Use with lazy-llm: lazy-llm -t gemini"
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

# Check Node.js version (requires 20+)
NODE_VERSION=$(node --version | sed 's/v//' | cut -d. -f1)
if [[ ${NODE_VERSION} -lt 20 ]]; then
  report_failed "Gemini CLI requires Node.js 20 or higher. Current version: $(node --version)"
  exit 1
fi

# Run installation
install_gemini_cli
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== Gemini CLI installation complete ==="
else
  log error "=== Gemini CLI installation failed ==="
fi

exit "${exit_code}"
