#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# ast-grep Installation Script
# Installs ast-grep (structural search and replace for code)
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (ast-grep is same across platforms)
PACKAGE_NAME=$(get_package_name "ast-grep")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_ast_grep() {
  log info "=== Installing ast-grep ==="

  # Check if already installed
  if ! check_installed ast-grep; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} via package manager"; then
      return 0
    fi

    # Install via package manager
    log info "Installing ${PACKAGE_NAME}..."
    if pkg_install "${PACKAGE_NAME}"; then
      report_changed "ast-grep installed successfully"
    else
      report_failed "Failed to install ast-grep"
      return 1
    fi

    # Verify installation
    if ! check_installed ast-grep; then
      report_failed "ast-grep installation verification failed"
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
install_ast_grep
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== ast-grep installation complete ==="
else
  log error "=== ast-grep installation failed ==="
fi

exit "${exit_code}"
