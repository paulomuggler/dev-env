#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# ncdu Installation Script
# Installs ncdu (ncurses disk usage analyzer)
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (ncdu is same across platforms)
PACKAGE_NAME=$(get_package_name "ncdu")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_ncdu() {
  log info "=== Installing ncdu ==="

  # Check if already installed
  if ! check_installed ncdu; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} via package manager"; then
      return 0
    fi

    # Install via package manager
    log info "Installing ${PACKAGE_NAME}..."
    if pkg_install "${PACKAGE_NAME}"; then
      report_changed "ncdu installed successfully"
    else
      report_failed "Failed to install ncdu"
      return 1
    fi

    # Verify installation
    if ! check_installed ncdu; then
      report_failed "ncdu installation verification failed"
      return 1
    fi
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

# Validate platform and package manager
validate_platform

# Run installation
install_ncdu
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== ncdu installation complete ==="
else
  log error "=== ncdu installation failed ==="
fi

exit "${exit_code}"
