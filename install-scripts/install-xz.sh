#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# XZ Utils Installation Script
# Installs xz (LZMA compression - .xz and .lzma files)
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions (loads bashlog, bash-utility)
source "${SCRIPT_DIR}/../libs/utils.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_xz() {
  log info "=== Installing xz ==="

  # Check if already installed
  if ! check_installed xz; then
    # Dry-run check
    if dry_run_report "Would install xz via brew"; then
      return 0
    fi

    # Install via Homebrew
    log info "Installing xz via Homebrew..."
    if brew install xz; then
      report_changed "xz installed successfully"
    else
      report_failed "Failed to install xz via brew"
      return 1
    fi

    # Verify installation
    if ! check_installed xz; then
      report_failed "xz installation verification failed"
      return 1
    fi
  else
    local version
    version=$(xz --version 2>&1 | head -1 || echo "version unknown")
    report_ok "xz is already installed ($version)"
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
install_xz
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== xz installation complete ==="
  log info "Usage: xz file.txt (compress to file.txt.xz)"
  log info "       unxz file.txt.xz (decompress)"
  log info "       xz -d file.txt.xz (decompress, keep original)"
else
  log error "=== xz installation failed ==="
fi

exit "${exit_code}"
