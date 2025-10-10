#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# fd Installation Script
# Installs fd (fast find alternative) and configures shell integration
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (fd is fd-find on Ubuntu)
declare -A PACKAGE_NAMES=(
  [macos]="fd"
  [ubuntu]="fd-find"
  [arch]="fd"
)
PACKAGE_NAME=$(get_package_name "fd" PACKAGE_NAMES)

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_fd() {
  log info "=== Installing fd ==="

  # Check if already installed
  if ! check_installed fd; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} via package manager"; then
      return 0
    fi

    # Install via package manager
    log info "Installing ${PACKAGE_NAME}..."
    if pkg_install "${PACKAGE_NAME}"; then
      report_changed "fd installed successfully"
    else
      report_failed "Failed to install fd"
      return 1
    fi

    # Verify installation
    if ! check_installed fd; then
      report_failed "fd installation verification failed"
      return 1
    fi
  fi

  # Link fd shell configuration into shell.d/
  log info "Configuring fd shell integration..."
  if ! link_shell_config "fd"; then
    report_failed "Failed to link fd shell configuration"
    return 1
  fi

  # Re-stow shell package to include fd.sh symlink
  local dotfiles_dir
  dotfiles_dir="$(cd "${SCRIPT_DIR}/../dotfiles" && pwd)"

  if (cd "${dotfiles_dir}" && stow -R --dotfiles -t "${HOME}" shell); then
    report_changed "Applied fd shell configuration"
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
install_fd
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== fd installation complete ==="
  log info "Usage: fd 'pattern' (basic), fdfzf (interactive), fddir (cd to dir)"
  log info "Restart your terminal or run: source ~/.bashrc"
else
  log error "=== fd installation failed ==="
fi

exit "${exit_code}"
