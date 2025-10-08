#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Glow Installation Script
# Installs glow (markdown preview in terminal) for use with glow.nvim plugin
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions (loads bashlog, bash-utility)
source "${SCRIPT_DIR}/../libs/utils.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_glow() {
  log info "=== Installing glow ==="

  # Check if already installed
  if ! check_installed glow; then
    # Dry-run check
    if dry_run_report "Would install glow via brew"; then
      return 0
    fi

    # Install via Homebrew
    log info "Installing glow via Homebrew..."
    if brew install glow; then
      report_changed "glow installed successfully"
    else
      report_failed "Failed to install glow via brew"
      return 1
    fi

    # Verify installation
    if ! check_installed glow; then
      report_failed "glow installation verification failed"
      return 1
    fi
  fi

  log info "glow CLI is ready (will be used by glow.nvim LazyVim plugin)"
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
install_glow
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== glow installation complete ==="
  log info "The glow.nvim plugin in LazyVim will use this CLI tool for markdown preview"
else
  log error "=== glow installation failed ==="
fi

exit "${exit_code}"
