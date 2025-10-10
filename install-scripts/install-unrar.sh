#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# UnRAR Installation Script
# Installs unrar (RAR archive extraction - .rar files)
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions (loads bashlog, bash-utility)
source "${SCRIPT_DIR}/../libs/utils.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_unrar() {
  log info "=== Installing unrar ==="

  # Check if already installed
  if ! check_installed unrar; then
    # Dry-run check
    if dry_run_report "Would install unrar via brew"; then
      return 0
    fi

    # Install via Homebrew
    log info "Installing unrar via Homebrew..."
    if brew install unrar; then
      report_changed "unrar installed successfully"
    else
      report_failed "Failed to install unrar via brew"
      return 1
    fi

    # Verify installation
    if ! check_installed unrar; then
      report_failed "unrar installation verification failed"
      return 1
    fi
  else
    local version
    version=$(unrar -v 2>&1 | head -1 || echo "version unknown")
    report_ok "unrar is already installed ($version)"
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
install_unrar
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== unrar installation complete ==="
  log info "Usage: unrar x archive.rar (extract archive)"
  log info "       unrar l archive.rar (list contents)"
  log info "       unrar t archive.rar (test archive integrity)"
else
  log error "=== unrar installation failed ==="
fi

exit "${exit_code}"
