#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Lynx Installation Script
# Installs lynx (text-based web browser) for CopilotChat URL fetching
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions (loads bashlog, bash-utility)
source "${SCRIPT_DIR}/../libs/utils.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_lynx() {
  log info "=== Installing lynx ==="

  # Check if already installed
  if ! check_installed lynx -version; then
    # Dry-run check
    if dry_run_report "Would install lynx via brew"; then
      return 0
    fi

    # Install via Homebrew
    log info "Installing lynx via Homebrew..."
    if brew install lynx; then
      report_changed "lynx installed successfully"
    else
      report_failed "Failed to install lynx via brew"
      return 1
    fi

    # Verify installation
    if ! check_installed lynx -version; then
      report_failed "lynx installation verification failed"
      return 1
    fi
  fi

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

# Ensure Homebrew is available
if ! check::command_exists brew; then
  report_failed "Homebrew is required but not installed. Please run install-homebrew.sh first"
  exit 1
fi

# Run installation
install_lynx
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== lynx installation complete ==="
  log info "lynx is a text-based web browser used by CopilotChat for improved URL content fetching"
else
  log error "=== lynx installation failed ==="
fi

exit "${exit_code}"
