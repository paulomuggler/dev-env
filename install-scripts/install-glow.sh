#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Glow Installation Script
# Installs glow (markdown preview in terminal) for use with glow.nvim plugin
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (glow is same across platforms)
PACKAGE_NAME=$(get_package_name "glow")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_glow() {
  log info "=== Installing glow ==="

  # Check if already installed
  if ! check_installed glow; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} via package manager"; then
      return 0
    fi

    # Install via package manager
    log info "Installing ${PACKAGE_NAME}..."
    if pkg_install "${PACKAGE_NAME}"; then
      report_changed "glow installed successfully"
    else
      report_failed "Failed to install glow"
      return 1
    fi

    # Verify installation
    if ! check_installed glow; then
      report_failed "glow installation verification failed"
      return 1
    fi
  fi

  log info "glow CLI is ready (will be used by glow.nvim LazyVim plugin)"
  return 0
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

# Validate platform and package manager
validate_platform

# Run installation
install_glow
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== glow installation complete ==="
  log info "The glow.nvim plugin in LazyVim will use this CLI tool for markdown preview"
else
  log error "=== glow installation failed ==="
fi

exit "${exit_code}"
