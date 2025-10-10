#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# rbenv Installation Script
# Installs rbenv (Ruby version manager) and ruby-build
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (rbenv is same across platforms)
PACKAGE_NAME=$(get_package_name "rbenv")
RUBY_BUILD=$(get_package_name "ruby-build")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_rbenv() {
  log info "=== Installing rbenv ==="

  # Check if already installed
  if ! check_installed rbenv; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} and ${RUBY_BUILD} via package manager"; then
      return 0
    fi

    # Install via package manager
    log info "Installing ${PACKAGE_NAME} and ${RUBY_BUILD}..."
    if pkg_install "${PACKAGE_NAME}" && pkg_install "${RUBY_BUILD}"; then
      report_changed "rbenv installed successfully"
    else
      report_failed "Failed to install rbenv"
      return 1
    fi

    # Verify installation
    if ! check_installed rbenv; then
      report_failed "rbenv installation verification failed"
      return 1
    fi
  else
    local version
    version=$(rbenv --version || echo "version unknown")
    report_ok "rbenv is already installed ($version)"
  fi

  # Initialize rbenv
  log info "Initializing rbenv..."
  if eval "$(rbenv init - bash)"; then
    log info "rbenv initialized for current shell"
  fi

  # Stow rbenv configuration if exists
  if [[ -d "${SCRIPT_DIR}/../dotfiles/rbenv" ]]; then
    log info "Applying rbenv configuration..."
    if ! stow_package "rbenv"; then
      log warn "Failed to apply rbenv configuration (non-fatal)"
    fi
  fi

  # Link rbenv shell configuration into shell.d/
  log info "Configuring rbenv shell integration..."
  if ! link_shell_config "rbenv"; then
    report_failed "Failed to link rbenv shell configuration"
    return 1
  fi

  # Re-stow shell package to include rbenv.sh symlink
  # Use stow_package to ensure proper conflict handling
  if ! stow_package "shell"; then
    report_failed "Failed to re-stow shell configuration"
    return 1
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

# Validate platform and package manager
validate_platform

# Run installation
install_rbenv
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== rbenv installation complete ==="
  log info ""
  log info "Next steps:"
  log info "1. Restart your terminal or run: source ~/.bashrc"
  log info "2. Install a Ruby version: rbenv install 3.3.0"
  log info "3. Set global Ruby version: rbenv global 3.3.0"
  log info "4. Verify: ruby --version"
  log info ""
  log info "Common commands:"
  log info "  rbenv install -l       # List available Ruby versions"
  log info "  rbenv install 3.3.0    # Install specific version"
  log info "  rbenv global 3.3.0     # Set global default"
  log info "  rbenv local 3.3.0      # Set version for current directory"
else
  log error "=== rbenv installation failed ==="
fi

exit "${exit_code}"
