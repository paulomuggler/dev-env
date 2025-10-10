#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# gdu Installation Script
# Installs gdu (disk usage analyzer with ncurses interface)
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (gdu is same across platforms)
PACKAGE_NAME=$(get_package_name "gdu")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_gdu() {
  log info "=== Installing gdu ==="

  # Check if already installed
  if ! check_installed gdu; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} via package manager"; then
      return 0
    fi

    # Install via package manager
    log info "Installing ${PACKAGE_NAME}..."
    if pkg_install "${PACKAGE_NAME}"; then
      report_changed "gdu installed successfully"
    else
      report_failed "Failed to install gdu"
      return 1
    fi

    # Verify installation
    if ! check_installed gdu; then
      report_failed "gdu installation verification failed"
      return 1
    fi
  else
    report_ok "gdu is already installed ($(gdu --version 2>&1 | head -n1 || echo 'version unknown'))"
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

# Validate platform and package manager
validate_platform

# Run installation
install_gdu
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== gdu installation complete ==="
  log info "Usage: gdu [directory] - Interactive disk usage analyzer"
else
  log error "=== gdu installation failed ==="
fi

exit "${exit_code}"
