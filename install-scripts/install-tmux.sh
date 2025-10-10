#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Tmux Installation Script
# Installs tmux via Homebrew and applies configuration
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (tmux is same across platforms)
PACKAGE_NAME=$(get_package_name "tmux")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_tmux() {
  log info "=== Installing Tmux ==="

  # Check if already installed
  if ! check_installed tmux; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} via package manager"; then
      return 0
    fi

    # Install via package manager
    log info "Installing ${PACKAGE_NAME}..."
    if pkg_install "${PACKAGE_NAME}"; then
      report_changed "Tmux installed successfully"
    else
      report_failed "Failed to install tmux"
      return 1
    fi

    # Verify installation
    if ! check_installed tmux; then
      report_failed "Tmux installation verification failed"
      return 1
    fi
  fi

  # Initialize TPM submodule
  log info "Initializing TPM (Tmux Plugin Manager) submodule..."
  local project_root="$(cd "${SCRIPT_DIR}/.." && pwd)"

  if (cd "${project_root}" && git submodule update --init --recursive dotfiles/tmux/.config/tmux/plugins/tpm); then
    report_changed "TPM submodule initialized"
  else
    log warn "Failed to initialize TPM submodule"
    log warn "You can initialize manually: git submodule update --init --recursive"
  fi

  # Stow tmux configuration (includes TPM)
  log info "Applying tmux configuration..."
  if ! stow_package "tmux"; then
    report_failed "Failed to apply tmux configuration"
    return 1
  fi

  # Link tmux shell configuration into shell.d/
  log info "Configuring tmux shell integration..."
  if ! link_shell_config "tmux"; then
    report_failed "Failed to link tmux shell configuration"
    return 1
  fi

  # Re-stow shell package to include tmux.sh symlink
  # Use stow_package to ensure proper conflict handling
  if ! stow_package "shell"; then
    report_failed "Failed to re-stow shell configuration"
    return 1
  fi

  # Install/Update tmux plugins
  local tpm_path="${HOME}/.config/tmux/plugins/tpm"
  if [[ -d "$tpm_path" ]]; then
    log info "Installing tmux plugins..."
    # Run TPM install script
    if bash "${tpm_path}/bin/install_plugins" 2>&1 | grep -q "Already installed"; then
      log info "✓ OK: Tmux plugins already installed"
    else
      report_changed "Tmux plugins installed"
    fi
  else
    log warn "TPM not found at ${tpm_path}, plugins will need to be installed manually"
    log warn "Inside tmux, press: prefix + I"
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

# Validate platform and package manager
validate_platform

# Run installation
install_tmux
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== Tmux installation complete ==="
  log info ""
  log info "Configuration: ~/.config/tmux/tmux.conf"
  log info "Plugins installed via TPM (Tmux Plugin Manager)"
  log info ""
  log info "Key bindings:"
  log info "  prefix + I        Install/update plugins"
  log info "  prefix + U        Update all plugins"
  log info "  prefix + alt + u  Uninstall plugins not in config"
  log info "  prefix + F        Fuzzy-find windows/panes (tmux-fzf)"
  log info "  prefix + Ctrl-s   Save session (tmux-resurrect)"
  log info "  prefix + Ctrl-r   Restore session (tmux-resurrect)"
  log info ""
  log info "Start tmux: tmux"
else
  log error "=== Tmux installation failed ==="
fi

exit "${exit_code}"
