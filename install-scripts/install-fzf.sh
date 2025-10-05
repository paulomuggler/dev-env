#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# fzf Installation Script
# Installs fzf (fuzzy finder) and configures it
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions (loads bashlog, bash-utility)
source "${SCRIPT_DIR}/../libs/utils.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_fzf() {
  log info "=== Installing fzf ==="

  # Check if already installed
  if ! check_installed fzf; then
    # Dry-run check
    if dry_run_report "Would install fzf via brew"; then
      return 0
    fi

    # Install via Homebrew
    log info "Installing fzf via Homebrew..."
    if brew install fzf; then
      report_changed "fzf installed successfully"
    else
      report_failed "Failed to install fzf via brew"
      return 1
    fi

    # Verify installation
    if ! check_installed fzf; then
      report_failed "fzf installation verification failed"
      return 1
    fi
  fi

  # Link fzf shell configuration into shell.d/
  log info "Configuring fzf shell integration..."
  if ! link_shell_config "fzf"; then
    report_failed "Failed to link fzf shell configuration"
    return 1
  fi

  # Re-stow shell package to include fzf.sh symlink
  local dotfiles_dir
  dotfiles_dir="$(cd "${SCRIPT_DIR}/../dotfiles" && pwd)"

  if (cd "${dotfiles_dir}" && stow -R --dotfiles -t "${HOME}" shell); then
    report_changed "Applied fzf shell configuration"
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
install_fzf
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== fzf installation complete ==="
  log info "Restart your terminal or run: source ~/.bashrc"
else
  log error "=== fzf installation failed ==="
fi

exit "${exit_code}"
