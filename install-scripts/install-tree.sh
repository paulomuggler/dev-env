#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# tree Installation Script
# Installs tree (directory tree listing)
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (tree is same across platforms)
PACKAGE_NAME=$(get_package_name "tree")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_tree() {
  log info "=== Installing tree ==="

  # Check if already installed
  if ! check_installed tree; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} via package manager"; then
      return 0
    fi

    # Install via package manager
    log info "Installing ${PACKAGE_NAME}..."
    if pkg_install "${PACKAGE_NAME}"; then
      report_changed "tree installed successfully"
    else
      report_failed "Failed to install tree"
      return 1
    fi

    # Verify installation
    if ! check_installed tree; then
      report_failed "tree installation verification failed"
      return 1
    fi
  else
    report_ok "tree is already installed ($(tree --version 2>&1 | head -n1 || echo 'version unknown'))"
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

# Validate platform and package manager
validate_platform

# Run installation
install_tree
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== tree installation complete ==="
  log info "Usage: tree [directory] - Display directory tree structure"
  log info "Common options: -L <level> (depth), -a (all files), -d (dirs only)"
else
  log error "=== tree installation failed ==="
fi

exit "${exit_code}"
