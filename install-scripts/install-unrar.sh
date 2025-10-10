#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# UnRAR Installation Script
# Installs unrar (RAR archive extraction - .rar files)
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (unrar is same across platforms)
PACKAGE_NAME=$(get_package_name "unrar")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_unrar() {
  log info "=== Installing unrar ==="

  # Check if already installed
  if ! check_installed unrar; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} via package manager"; then
      return 0
    fi

    # Install via Homebrew
    log info "Installing ${PACKAGE_NAME}..."
    if pkg_install "${PACKAGE_NAME}"; then
      report_changed "unrar installed successfully"
    else
      report_failed "Failed to install unrar"
      return 1
    fi

    # Verify installation
    if ! check_installed unrar; then
      report_failed "unrar installation verification failed"
      return 1
    fi
  else
    local version
    version=$(unrar -v 2>&1 | head -1 || echo "version unknown")
    report_ok "unrar is already installed ($version)"
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

# Validate platform and package manager
validate_platform

# Run installation
install_unrar
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== unrar installation complete ==="
  log info "Usage: unrar x archive.rar (extract archive)"
  log info "       unrar l archive.rar (list contents)"
  log info "       unrar t archive.rar (test archive integrity)"
else
  log error "=== unrar installation failed ==="
fi

exit "${exit_code}"
