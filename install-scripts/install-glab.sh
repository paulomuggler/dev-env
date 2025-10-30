#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# GitLab CLI Installation Script
# Installs glab (GitLab's official command line tool)
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (glab is same across platforms)
PACKAGE_NAME=$(get_package_name "glab")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_glab() {
  log info "=== Installing GitLab CLI ==="

  # Check if already installed
  if ! check_installed glab; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} via package manager"; then
      return 0
    fi

    # Install via package manager
    log info "Installing ${PACKAGE_NAME}..."
    if pkg_install "${PACKAGE_NAME}"; then
      report_changed "glab installed successfully"
    else
      report_failed "Failed to install glab"
      return 1
    fi

    # Verify installation
    if ! check_installed glab; then
      report_failed "glab installation verification failed"
      return 1
    fi
  fi

  # Link glab shell configuration into shell.d/
  log info "Configuring glab shell integration..."
  if ! link_shell_config "glab"; then
    report_failed "Failed to link glab shell configuration"
    return 1
  fi

  # Re-stow shell package to include glab.sh symlink
  # Use stow_package to ensure proper conflict handling
  if ! stow_package "shell"; then
    report_failed "Failed to re-stow shell configuration"
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
install_glab
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== GitLab CLI installation complete ==="
  log info ""
  log info "Next steps:"
  log info "1. Authenticate with GitLab: glab auth login"
  log info "2. Set your preferred editor: glab config set editor nvim"
  log info ""
  log info "Common commands:"
  log info "  glab repo clone <group/repo>   # Clone a repository"
  log info "  glab mr create                  # Create a merge request"
  log info "  glab mr list                    # List merge requests"
  log info "  glab issue create               # Create an issue"
  log info "  glab repo view                  # Open repo in browser"
else
  log error "=== GitLab CLI installation failed ==="
fi

exit "${exit_code}"
