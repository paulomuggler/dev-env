#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# .NET SDK Installation Script
# Installs .NET SDK (required for C# development and OmniSharp LSP)
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions (loads bashlog, bash-utility)
source "${SCRIPT_DIR}/../libs/utils.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_dotnet() {
  log info "=== Installing .NET SDK ==="

  # Check if already installed
  if ! check_installed dotnet; then
    # Dry-run check
    if dry_run_report "Would install dotnet-sdk via brew cask"; then
      return 0
    fi

    # Install via Homebrew Cask
    log info "Installing .NET SDK via Homebrew..."
    log warn "This installation requires sudo access. You may be prompted for your password."
    if brew install --cask dotnet-sdk; then
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
