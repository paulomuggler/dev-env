#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Bat Installation Script
# Installs bat (cat replacement with syntax highlighting) and configures it
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (bat is same across platforms)
PACKAGE_NAME=$(get_package_name "bat")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_bat() {
  log info "=== Installing bat ==="

  # Check if already installed (Ubuntu installs as 'batcat', not 'bat')
  local cmd_name="bat"
  if is_ubuntu && ! check::command_exists bat && check::command_exists batcat; then
    cmd_name="batcat"
  fi

  if ! check_installed "$cmd_name"; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} via package manager"; then
      return 0
    fi

    # Install via package manager
    log info "Installing ${PACKAGE_NAME}..."
    if pkg_install "${PACKAGE_NAME}"; then
      report_changed "bat installed successfully"
    else
      report_failed "Failed to install bat"
      return 1
    fi

    # Verify installation (check for batcat on Ubuntu, bat elsewhere)
    if is_ubuntu; then
      if ! check_installed batcat; then
        report_failed "bat installation verification failed (looking for batcat command)"
        return 1
      fi
    else
      if ! check_installed bat; then
        report_failed "bat installation verification failed"
        return 1
      fi
    fi
  fi

  # Stow bat configuration files
  log info "Applying bat configuration..."
  if ! stow_package "bat"; then
    report_failed "Failed to apply bat configuration"
    return 1
  fi

  # Link bat shell configuration into shell.d/
  log info "Configuring bat shell integration..."
  if ! link_shell_config "bat"; then
    report_failed "Failed to link bat shell configuration"
    return 1
  fi

  # Re-stow shell package to include bat.sh symlink
  local dotfiles_dir
  dotfiles_dir="$(cd "${SCRIPT_DIR}/../dotfiles" && pwd)"

  if (cd "${dotfiles_dir}" && stow -R --dotfiles -t "${HOME}" shell); then
    report_changed "Applied bat shell configuration"
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
install_bat
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== bat installation complete ==="
  log info "Restart your terminal or run: source ~/.bashrc"
else
  log error "=== bat installation failed ==="
fi

exit "${exit_code}"
