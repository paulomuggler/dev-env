#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# pyenv Installation Script
# Installs pyenv (Python version manager) and python-build
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (pyenv is same across platforms)
PACKAGE_NAME=$(get_package_name "pyenv")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_pyenv() {
  log info "=== Installing pyenv ==="

  # Check if already installed
  if ! check_installed pyenv; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} via package manager"; then
      return 0
    fi

    # Install via package manager
    log info "Installing ${PACKAGE_NAME}..."
    if pkg_install "${PACKAGE_NAME}"; then
      report_changed "pyenv installed successfully"
    else
      report_failed "Failed to install pyenv"
      return 1
    fi

    # Verify installation
    if ! check_installed pyenv; then
      report_failed "pyenv installation verification failed"
      return 1
    fi
  else
    local version
    version=$(pyenv --version || echo "version unknown")
    report_ok "pyenv is already installed ($version)"
  fi

  # Initialize pyenv for current shell
  log info "Initializing pyenv..."
  if eval "$(pyenv init -)"; then
    log info "pyenv initialized for current shell"
  fi

  # Stow pyenv configuration if exists
  if [[ -d "${SCRIPT_DIR}/../dotfiles/pyenv" ]]; then
    log info "Applying pyenv configuration..."
    if ! stow_package "pyenv"; then
      log warn "Failed to apply pyenv configuration (non-fatal)"
    fi
  fi

  # Link pyenv shell configuration into shell.d/
  log info "Configuring pyenv shell integration..."
  if ! link_shell_config "pyenv"; then
    report_failed "Failed to link pyenv shell configuration"
    return 1
  fi

  # Re-stow shell package to include pyenv.sh symlink
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
install_pyenv
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== pyenv installation complete ==="
  log info ""
  log info "Next steps:"
  log info "1. Restart your terminal or run: source ~/.bashrc"
  log info "2. Install a Python version: pyenv install 3.12.0"
  log info "3. Set global Python version: pyenv global 3.12.0"
  log info "4. Verify: python --version"
  log info ""
  log info "Common commands:"
  log info "  pyenv install -l       # List available Python versions"
  log info "  pyenv install 3.12.0   # Install specific version"
  log info "  pyenv global 3.12.0    # Set global default"
  log info "  pyenv local 3.12.0     # Set version for current directory"
  log info "  pyenv versions         # List installed versions"
  log info ""
  log info "Build dependencies for compiling Python:"
  log info "  macOS: Xcode Command Line Tools (xcode-select --install)"
  log info "  Ubuntu: build-essential libssl-dev zlib1g-dev libbz2-dev \\"
  log info "          libreadline-dev libsqlite3-dev libffi-dev liblzma-dev"
else
  log error "=== pyenv installation failed ==="
fi

exit "${exit_code}"
