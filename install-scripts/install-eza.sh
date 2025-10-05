#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Eza Installation Script
# Installs eza (modern ls replacement) and configures it
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions (loads bashlog, bash-utility)
source "${SCRIPT_DIR}/../libs/utils.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_eza() {
  log info "=== Installing eza ==="

  # Check if already installed
  if ! check_installed eza; then
    # Dry-run check
    if dry_run_report "Would install eza via brew"; then
      return 0
    fi

    # Install via Homebrew
    log info "Installing eza via Homebrew..."
    if brew install eza; then
      report_changed "eza installed successfully"
    else
      report_failed "Failed to install eza via brew"
      return 1
    fi

    # Verify installation
    if ! check_installed eza; then
      report_failed "eza installation verification failed"
      return 1
    fi
  fi

  # Link eza shell configuration into shell.d/
  log info "Configuring eza shell integration..."
  if ! link_shell_config "eza"; then
    report_failed "Failed to link eza shell configuration"
    return 1
  fi

  # Re-stow shell package to include eza.sh symlink
  local dotfiles_dir
  dotfiles_dir="$(cd "${SCRIPT_DIR}/../dotfiles" && pwd)"

  if (cd "${dotfiles_dir}" && stow -R --dotfiles -t "${HOME}" shell); then
    report_changed "Applied eza shell configuration"
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
install_eza
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== eza installation complete ==="
  log info "Restart your terminal or run: source ~/.bashrc"
else
  log error "=== eza installation failed ==="
fi

exit "${exit_code}"
