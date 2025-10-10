#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# zoxide Installation Script
# Installs zoxide (smart cd command) and configures it
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (zoxide is same across platforms)
PACKAGE_NAME=$(get_package_name "zoxide")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_zoxide() {
  log info "=== Installing zoxide ==="

  # Check if already installed
  if ! check_installed zoxide; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} via package manager"; then
      return 0
    fi

    # Install via package manager
    log info "Installing ${PACKAGE_NAME}..."
    if pkg_install "${PACKAGE_NAME}"; then
      report_changed "zoxide installed successfully"
    else
      report_failed "Failed to install zoxide"
      return 1
    fi

    # Verify installation
    if ! check_installed zoxide; then
      report_failed "zoxide installation verification failed"
      return 1
    fi
  fi

  # Link zoxide shell configuration into shell.d/
  log info "Configuring zoxide shell integration..."
  if ! link_shell_config "zoxide"; then
    report_failed "Failed to link zoxide shell configuration"
    return 1
  fi

  # Re-stow shell package to include zoxide.sh symlink
  local dotfiles_dir
  dotfiles_dir="$(cd "${SCRIPT_DIR}/../dotfiles" && pwd)"

  if (cd "${dotfiles_dir}" && stow -R --dotfiles -t "${HOME}" shell); then
    report_changed "Applied zoxide shell configuration"
  else
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
install_zoxide
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== zoxide installation complete ==="
  log info "Restart your terminal or run: source ~/.bashrc"
else
  log error "=== zoxide installation failed ==="
fi

exit "${exit_code}"
