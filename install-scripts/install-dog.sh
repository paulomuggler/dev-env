#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# dog Installation Script
# Installs dog (dig alternative with better output)
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (dog is same across platforms)
PACKAGE_NAME=$(get_package_name "dog")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_dog() {
  log info "=== Installing dog ==="

  # Check if already installed
  if ! check_installed dog; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} via package manager"; then
      return 0
    fi

    # Install via package manager
    log info "Installing ${PACKAGE_NAME}..."
    if pkg_install "${PACKAGE_NAME}"; then
      report_changed "dog installed successfully"
    else
      report_failed "Failed to install dog"
      return 1
    fi

    # Verify installation
    if ! check_installed dog; then
      report_failed "dog installation verification failed"
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
install_dog
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== dog installation complete ==="
else
  log error "=== dog installation failed ==="
fi

exit "${exit_code}"
