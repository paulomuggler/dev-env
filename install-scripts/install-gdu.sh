#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# gdu Installation Script
# Installs gdu (disk usage analyzer with ncurses interface)
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions (loads bashlog, bash-utility)
source "${SCRIPT_DIR}/../libs/utils.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_gdu() {
  log info "=== Installing gdu ==="

  # Check if already installed
  if ! check_installed gdu; then
    # Dry-run check
    if dry_run_report "Would install gdu via brew"; then
      return 0
    fi

    # Install via Homebrew
    log info "Installing gdu via Homebrew..."
    if brew install gdu; then
      report_changed "gdu installed successfully"
    else
      report_failed "Failed to install gdu via brew"
      return 1
    fi

    # Verify installation
    if ! check_installed gdu; then
      report_failed "gdu installation verification failed"
      return 1
    fi
  else
    report_ok "gdu is already installed ($(gdu --version 2>&1 | head -n1 || echo 'version unknown'))"
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
install_gdu
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== gdu installation complete ==="
  log info "Usage: gdu [directory] - Interactive disk usage analyzer"
else
  log error "=== gdu installation failed ==="
fi

exit "${exit_code}"
