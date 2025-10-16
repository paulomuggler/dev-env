#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# AeroSpace Installation Script
# Installs AeroSpace (i3-like tiling window manager for macOS)
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

check_aerospace_installed() {
  # Check if AeroSpace is installed in Applications
  if [[ -d "/Applications/AeroSpace.app" ]]; then
    return 0
  fi
  return 1
}

configure_aerospace() {
  # Stow the AeroSpace configuration if available
  if [[ -d "${SCRIPT_DIR}/../dotfiles/aerospace" ]]; then
    log info "Applying AeroSpace configuration..."
    if ! stow_package "aerospace"; then
      log warn "Failed to stow AeroSpace configuration"
      return 1
    fi
    report_changed "AeroSpace configuration stowed to ~/.config/aerospace/"
  else
    log info "No AeroSpace dotfiles package found (will use defaults)"
    return 0
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_aerospace() {
  log info "=== Installing AeroSpace ==="

  # Check if already installed
  if check_aerospace_installed; then
    local version
    version=$(defaults read /Applications/AeroSpace.app/Contents/Info.plist CFBundleShortVersionString 2>/dev/null || echo "version unknown")
    report_ok "AeroSpace is already installed (version ${version})"

    # Still configure if not done
    configure_aerospace
    return 0
  fi

  # Dry-run check
  if dry_run_report "Would install AeroSpace via Homebrew cask"; then
    return 0
  fi

  # Check if Homebrew is available
  if ! check::command_exists brew; then
    report_failed "Homebrew is required to install AeroSpace"
    log error "Please run: ./install-scripts/install-homebrew.sh"
    return 1
  fi

  # Install AeroSpace via Homebrew cask
  log info "Installing AeroSpace via Homebrew cask..."
  if brew install --cask nikitabobko/tap/aerospace; then
    report_changed "AeroSpace installed successfully"
  else
    report_failed "Failed to install AeroSpace"
    return 1
  fi

  # Verify installation
  if ! check_aerospace_installed; then
    report_failed "AeroSpace installation verification failed"
    return 1
  fi

  # Configure AeroSpace
  configure_aerospace

  return 0
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

# AeroSpace is macOS-specific
if ! is_macos; then
  report_failed "AeroSpace is only available on macOS"
  log error "Current platform: $(get_platform)"
  exit 1
fi

# Validate platform and package manager
validate_platform

# Run installation
install_aerospace
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== AeroSpace installation complete ==="
  log info ""
  log info "Configuration:"
  log info "  - Config file: ~/.config/aerospace/aerospace.toml"
  log info "  - Managed via GNU Stow from dotfiles/aerospace/"
  log info ""
  log info "Next steps:"
  log info "1. Launch AeroSpace from Applications or Spotlight"
  log info "2. Grant necessary accessibility permissions when prompted"
  log info "3. AeroSpace will start automatically on login"
  log info ""
  log info "Usage:"
  log info "  - AeroSpace provides i3-like tiling window management"
  log info "  - Default keybindings are in the config file"
  log info "  - Documentation: https://github.com/nikitabobko/AeroSpace"
else
  log error "=== AeroSpace installation failed ==="
fi

exit "${exit_code}"
