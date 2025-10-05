#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Starship Installation Script
# Installs starship (cross-shell prompt) and configures it
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions (loads bashlog, bash-utility)
source "${SCRIPT_DIR}/../libs/utils.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_starship() {
  log info "=== Installing starship ==="

  # Check if already installed
  if ! check_installed starship; then
    # Dry-run check
    if dry_run_report "Would install starship via brew"; then
      return 0
    fi

    # Install via Homebrew
    log info "Installing starship via Homebrew..."
    if brew install starship; then
      report_changed "starship installed successfully"
    else
      report_failed "Failed to install starship via brew"
      return 1
    fi

    # Verify installation
    if ! check_installed starship; then
      report_failed "starship installation verification failed"
      return 1
    fi
  fi

  # Stow starship configuration files
  log info "Applying starship configuration..."
  if ! stow_package "starship"; then
    report_failed "Failed to apply starship configuration"
    return 1
  fi

  # Link starship shell configuration into shell.d/
  log info "Configuring starship shell integration..."
  if ! link_shell_config "starship"; then
    report_failed "Failed to link starship shell configuration"
    return 1
  fi

  # Re-stow shell package to include starship.sh symlink
  local dotfiles_dir
  dotfiles_dir="$(cd "${SCRIPT_DIR}/../dotfiles" && pwd)"

  if (cd "${dotfiles_dir}" && stow -R --dotfiles -t "${HOME}" shell); then
    report_changed "Applied starship shell configuration"
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
install_starship
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== starship installation complete ==="
  log info "Restart your terminal or run: source ~/.bashrc"
else
  log error "=== starship installation failed ==="
fi

exit "${exit_code}"
