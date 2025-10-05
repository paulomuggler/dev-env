#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# htop Installation Script
# Installs htop (interactive process viewer)
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions (loads bashlog, bash-utility)
source "${SCRIPT_DIR}/../libs/utils.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_htop() {
  log info "=== Installing htop ==="

  # Check if already installed
  if ! check_installed htop; then
    # Dry-run check
    if dry_run_report "Would install htop via brew"; then
      return 0
    fi

    # Install via Homebrew
    log info "Installing htop via Homebrew..."
    if brew install htop; then
      report_changed "htop installed successfully"
    else
      report_failed "Failed to install htop via brew"
      return 1
    fi

    # Verify installation
    if ! check_installed htop; then
      report_failed "htop installation verification failed"
      return 1
    fi
  else
    report_ok "htop is already installed ($(htop --version 2>&1 | head -n1 || echo 'version unknown'))"
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
install_htop
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== htop installation complete ==="
  log info "Usage: htop - Interactive process viewer"
  log info "Note: Consider using 'btm' (bottom) for a more modern alternative"
else
  log error "=== htop installation failed ==="
fi

exit "${exit_code}"
