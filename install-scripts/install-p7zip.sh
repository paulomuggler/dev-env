#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# p7zip Installation Script
# Installs p7zip (7-Zip port for Unix - .7z archives)
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (p7zip is same across platforms)
PACKAGE_NAME=$(get_package_name "p7zip")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_p7zip() {
  log info "=== Installing p7zip ==="

  # Check if already installed
  if ! check_installed 7z; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} via package manager"; then
      return 0
    fi

    # Install via Homebrew
    log info "Installing ${PACKAGE_NAME}..."
    if pkg_install "${PACKAGE_NAME}"; then
      report_changed "p7zip installed successfully"
    else
      report_failed "Failed to install p7zip"
      return 1
    fi

    # Verify installation
    if ! check_installed 7z; then
      report_failed "p7zip installation verification failed"
      return 1
    fi
  else
    local version
    version=$(7z --help 2>&1 | head -2 | tail -1 || echo "version unknown")
    report_ok "p7zip is already installed ($version)"
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

# Validate platform and package manager
validate_platform

# Run installation
install_p7zip
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== p7zip installation complete ==="
  log info "Usage: 7z a archive.7z files/ (create archive)"
  log info "       7z x archive.7z (extract archive)"
  log info "       7z l archive.7z (list contents)"
else
  log error "=== p7zip installation failed ==="
fi

exit "${exit_code}"
