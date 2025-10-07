#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Tmux Installation Script
# Installs tmux via Homebrew and applies configuration
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions (loads bashlog, bash-utility)
source "${SCRIPT_DIR}/../libs/utils.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_tmux() {
  log info "=== Installing Tmux ==="

  # Check if already installed
  if ! check_installed tmux; then
    # Dry-run check
    if dry_run_report "Would install tmux via brew"; then
      return 0
    fi

    # Install via Homebrew
    log info "Installing tmux via Homebrew..."
    if brew install tmux; then
      report_changed "Tmux installed successfully"
    else
      report_failed "Failed to install tmux via brew"
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
  local dotfiles_dir
  dotfiles_dir="$(cd "${SCRIPT_DIR}/../dotfiles" && pwd)"

  if (cd "${dotfiles_dir}" && stow -R --dotfiles -t "${HOME}" shell); then
    report_changed "Applied tmux shell configuration"
  else
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

# Ensure we're on macOS
if ! is_macos; then
  report_failed "This script currently only supports macOS"
  exit 1
fi

# Ensure Homebrew is available
if ! check::command_exists brew; then
  report_failed "Homebrew is required but not installed. Please run install-homebrew.sh first"
  exit 1
fi

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
