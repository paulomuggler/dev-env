#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Tmux Installation Script
# Installs tmux via Homebrew and applies configuration
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions (loads bashlog, bash-utility)
source "${SCRIPT_DIR}/../libs/utils.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_tmux() {
  log info "=== Installing Tmux ==="

  # Check if already installed
  if ! check_installed tmux; then
    # Dry-run check
    if dry_run_report "Would install tmux via brew"; then
      return 0
    fi

    # Install via Homebrew
    log info "Installing tmux via Homebrew..."
    if brew install tmux; then
      report_changed "Tmux installed successfully"
    else
      report_failed "Failed to install tmux via brew"
      return 1
    fi

    # Verify installation
    if ! check_installed tmux; then
      report_failed "Tmux installation verification failed"
      return 1
    fi
  fi

  # Stow tmux configuration
  log info "Applying tmux configuration..."
  if ! stow_package "tmux"; then
    report_failed "Failed to apply tmux configuration"
    return 1
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
install_tmux
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== Tmux installation complete ==="
  log info "Configuration applied to ~/.config/tmux/tmux.conf"
  log info "Start tmux with: tmux"
else
  log error "=== Tmux installation failed ==="
fi

exit "${exit_code}"
