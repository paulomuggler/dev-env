#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# zoxide Installation Script
# Installs zoxide (smart cd command) and configures it
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions (loads bashlog, bash-utility)
source "${SCRIPT_DIR}/../libs/utils.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_zoxide() {
  log info "=== Installing zoxide ==="

  # Check if already installed
  if ! check_installed zoxide; then
    # Dry-run check
    if dry_run_report "Would install zoxide via brew"; then
      return 0
    fi

    # Install via Homebrew
    log info "Installing zoxide via Homebrew..."
    if brew install zoxide; then
      report_changed "zoxide installed successfully"
    else
      report_failed "Failed to install zoxide via brew"
      return 1
    fi

    # Verify installation
    if ! check_installed zoxide; then
      report_failed "zoxide installation verification failed"
      return 1
    fi
  fi

  # Link zoxide shell configuration into shell.d/
  log info "Configuring zoxide shell integration..."
  if ! link_shell_config "zoxide"; then
    report_failed "Failed to link zoxide shell configuration"
    return 1
  fi

  # Re-stow shell package to include zoxide.sh symlink
  local dotfiles_dir
  dotfiles_dir="$(cd "${SCRIPT_DIR}/../dotfiles" && pwd)"

  if (cd "${dotfiles_dir}" && stow -R --dotfiles -t "${HOME}" shell); then
    report_changed "Applied zoxide shell configuration"
  else
    report_failed "Failed to re-stow shell configuration"
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
install_zoxide
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== zoxide installation complete ==="
  log info "Restart your terminal or run: source ~/.bashrc"
else
  log error "=== zoxide installation failed ==="
fi

exit "${exit_code}"
