#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# htop Installation Script
# Installs htop (interactive process viewer)
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (htop is same across platforms)
PACKAGE_NAME=$(get_package_name "htop")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_htop() {
  log info "=== Installing htop ==="

  # Check if already installed
  if ! check_installed htop; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} via package manager"; then
      return 0
    fi

    # Install via package manager
    log info "Installing ${PACKAGE_NAME}..."
    if pkg_install "${PACKAGE_NAME}"; then
      report_changed "htop installed successfully"
    else
      report_failed "Failed to install htop"
      return 1
    fi

    # Verify installation
    if ! check_installed htop; then
      report_failed "htop installation verification failed"
      return 1
    fi
  else
    report_ok "htop is already installed ($(htop --version 2>&1 | head -n1 || echo 'version unknown'))"
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

# Validate platform and package manager
validate_platform

# Run installation
install_htop
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== htop installation complete ==="
  log info "Usage: htop - Interactive process viewer"
  log info "Note: Consider using 'btm' (bottom) for a more modern alternative"
else
  log error "=== htop installation failed ==="
fi

exit "${exit_code}"
