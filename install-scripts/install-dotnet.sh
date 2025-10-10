#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# .NET SDK Installation Script
# Installs .NET SDK (required for C# development and OmniSharp LSP)
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (dotnet is same across platforms)
PACKAGE_NAME=$(get_package_name "dotnet")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_dotnet() {
  log info "=== Installing .NET SDK ==="

  # Check if already installed
  if ! check_installed dotnet; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} via package manager cask"; then
      return 0
    fi

    # Install via Homebrew Cask
    log info "Installing .NET SDK via Homebrew..."
    log warn "This installation requires sudo access. You may be prompted for your password."
    if pkg_install "${PACKAGE_NAME}" dotnet-sdk; then
      report_changed ".NET SDK installed successfully"
    else
      report_failed "Failed to install .NET SDK via brew"
      return 1
    fi

    # Verify installation
    if ! check_installed dotnet; then
      report_failed ".NET SDK installation verification failed"
      return 1
    fi
  fi

  # Display installed version
  local dotnet_version
  dotnet_version=$(dotnet --version 2>/dev/null || echo "unknown")
  log info ".NET SDK version: ${dotnet_version}"

  return 0
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

# Validate platform and package manager
validate_platform

# Run installation
install_dotnet
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== .NET SDK installation complete ==="
  log info ""
  log info "The .NET SDK is now available for:"
  log info "- C# development"
  log info "- OmniSharp LSP server (C# language support in Neovim)"
  log info ""
  log info "Verify installation: dotnet --version"
  log info "Restart your terminal or run: source ~/.bashrc"
else
  log error "=== .NET SDK installation failed ==="
fi

exit "${exit_code}"
