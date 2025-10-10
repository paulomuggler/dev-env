#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# p7zip Installation Script
# Installs p7zip (7-Zip port for Unix - .7z archives)
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions (loads bashlog, bash-utility)
source "${SCRIPT_DIR}/../libs/utils.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_p7zip() {
  log info "=== Installing p7zip ==="

  # Check if already installed
  if ! check_installed 7z; then
    # Dry-run check
    if dry_run_report "Would install p7zip via brew"; then
      return 0
    fi

    # Install via Homebrew
    log info "Installing p7zip via Homebrew..."
    if brew install p7zip; then
      report_changed "p7zip installed successfully"
    else
      report_failed "Failed to install p7zip via brew"
      return 1
    fi

    # Verify installation
    if ! check_installed 7z; then
      report_failed "p7zip installation verification failed"
      return 1
    fi
  else
    local version
    version=$(7z --help 2>&1 | head -2 | tail -1 || echo "version unknown")
    report_ok "p7zip is already installed ($version)"
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
install_p7zip
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== p7zip installation complete ==="
  log info "Usage: 7z a archive.7z files/ (create archive)"
  log info "       7z x archive.7z (extract archive)"
  log info "       7z l archive.7z (list contents)"
else
  log error "=== p7zip installation failed ==="
fi

exit "${exit_code}"
