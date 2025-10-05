#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Bottom Installation Script
# Installs bottom (btm - system monitor) and configures it
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions (loads bashlog, bash-utility)
source "${SCRIPT_DIR}/../libs/utils.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_bottom() {
  log info "=== Installing bottom ==="

  # Check if already installed
  if ! check_installed btm; then
    # Dry-run check
    if dry_run_report "Would install bottom via brew"; then
      return 0
    fi

    # Install via Homebrew
    log info "Installing bottom via Homebrew..."
    if brew install bottom; then
      report_changed "bottom installed successfully"
    else
      report_failed "Failed to install bottom via brew"
      return 1
    fi

    # Verify installation
    if ! check_installed btm; then
      report_failed "bottom installation verification failed"
      return 1
    fi
  fi

  # Stow bottom configuration files
  log info "Applying bottom configuration..."
  if ! stow_package "bottom"; then
    report_failed "Failed to apply bottom configuration"
    return 1
  fi

  # Link bottom shell configuration into shell.d/
  log info "Configuring bottom shell integration..."
  if ! link_shell_config "bottom"; then
    report_failed "Failed to link bottom shell configuration"
    return 1
  fi

  # Re-stow shell package to include bottom.sh symlink
  local dotfiles_dir
  dotfiles_dir="$(cd "${SCRIPT_DIR}/../dotfiles" && pwd)"

  if (cd "${dotfiles_dir}" && stow -R --dotfiles -t "${HOME}" shell); then
    report_changed "Applied bottom shell configuration"
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
install_bottom
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== bottom installation complete ==="
  log info "Usage: btm (or top/htop - aliased to bottom)"
  log info "Restart your terminal or run: source ~/.bashrc"
else
  log error "=== bottom installation failed ==="
fi

exit "${exit_code}"
