#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# XZ Utils Installation Script
# Installs xz (LZMA compression - .xz and .lzma files)
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (xz is same across platforms)
PACKAGE_NAME=$(get_package_name "xz")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_xz() {
  log info "=== Installing xz ==="

  # Check if already installed
  if ! check_installed xz; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} via package manager"; then
      return 0
    fi

    # Install via Homebrew
    log info "Installing ${PACKAGE_NAME}..."
    if pkg_install "${PACKAGE_NAME}"; then
      report_changed "xz installed successfully"
    else
      report_failed "Failed to install xz"
      return 1
    fi

    # Verify installation
    if ! check_installed xz; then
      report_failed "xz installation verification failed"
      return 1
    fi
  else
    local version
    version=$(xz --version 2>&1 | head -1 || echo "version unknown")
    report_ok "xz is already installed ($version)"
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

# Validate platform and package manager
validate_platform

# Run installation
install_xz
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== xz installation complete ==="
  log info "Usage: xz file.txt (compress to file.txt.xz)"
  log info "       unxz file.txt.xz (decompress)"
  log info "       xz -d file.txt.xz (decompress, keep original)"
else
  log error "=== xz installation failed ==="
fi

exit "${exit_code}"
