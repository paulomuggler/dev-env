#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Zstandard Installation Script
# Installs zstd (Zstandard compression - .zst files, modern and fast)
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (zstd is same across platforms)
PACKAGE_NAME=$(get_package_name "zstd")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_zstd() {
  log info "=== Installing zstd ==="

  # Check if already installed
  if ! check_installed zstd; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} via package manager"; then
      return 0
    fi

    # Install via Homebrew
    log info "Installing ${PACKAGE_NAME}..."
    if pkg_install "${PACKAGE_NAME}"; then
      report_changed "zstd installed successfully"
    else
      report_failed "Failed to install zstd"
      return 1
    fi

    # Verify installation
    if ! check_installed zstd; then
      report_failed "zstd installation verification failed"
      return 1
    fi
  else
    local version
    version=$(zstd --version 2>&1 || echo "version unknown")
    report_ok "zstd is already installed ($version)"
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

# Validate platform and package manager
validate_platform

# Run installation
install_zstd
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== zstd installation complete ==="
  log info "Usage: zstd file.txt (compress to file.txt.zst)"
  log info "       unzstd file.txt.zst (decompress)"
  log info "       zstd -d file.txt.zst (decompress, keep original)"
else
  log error "=== zstd installation failed ==="
fi

exit "${exit_code}"
