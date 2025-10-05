#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Ripgrep Installation Script
# Installs ripgrep (fast search tool) and configures shell integration
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions (loads bashlog, bash-utility)
source "${SCRIPT_DIR}/../libs/utils.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_ripgrep() {
  log info "=== Installing ripgrep ==="

  # Check if already installed
  if ! check_installed rg; then
    # Dry-run check
    if dry_run_report "Would install ripgrep via brew"; then
      return 0
    fi

    # Install via Homebrew
    log info "Installing ripgrep via Homebrew..."
    if brew install ripgrep; then
      report_changed "ripgrep installed successfully"
    else
      report_failed "Failed to install ripgrep via brew"
      return 1
    fi

    # Verify installation
    if ! check_installed rg; then
      report_failed "ripgrep installation verification failed"
      return 1
    fi
  fi

  # Link ripgrep shell configuration into shell.d/
  log info "Configuring ripgrep shell integration..."
  if ! link_shell_config "ripgrep"; then
    report_failed "Failed to link ripgrep shell configuration"
    return 1
  fi

  # Re-stow shell package to include ripgrep.sh symlink
  local dotfiles_dir
  dotfiles_dir="$(cd "${SCRIPT_DIR}/../dotfiles" && pwd)"

  if (cd "${dotfiles_dir}" && stow -R --dotfiles -t "${HOME}" shell); then
    report_changed "Applied ripgrep shell configuration"
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
install_ripgrep
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== ripgrep installation complete ==="
  log info "Usage: rg 'pattern' (basic), rgi (case-insensitive), rgfzf (interactive)"
  log info "Restart your terminal or run: source ~/.bashrc"
else
  log error "=== ripgrep installation failed ==="
fi

exit "${exit_code}"
