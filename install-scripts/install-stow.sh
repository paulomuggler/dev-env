#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# GNU Stow Installation Script
# Installs GNU Stow via Homebrew and applies its configuration
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (stow is same across platforms)
PACKAGE_NAME=$(get_package_name "stow")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_stow() {
  log info "=== Installing GNU Stow ==="

  # Check if already installed
  if ! check_installed stow; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} via package manager"; then
      return 0
    fi

    # Install via package manager
    log info "Installing ${PACKAGE_NAME}..."
    if pkg_install "${PACKAGE_NAME}"; then
      report_changed "GNU Stow installed successfully"
    else
      report_failed "Failed to install stow"
      return 1
    fi

    # Verify installation
    if ! check_installed stow; then
      report_failed "Stow installation verification failed"
      return 1
    fi
  fi

  # Stow the stow configuration
  # Note: Since stow_package() already handles --dotfiles, we can use it directly
  log info "Applying stow configuration..."
  if ! stow_package "stow"; then
    report_failed "Failed to apply stow configuration"
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
install_stow
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== Stow installation complete ==="
else
  log error "=== Stow installation failed ==="
fi

exit "${exit_code}"
