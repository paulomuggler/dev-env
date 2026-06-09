#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Mosh Installation Script
# Installs mosh (mobile shell) -- a UDP-based remote shell that survives
# roaming, intermittent connectivity, and high latency better than ssh.
# The single `mosh` package provides both the client (`mosh`) and the server
# (`mosh-server`) binaries.
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package name is `mosh` across all supported platforms.
PACKAGE_NAME=$(get_package_name "mosh")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_mosh() {
  log info "=== Installing mosh ==="

  # Check if already installed (presence of both client and server)
  if check_installed mosh && check_installed mosh-server; then
    log info "mosh already installed ($(mosh --version 2>&1 | head -n1))"
    return 0
  fi

  # Dry-run check
  if dry_run_report "Would install ${PACKAGE_NAME} via package manager"; then
    return 0
  fi

  # Install via package manager
  log info "Installing ${PACKAGE_NAME}..."
  if pkg_install "${PACKAGE_NAME}"; then
    report_changed "mosh installed successfully"
  else
    report_failed "Failed to install mosh"
    return 1
  fi

  # Verify both binaries are present
  if ! check_installed mosh; then
    report_failed "mosh client verification failed"
    return 1
  fi
  if ! check_installed mosh-server; then
    report_failed "mosh-server verification failed"
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
install_mosh
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== mosh installation complete ==="
  log info "Client:  mosh user@host"
  log info "Server:  mosh-server starts on demand from the client"
  log info "Note: mosh-server listens on UDP 60000-61000 by default; open"
  log info "      those ports in the firewall on remote hosts you mosh into."
else
  log error "=== mosh installation failed ==="
fi

exit "${exit_code}"
