#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Lazygit Installation Script
# Installs lazygit (Git TUI) and configures it with Catppuccin theme
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions (loads bashlog, bash-utility)
source "${SCRIPT_DIR}/../libs/utils.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_lazygit() {
  log info "=== Installing lazygit ==="

  # Check if already installed
  if ! check_installed lazygit; then
    # Dry-run check
    if dry_run_report "Would install lazygit via brew"; then
      return 0
    fi

    # Install via Homebrew
    log info "Installing lazygit via Homebrew..."
    if brew install lazygit; then
      report_changed "lazygit installed successfully"
    else
      report_failed "Failed to install lazygit via brew"
      return 1
    fi

    # Verify installation
    if ! check_installed lazygit; then
      report_failed "lazygit installation verification failed"
      return 1
    fi
  fi

  # Stow lazygit configuration files
  log info "Applying lazygit configuration..."
  if ! stow_package "lazygit"; then
    report_failed "Failed to apply lazygit configuration"
    return 1
  fi

  # Link lazygit shell configuration into shell.d/
  log info "Configuring lazygit shell integration..."
  if ! link_shell_config "lazygit"; then
    report_failed "Failed to link lazygit shell configuration"
    return 1
  fi

  # Re-stow shell package to include lazygit.sh symlink
  local dotfiles_dir
  dotfiles_dir="$(cd "${SCRIPT_DIR}/../dotfiles" && pwd)"

  if (cd "${dotfiles_dir}" && stow -R --dotfiles -t "${HOME}" shell); then
    report_changed "Applied lazygit shell configuration"
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
install_lazygit
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== lazygit installation complete ==="
  log info "Usage: lg (lazygit), lgr (lazygit at repo root)"
  log info "Restart your terminal or run: source ~/.bashrc"
else
  log error "=== lazygit installation failed ==="
fi

exit "${exit_code}"
