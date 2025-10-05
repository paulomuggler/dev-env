#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# tree Installation Script
# Installs tree (directory tree listing)
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions (loads bashlog, bash-utility)
source "${SCRIPT_DIR}/../libs/utils.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_tree() {
  log info "=== Installing tree ==="

  # Check if already installed
  if ! check_installed tree; then
    # Dry-run check
    if dry_run_report "Would install tree via brew"; then
      return 0
    fi

    # Install via Homebrew
    log info "Installing tree via Homebrew..."
    if brew install tree; then
      report_changed "tree installed successfully"
    else
      report_failed "Failed to install tree via brew"
      return 1
    fi

    # Verify installation
    if ! check_installed tree; then
      report_failed "tree installation verification failed"
      return 1
    fi
  else
    report_ok "tree is already installed ($(tree --version 2>&1 | head -n1 || echo 'version unknown'))"
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
install_tree
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== tree installation complete ==="
  log info "Usage: tree [directory] - Display directory tree structure"
  log info "Common options: -L <level> (depth), -a (all files), -d (dirs only)"
else
  log error "=== tree installation failed ==="
fi

exit "${exit_code}"
