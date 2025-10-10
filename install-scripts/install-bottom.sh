#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Bottom Installation Script
# Installs bottom (btm - system monitor) and configures it
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (bottom is same across platforms)
PACKAGE_NAME=$(get_package_name "bottom")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_bottom() {
  log info "=== Installing bottom ==="

  # Check if already installed
  if ! check_installed btm; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} via package manager"; then
      return 0
    fi

    # Install via package manager
    log info "Installing ${PACKAGE_NAME}..."
    if pkg_install "${PACKAGE_NAME}"; then
      report_changed "bottom installed successfully"
    else
      report_failed "Failed to install bottom"
      return 1
    fi

    # Verify installation
    if ! check_installed btm; then
      report_failed "bottom installation verification failed"
      return 1
    fi
  fi

  # Stow bottom configuration files
  log info "Applying bottom configuration..."
  if ! stow_package "bottom"; then
    report_failed "Failed to apply bottom configuration"
    return 1
  fi

  # Link bottom shell configuration into shell.d/
  log info "Configuring bottom shell integration..."
  if ! link_shell_config "bottom"; then
    report_failed "Failed to link bottom shell configuration"
    return 1
  fi

  # Re-stow shell package to include bottom.sh symlink
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
install_bottom
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== bottom installation complete ==="
  log info "Usage: btm (or top/htop - aliased to bottom)"
  log info "Restart your terminal or run: source ~/.bashrc"
else
  log error "=== bottom installation failed ==="
fi

exit "${exit_code}"
