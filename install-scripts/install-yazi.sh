#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Yazi Installation Script
# Installs yazi (terminal file manager) and configures it with Catppuccin theme
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions (loads bashlog, bash-utility)
source "${SCRIPT_DIR}/../libs/utils.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_yazi() {
  log info "=== Installing yazi ==="

  # Check if already installed
  if ! check_installed yazi; then
    # Dry-run check
    if dry_run_report "Would install yazi via brew"; then
      return 0
    fi

    # Install via Homebrew
    log info "Installing yazi via Homebrew..."
    if brew install yazi; then
      report_changed "yazi installed successfully"
    else
      report_failed "Failed to install yazi via brew"
      return 1
    fi

    # Verify installation
    if ! check_installed yazi; then
      report_failed "yazi installation verification failed"
      return 1
    fi
  fi

  # Stow yazi configuration files
  log info "Applying yazi configuration..."
  if ! stow_package "yazi"; then
    report_failed "Failed to apply yazi configuration"
    return 1
  fi

  # Link yazi shell configuration into shell.d/
  log info "Configuring yazi shell integration..."
  if ! link_shell_config "yazi"; then
    report_failed "Failed to link yazi shell configuration"
    return 1
  fi

  # Re-stow shell package to include yazi.sh symlink
  local dotfiles_dir
  dotfiles_dir="$(cd "${SCRIPT_DIR}/../dotfiles" && pwd)"

  if (cd "${dotfiles_dir}" && stow -R --dotfiles -t "${HOME}" shell); then
    report_changed "Applied yazi shell configuration"
  else
    report_failed "Failed to re-stow shell configuration"
    return 1
  fi

  # Install Catppuccin Mocha flavor via yazi package manager
  log info "Installing Catppuccin Mocha flavor for yazi..."
  if check::command_exists ya; then
    if ya pkg add yazi-rs/flavors:catppuccin-mocha 2>&1 | grep -q "already exists\|successfully"; then
      report_changed "Catppuccin Mocha flavor installed"
    else
      log warning "Failed to install Catppuccin flavor, you may need to run manually:"
      log warning "  ya pkg add yazi-rs/flavors:catppuccin-mocha"
    fi
  else
    log warning "Yazi package manager (ya) not found, flavor not installed"
    log warning "After sourcing your shell, run: ya pkg add yazi-rs/flavors:catppuccin-mocha"
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
install_yazi
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== yazi installation complete ==="
  log info "Usage: y (quick launch), yy (with directory change on exit)"
  log info "If flavor installation failed, run: ya pkg add yazi-rs/flavors:catppuccin-mocha"
  log info "Restart your terminal or run: source ~/.bashrc"
else
  log error "=== yazi installation failed ==="
fi

exit "${exit_code}"
