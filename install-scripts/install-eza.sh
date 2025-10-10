#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Eza Installation Script
# Installs eza (modern ls replacement) and configures it
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (eza is same across platforms)
PACKAGE_NAME=$(get_package_name "eza")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_eza() {
  log info "=== Installing eza ==="

  # Check if already installed
  if ! check_installed eza; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} via package manager"; then
      return 0
    fi

    # Install via package manager
    log info "Installing ${PACKAGE_NAME}..."
    if pkg_install "${PACKAGE_NAME}"; then
      report_changed "eza installed successfully"
    else
      report_failed "Failed to install eza"
      return 1
    fi

    # Verify installation
    if ! check_installed eza; then
      report_failed "eza installation verification failed"
      return 1
    fi
  fi

  # Link eza shell configuration into shell.d/
  log info "Configuring eza shell integration..."
  if ! link_shell_config "eza"; then
    report_failed "Failed to link eza shell configuration"
    return 1
  fi

  # Re-stow shell package to include eza.sh symlink
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
install_eza
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== eza installation complete ==="
  log info "Restart your terminal or run: source ~/.bashrc"
else
  log error "=== eza installation failed ==="
fi

exit "${exit_code}"
