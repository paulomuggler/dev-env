#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Lazygit Installation Script
# Installs lazygit (Git TUI) and configures it with Catppuccin theme
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (lazygit is same across platforms)
PACKAGE_NAME=$(get_package_name "lazygit")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_lazygit() {
  log info "=== Installing lazygit ==="

  # Check if already installed
  if ! check_installed lazygit; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} via package manager"; then
      return 0
    fi

    # Install via package manager
    log info "Installing ${PACKAGE_NAME}..."
    if pkg_install "${PACKAGE_NAME}"; then
      report_changed "lazygit installed successfully"
    else
      report_failed "Failed to install lazygit"
      return 1
    fi

    # Verify installation
    if ! check_installed lazygit; then
      report_failed "lazygit installation verification failed"
      return 1
    fi
  fi

  # Stow lazygit configuration files
  log info "Applying lazygit configuration..."
  if ! stow_package "lazygit"; then
    report_failed "Failed to apply lazygit configuration"
    return 1
  fi

  # Link lazygit shell configuration into shell.d/
  log info "Configuring lazygit shell integration..."
  if ! link_shell_config "lazygit"; then
    report_failed "Failed to link lazygit shell configuration"
    return 1
  fi

  # Re-stow shell package to include lazygit.sh symlink
  local dotfiles_dir
  dotfiles_dir="$(cd "${SCRIPT_DIR}/../dotfiles" && pwd)"

  if (cd "${dotfiles_dir}" && stow -R --dotfiles -t "${HOME}" shell); then
    report_changed "Applied lazygit shell configuration"
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
install_lazygit
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== lazygit installation complete ==="
  log info "Usage: lg (lazygit), lgr (lazygit at repo root)"
  log info "Restart your terminal or run: source ~/.bashrc"
else
  log error "=== lazygit installation failed ==="
fi

exit "${exit_code}"
