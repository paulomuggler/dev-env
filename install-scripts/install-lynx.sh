#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Lynx Installation Script
# Installs lynx (text-based web browser) for CopilotChat URL fetching
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (lynx is same across platforms)
PACKAGE_NAME=$(get_package_name "lynx")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_lynx() {
  log info "=== Installing lynx ==="

  # Check if already installed
  if ! check_installed lynx -version; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} via package manager"; then
      return 0
    fi

    # Install via package manager
    log info "Installing ${PACKAGE_NAME}..."
    if pkg_install "${PACKAGE_NAME}"; then
      report_changed "lynx installed successfully"
    else
      report_failed "Failed to install lynx"
      return 1
    fi

    # Verify installation
    if ! check_installed lynx -version; then
      report_failed "lynx installation verification failed"
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
install_lynx
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== lynx installation complete ==="
  log info "lynx is a text-based web browser used by CopilotChat for improved URL content fetching"
else
  log error "=== lynx installation failed ==="
fi

exit "${exit_code}"
