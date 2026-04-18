#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Shell Configuration Installation Script
# Applies Bash shell configuration via stow
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_shell_config() {
  log info "=== Installing Shell Configuration ==="

  # NixOS with home-manager manages .bashrc/.bash_profile - skip stowing
  if is_nixos; then
    log info "NixOS detected - checking shell configuration..."

    # Check if .shell.d is already linked (expected for NixOS setup)
    if [[ -L "${HOME}/.shell.d" ]]; then
      log info "✓ OK: .shell.d already linked (home-manager manages base shell files)"
      report_ok "Shell configuration ready (NixOS/home-manager mode)"
    else
      log warn ".shell.d not found - creating symlink..."
      local dotfiles_dir
      dotfiles_dir="$(cd "${SCRIPT_DIR}/../dotfiles" && pwd)"
      ln -sfn "${dotfiles_dir}/shell/dot-shell.d" "${HOME}/.shell.d"
      report_changed "Created .shell.d symlink"
    fi
    return 0
  fi

  # Stow shell configuration (non-NixOS platforms)
  log info "Applying shell configuration..."
  if ! stow_package "shell"; then
    report_failed "Failed to apply shell configuration"
    return 1
  fi

  # Ensure .bash_path sourcing is set up
  log info "Ensuring .bash_profile sources .bash_path..."
  ensure_bash_path_sourced

  # Check if user has .bash_env for secrets
  if [[ ! -f "${HOME}/.bash_env" ]] && [[ -f "${HOME}/.bash_env.example" ]]; then
    log warn "No .bash_env found. Copy .bash_env.example and add your API keys:"
    log warn "  cp ~/.bash_env.example ~/.bash_env"
    log warn "  # Then edit ~/.bash_env with your actual secrets"
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

# Validate platform and package manager
validate_platform

# Run installation
install_shell_config
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== Shell configuration complete ==="
  log info "Restart your terminal or run: source ~/.bash_profile"
else
  log error "=== Shell configuration failed ==="
fi

exit "${exit_code}"
