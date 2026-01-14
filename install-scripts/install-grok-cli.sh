#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Grok CLI Installation Script
# Installs xAI's Grok CLI (AI agent for terminal)
# Uses superagent-ai/grok-cli implementation
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions (loads bashlog, bash-utility, platform, utils)
source "${SCRIPT_DIR}/../libs/linker.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_grok_cli() {
  log info "=== Installing Grok CLI ==="

  # Check if already installed
  if ! check_installed grok; then
    # Dry-run check
    if dry_run_report "Would install Grok CLI via npm"; then
      return 0
    fi

    # Install via npm globally
    log info "Installing Grok CLI via npm..."
    if npm install -g @vibe-kit/grok-cli; then
      report_changed "Grok CLI installed successfully"
    else
      report_failed "Failed to install Grok CLI via npm"
      return 1
    fi

    # Verify installation
    if ! check_installed grok; then
      report_failed "Grok CLI installation verification failed"
      return 1
    fi
  fi

  # Display configuration info
  log info ""
  log info "Grok CLI has been installed successfully!"
  log info ""
  log info "To use Grok CLI, you need an API key from xAI:"
  log info "  1. Get your API key from https://x.ai"
  log info "  2. The CLI will prompt for the key on first run"
  log info "  3. Your key is stored locally for future use"
  log info ""
  log info "Features:"
  log info "  - Conversational UI for natural language commands"
  log info "  - Query and edit large codebases"
  log info "  - 1M token context window"
  log info "  - OpenAI-compatible API support"
  log info ""
  log info "Available models:"
  log info "  - grok-code-fast-1"
  log info "  - grok-4-latest"
  log info "  - grok-3-fast"
  log info ""
  log info "Usage:"
  log info "  - Start Grok CLI: grok"
  log info "  - Specify directory: grok -d /path/to/project"
  log info "  - Use with lazy-llm: lazy-llm -t grok"
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
  report_failed "Grok CLI requires Node.js 18 or higher. Current version: $(node --version)"
  exit 1
fi

# Run installation
install_grok_cli
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== Grok CLI installation complete ==="
else
  log error "=== Grok CLI installation failed ==="
fi

exit "${exit_code}"
