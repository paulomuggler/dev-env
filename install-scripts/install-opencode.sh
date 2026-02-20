#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# OpenCode Installation Script
# Installs opencode (Open Source AI Software Engineer)
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_opencode() {
  log info "=== Installing opencode ==="

  # Check if already installed
  # We check both PATH and the expected installation directory
  if ! check::command_exists "opencode" && [[ ! -f "$HOME/.opencode/bin/opencode" ]]; then
    # Dry-run check
    if dry_run_report "Would install opencode via curl | bash"; then
      return 0
    fi

    # Install via curl | bash
    log info "Installing opencode..."
    if curl -fsSL https://opencode.ai/install | bash; then
      report_changed "opencode installed successfully"
    else
      report_failed "Failed to install opencode"
      return 1
    fi

    # Verify installation
    if [[ ! -f "$HOME/.opencode/bin/opencode" ]]; then
      report_failed "opencode installation verification failed (binary not found at ~/.opencode/bin/opencode)"
      return 1
    fi
  else
    report_ok "opencode already installed"
  fi

  # Link opencode shell configuration into shell.d/
  log info "Configuring opencode shell integration..."
  if ! link_shell_config "opencode"; then
    report_failed "Failed to link opencode shell configuration"
    return 1
  fi

  # Re-stow shell package to include opencode.sh symlink
  if ! stow_package "shell"; then
    report_failed "Failed to re-stow shell configuration"
    return 1
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

# Run installation
install_opencode
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== opencode installation complete ==="
  log info "Restart your terminal or run: source ~/.bashrc"
else
  log error "=== opencode installation failed ==="
fi

exit "${exit_code}"
