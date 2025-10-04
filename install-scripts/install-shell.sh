#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Shell Configuration Installation Script
# Applies Bash shell configuration via stow
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions (loads bashlog, bash-utility)
source "${SCRIPT_DIR}/../libs/utils.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_shell_config() {
  log info "=== Installing Shell Configuration ==="

  # Stow shell configuration
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

# Ensure we're on macOS
if ! is_macos; then
  report_failed "This script currently only supports macOS"
  exit 1
fi

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
