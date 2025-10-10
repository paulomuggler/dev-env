#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# GitHub CLI Installation Script
# Installs gh (GitHub's official command line tool)
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (gh is same across platforms)
PACKAGE_NAME=$(get_package_name "gh")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_gh() {
  log info "=== Installing GitHub CLI ==="

  # Check if already installed
  if ! check_installed gh; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} via package manager"; then
      return 0
    fi

    # Install via package manager
    log info "Installing ${PACKAGE_NAME}..."
    if pkg_install "${PACKAGE_NAME}"; then
      report_changed "gh installed successfully"
    else
      report_failed "Failed to install gh"
      return 1
    fi

    # Verify installation
    if ! check_installed gh; then
      report_failed "gh installation verification failed"
      return 1
    fi
  fi

  # Link gh shell configuration into shell.d/
  log info "Configuring gh shell integration..."
  if ! link_shell_config "gh"; then
    report_failed "Failed to link gh shell configuration"
    return 1
  fi

  # Re-stow shell package to include gh.sh symlink
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
install_gh
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== GitHub CLI installation complete ==="
  log info ""
  log info "Next steps:"
  log info "1. Authenticate with GitHub: gh auth login"
  log info "2. Set your preferred editor: gh config set editor nvim"
  log info ""
  log info "Common commands:"
  log info "  gh repo clone <repo>       # Clone a repository"
  log info "  gh pr create               # Create a pull request"
  log info "  gh pr list                 # List pull requests"
  log info "  gh issue create            # Create an issue"
  log info "  gh browse                  # Open repo in browser"
else
  log error "=== GitHub CLI installation failed ==="
fi

exit "${exit_code}"
