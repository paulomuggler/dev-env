#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Node.js Installation Script
# Installs Node.js and npm (Node Package Manager)
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (node includes npm)
PACKAGE_NAME=$(get_package_name "node")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_node() {
  log info "=== Installing Node.js ==="

  # Check if node already installed
  if ! check_installed node; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} (includes npm) via package manager"; then
      return 0
    fi

    # Install via package manager
    log info "Installing ${PACKAGE_NAME}..."
    if pkg_install "${PACKAGE_NAME}"; then
      report_changed "Node.js installed successfully"
    else
      report_failed "Failed to install Node.js"
      return 1
    fi

    # Verify installation
    if ! check_installed node; then
      report_failed "Node.js installation verification failed"
      return 1
    fi
  fi

  # Verify npm is available (should come with node)
  if ! check_installed npm; then
    log warn "npm not found (should be included with Node.js)"
    return 1
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

# Validate platform and package manager
validate_platform

# Run installation
install_node
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== Node.js installation complete ==="
  log info ""
  log info "Installed versions:"
  node --version 2>/dev/null && npm --version 2>/dev/null || true
  log info ""
  log info "Common commands:"
  log info "  node --version         # Check Node.js version"
  log info "  npm --version          # Check npm version"
  log info "  npm install <package>  # Install package locally"
  log info "  npm install -g <pkg>   # Install package globally"
  log info "  npx <command>          # Execute package without installing"
else
  log error "=== Node.js installation failed ==="
fi

exit "${exit_code}"
