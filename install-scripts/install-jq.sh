#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# jq Installation Script
# Installs jq (command-line JSON processor)
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (jq is same across platforms)
PACKAGE_NAME=$(get_package_name "jq")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_jq() {
  log info "=== Installing jq ==="

  # Check if already installed
  if ! check_installed jq; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} via package manager"; then
      return 0
    fi

    # Install via package manager
    log info "Installing ${PACKAGE_NAME}..."
    if pkg_install "${PACKAGE_NAME}"; then
      report_changed "jq installed successfully"
    else
      report_failed "Failed to install jq"
      return 1
    fi

    # Verify installation
    if ! check_installed jq; then
      report_failed "jq installation verification failed"
      return 1
    fi
  else
    report_ok "jq is already installed ($(jq --version 2>&1 || echo 'version unknown'))"
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

# Validate platform and package manager
validate_platform

# Run installation
install_jq
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== jq installation complete ==="
  log info "Usage: jq '.' file.json - Pretty-print JSON"
  log info "Common: jq '.key' (extract), jq '.[]' (array), jq -r (raw output)"
else
  log error "=== jq installation failed ==="
fi

exit "${exit_code}"
