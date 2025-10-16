#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# dust Installation Script
# Installs dust (du alternative with better visualization)
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (dust is same across platforms, some distros call it du-dust)
PACKAGE_NAME=$(get_package_name "dust")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_dust() {
  log info "=== Installing dust ==="

  # Check if already installed
  if ! check_installed dust; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} via package manager"; then
      return 0
    fi

    # Install via package manager
    log info "Installing ${PACKAGE_NAME}..."
    if pkg_install "${PACKAGE_NAME}"; then
      report_changed "dust installed successfully"
    else
      report_failed "Failed to install dust"
      return 1
    fi

    # Verify installation
    if ! check_installed dust; then
      report_failed "dust installation verification failed"
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
install_dust
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== dust installation complete ==="
else
  log error "=== dust installation failed ==="
fi

exit "${exit_code}"
