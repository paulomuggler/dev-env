#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Bat Installation Script
# Installs bat (cat replacement with syntax highlighting) and configures it
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions (loads bashlog, bash-utility)
source "${SCRIPT_DIR}/../libs/utils.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_bat() {
  log info "=== Installing bat ==="

  # Check if already installed
  if ! check_installed bat; then
    # Dry-run check
    if dry_run_report "Would install bat via brew"; then
      return 0
    fi

    # Install via Homebrew
    log info "Installing bat via Homebrew..."
    if brew install bat; then
      report_changed "bat installed successfully"
    else
      report_failed "Failed to install bat via brew"
      return 1
    fi

    # Verify installation
    if ! check_installed bat; then
      report_failed "bat installation verification failed"
      return 1
    fi
  fi

  # Stow bat configuration files
  log info "Applying bat configuration..."
  if ! stow_package "bat"; then
    report_failed "Failed to apply bat configuration"
    return 1
  fi

  # Link bat shell configuration into shell.d/
  log info "Configuring bat shell integration..."
  if ! link_shell_config "bat"; then
    report_failed "Failed to link bat shell configuration"
    return 1
  fi

  # Re-stow shell package to include bat.sh symlink
  local dotfiles_dir
  dotfiles_dir="$(cd "${SCRIPT_DIR}/../dotfiles" && pwd)"

  if (cd "${dotfiles_dir}" && stow -R --dotfiles -t "${HOME}" shell); then
    report_changed "Applied bat shell configuration"
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
install_bat
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== bat installation complete ==="
  log info "Restart your terminal or run: source ~/.bashrc"
else
  log error "=== bat installation failed ==="
fi

exit "${exit_code}"
