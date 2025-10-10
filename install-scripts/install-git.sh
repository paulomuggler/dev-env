#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Git Installation Script
# Installs Git via Homebrew and validates installation
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (git is same across platforms)
PACKAGE_NAME=$(get_package_name "git")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_git() {
  log info "=== Installing Git ==="

  # Check if already installed
  if ! check_installed git; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} via package manager"; then
      return 0
    fi

    # Install via package manager
    log info "Installing ${PACKAGE_NAME}..."
    if pkg_install "${PACKAGE_NAME}"; then
      report_changed "Git installed successfully"
    else
      report_failed "Failed to install git"
      return 1
    fi

    # Verify installation
    if ! check_installed git; then
      report_failed "Git installation verification failed"
      return 1
    fi
  fi

  # Stow git configuration (always apply, even if git was already installed)
  log info "Applying git configuration..."
  if ! stow_package "git"; then
    report_failed "Failed to apply git configuration"
    return 1
  fi

  # Link git shell configuration into shell.d/
  log info "Configuring git shell integration..."
  if ! link_shell_config "git"; then
    report_failed "Failed to link git shell configuration"
    return 1
  fi

  # Re-stow shell package to include git.sh symlink
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
install_git
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== Git installation complete ==="
else
  log error "=== Git installation failed ==="
fi

exit "${exit_code}"