#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Homebrew Installation Script
# Installs Homebrew package manager for macOS
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions (loads bashlog, bash-utility)
source "${SCRIPT_DIR}/../libs/utils.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_homebrew() {
  log info "=== Installing Homebrew ==="

  # Check if already installed
  if check_installed brew; then
    return 0
  fi

  # Dry-run check
  if dry_run_report "Would install Homebrew via official install script"; then
    return 0
  fi

  # Install Homebrew
  log info "Installing Homebrew..."
  log warn "You may be prompted for your password by the Homebrew installer"

  if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
    report_changed "Homebrew installed successfully"
  else
    report_failed "Failed to install Homebrew"
    return 1
  fi

  # Add Homebrew to PATH for this session
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    log info "Added Homebrew to PATH for this session"
  fi

  # Verify installation
  if ! check_installed brew; then
    report_failed "Homebrew installation verification failed"
    return 1
  fi

  # Add Homebrew to .bash_path
  log info "Configuring Homebrew PATH..."
  ensure_bash_path_sourced
  # shellcheck disable=SC2016
  add_to_path_file "Homebrew" 'eval "$(/opt/homebrew/bin/brew shellenv)"' "brew"

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

# Run installation
install_homebrew
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== Homebrew installation complete ==="
  log info "Homebrew has been added to ~/.bash_path"
  log info "Restart your terminal or run: source ~/.bash_profile"
else
  log error "=== Homebrew installation failed ==="
fi

exit "${exit_code}"
