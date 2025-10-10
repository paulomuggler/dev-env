#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# iTerm2 Installation Script
# Installs iTerm2 terminal emulator on macOS
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

check_iterm2_installed() {
  # Check if iTerm2 is installed in Applications
  if [[ -d "/Applications/iTerm.app" ]]; then
    return 0
  fi
  return 1
}

configure_iterm2_preferences() {
  local iterm2_config_dir="${HOME}/.config/iterm2"
  local plist_file="${iterm2_config_dir}/com.googlecode.iterm2.plist"

  # Stow the iterm2 configuration first
  if [[ -d "${SCRIPT_DIR}/../dotfiles/iterm2" ]]; then
    log info "Applying iTerm2 configuration..."
    if ! stow_package "iterm2"; then
      log warn "Failed to stow iTerm2 configuration"
      return 1
    fi
    report_changed "iTerm2 configuration stowed to ${iterm2_config_dir}"
  else
    log warn "No iTerm2 dotfiles package found"
    return 0
  fi

  # Check if plist exists after stowing
  if [[ ! -f "${plist_file}" ]]; then
    log warn "iTerm2 plist not found at ${plist_file}"
    log warn "Configuration will not be applied automatically"
    return 0
  fi

  # Configure iTerm2 to use the custom preferences folder
  log info "Configuring iTerm2 to use custom preferences folder..."

  # Set the custom preferences folder
  if ! defaults write com.googlecode.iterm2 PrefsCustomFolder -string "${iterm2_config_dir}"; then
    log warn "Failed to set PrefsCustomFolder (non-fatal)"
    return 0
  fi

  # Enable loading from custom folder
  if ! defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true; then
    log warn "Failed to enable LoadPrefsFromCustomFolder (non-fatal)"
    return 0
  fi

  report_changed "iTerm2 configured to use custom preferences folder"
  log info "Custom preferences folder: ${iterm2_config_dir}"
  log warn "IMPORTANT: Restart iTerm2 completely for changes to take effect"

  return 0
}

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_iterm2() {
  log info "=== Installing iTerm2 ==="

  # Check if already installed
  if check_iterm2_installed; then
    local version
    version=$(defaults read /Applications/iTerm.app/Contents/Info.plist CFBundleShortVersionString 2>/dev/null || echo "version unknown")
    report_ok "iTerm2 is already installed (version ${version})"

    # Still configure preferences if not done
    configure_iterm2_preferences
    return 0
  fi

  # Dry-run check
  if dry_run_report "Would install iTerm2 via Homebrew cask"; then
    return 0
  fi

  # Check if Homebrew is available
  if ! check::command_exists brew; then
    report_failed "Homebrew is required to install iTerm2"
    log error "Please run: ./install-scripts/install-homebrew.sh"
    return 1
  fi

  # Install iTerm2 via Homebrew cask
  log info "Installing iTerm2 via Homebrew cask..."
  if brew install --cask iterm2; then
    report_changed "iTerm2 installed successfully"
  else
    report_failed "Failed to install iTerm2"
    return 1
  fi

  # Verify installation
  if ! check_iterm2_installed; then
    report_failed "iTerm2 installation verification failed"
    return 1
  fi

  # Configure preferences
  configure_iterm2_preferences

  return 0
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

# iTerm2 is macOS-specific
if ! is_macos; then
  report_failed "iTerm2 is only available on macOS"
  log error "Current platform: $(get_platform)"
  exit 1
fi

# Validate platform and package manager
validate_platform

# Run installation
install_iterm2
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== iTerm2 installation complete ==="
  log info ""
  log info "Configuration:"
  log info "  - Custom preferences folder: ~/.config/iterm2/"
  log info "  - Preferences file: ~/.config/iterm2/com.googlecode.iterm2.plist"
  log info "  - Managed via GNU Stow from dotfiles/iterm2/"
  log info ""
  log info "IMPORTANT: Restart iTerm2 completely for preferences to take effect"
  log info ""
  log info "Next steps:"
  log info "1. Quit iTerm2 completely (⌘Q)"
  log info "2. Launch iTerm2 from Applications or Spotlight"
  log info "3. Verify custom folder is active:"
  log info "   defaults read com.googlecode.iterm2 PrefsCustomFolder"
  log info ""
  log info "Making changes:"
  log info "  - All preference changes automatically save to ~/.config/iterm2/"
  log info "  - Changes are version controlled in dotfiles/iterm2/"
  log info "  - Commit changes: git add dotfiles/iterm2/ && git commit"
  log info ""
  log info "Shell integration:"
  log info "  - Already configured via dotfiles/shell/dot-bashrc"
  log info "  - Integration script: ~/.iterm2_shell_integration.bash"
else
  log error "=== iTerm2 installation failed ==="
fi

exit "${exit_code}"
