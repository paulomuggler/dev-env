#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# fzf Installation Script
# Installs fzf (fuzzy finder) and configures it
#
# On macOS: installs via Homebrew
# On Linux: installs from Git (official method) to get latest version
#           Ubuntu/Debian repos ship outdated versions missing --bash flag
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

FZF_GIT_DIR="${HOME}/.fzf"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_fzf() {
  log info "=== Installing fzf ==="

  # Check if already installed with adequate version (0.48+ for --bash)
  if check_installed fzf; then
    local current_ver
    current_ver=$(fzf --version 2>/dev/null | awk '{print $1}')
    if fzf --bash &>/dev/null; then
      report_ok "fzf ${current_ver} already installed"
    else
      log info "fzf ${current_ver} is outdated (need 0.48+ for --bash), upgrading..."
      # Remove apt version if present so git install takes precedence
      if is_ubuntu && pkg_installed fzf; then
        log info "Removing system fzf package..."
        sudo apt-get remove -y fzf &>/dev/null || true
      fi
    fi
  fi

  # Install/update via git on Linux, Homebrew on macOS
  if ! fzf --bash &>/dev/null; then
    if dry_run_report "Would install fzf from git"; then
      return 0
    fi

    if is_macos; then
      local pkg
      pkg=$(get_package_name "fzf")
      log info "Installing ${pkg} via Homebrew..."
      if ! pkg_install "${pkg}"; then
        report_failed "Failed to install fzf"
        return 1
      fi
    else
      # Install from git (official recommended method for Linux)
      if [[ -d "$FZF_GIT_DIR" ]]; then
        log info "Updating fzf from git..."
        (cd "$FZF_GIT_DIR" && git pull) || true
      else
        log info "Cloning fzf from git..."
        git clone --depth 1 https://github.com/junegunn/fzf.git "$FZF_GIT_DIR"
      fi

      # Run fzf install (--bin only installs the binary, no shell config — we manage that)
      if ! "${FZF_GIT_DIR}/install" --bin; then
        report_failed "fzf install script failed"
        return 1
      fi
    fi

    # Verify installation
    if ! check_installed fzf; then
      report_failed "fzf installation verification failed"
      return 1
    fi

    report_changed "fzf $(fzf --version | awk '{print $1}') installed"
  fi

  # Link fzf shell configuration into shell.d/
  log info "Configuring fzf shell integration..."
  if ! link_shell_config "fzf"; then
    report_failed "Failed to link fzf shell configuration"
    return 1
  fi

  # Re-stow shell package to include fzf.sh symlink
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
install_fzf
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== fzf installation complete ==="
  log info "Restart your terminal or run: source ~/.bashrc"
else
  log error "=== fzf installation failed ==="
fi

exit "${exit_code}"
