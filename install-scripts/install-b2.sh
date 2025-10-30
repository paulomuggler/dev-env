#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Backblaze B2 CLI Installation Script
# Installs b2 (Backblaze B2 cloud storage CLI) and configures it
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (b2-tools is the homebrew formula)
PACKAGE_NAME=$(get_package_name "b2-tools")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_b2() {
  log info "=== Installing Backblaze B2 CLI ==="

  # Check if already installed
  if ! check_installed b2; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} via package manager"; then
      return 0
    fi

    # Install via package manager
    log info "Installing ${PACKAGE_NAME}..."
    if pkg_install "${PACKAGE_NAME}"; then
      report_changed "b2 installed successfully"
    else
      report_failed "Failed to install b2"
      return 1
    fi

    # Verify installation
    if ! check_installed b2; then
      report_failed "b2 installation verification failed"
      return 1
    fi
  fi

  # Stow b2 configuration files
  log info "Applying b2 configuration..."
  if ! stow_package "b2"; then
    report_failed "Failed to apply b2 configuration"
    return 1
  fi

  # Link b2 shell configuration into shell.d/
  log info "Configuring b2 shell integration..."
  if ! link_shell_config "b2"; then
    report_failed "Failed to link b2 shell configuration"
    return 1
  fi

  # Re-stow shell package to include b2.sh symlink
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
install_b2
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== Backblaze B2 CLI installation complete ==="
  log info "Configure with: b2 authorize-account"
  log info "Restart your terminal or run: source ~/.bashrc"
else
  log error "=== Backblaze B2 CLI installation failed ==="
fi

exit "${exit_code}"
