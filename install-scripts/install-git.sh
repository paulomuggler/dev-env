#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Git Installation Script
# Installs Git via Homebrew and validates installation
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions (loads bashlog, bash-utility, colr.sh)
source "${SCRIPT_DIR}/../libs/utils.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_git() {
  log info "=== Installing Git ==="

  # Check if already installed
  if ! check_installed git; then
    # Dry-run check
    if dry_run_report "Would install git via brew"; then
      return 0
    fi

    # Install via Homebrew
    log info "Installing git via Homebrew..."
    if brew install git; then
      report_changed "Git installed successfully"
    else
      report_failed "Failed to install git via brew"
      return 1
    fi

    # Verify installation
    if ! check_installed git; then
      report_failed "Git installation verification failed"
      return 1
    fi
  fi

  # Stow git configuration (always apply, even if git was already installed)
  log info "Applying git configuration..."
  if ! stow_package "git"; then
    report_failed "Failed to apply git configuration"
    return 1
  fi

  # Link git shell configuration into shell.d/
  log info "Configuring git shell integration..."
  if ! link_shell_config "git"; then
    report_failed "Failed to link git shell configuration"
    return 1
  fi

  # Re-stow shell package to include git.sh symlink
  local dotfiles_dir
  dotfiles_dir="$(cd "${SCRIPT_DIR}/../dotfiles" && pwd)"

  if (cd "${dotfiles_dir}" && stow -R --dotfiles -t "${HOME}" shell); then
    report_changed "Applied git shell configuration"
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
install_git
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== Git installation complete ==="
else
  log error "=== Git installation failed ==="
fi

exit "${exit_code}"