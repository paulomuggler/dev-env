#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Tilt Installation Script
# Installs Tilt (https://tilt.dev) - a dev environment for Kubernetes
# that makes it easier to develop microservices locally.
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform
declare -A TILT_PACKAGES=(
  [macos]="tilt"
  [arch]="tilt-bin"
  [ubuntu]="tilt"
)

PACKAGE_NAME=$(get_package_name "tilt" "TILT_PACKAGES")

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_tilt() {
  log info "=== Installing Tilt ==="

  # Check if already installed
  if ! check_installed tilt; then
    # Dry-run check
    if dry_run_report "Would install ${PACKAGE_NAME} via package manager"; then
      return 0
    fi

    # Install via package manager (AUR on Arch, brew on macOS)
    log info "Installing ${PACKAGE_NAME}..."
    local install_success=false
    if is_arch; then
      # Use AUR helper for Arch (tilt-bin is in AUR)
      if aur_install "${PACKAGE_NAME}"; then
        install_success=true
      fi
    else
      # Use standard package manager for other platforms
      if pkg_install "${PACKAGE_NAME}"; then
        install_success=true
      fi
    fi

    if [[ "$install_success" == "true" ]]; then
      report_changed "Tilt installed successfully"
    else
      report_failed "Failed to install Tilt"
      return 1
    fi

    # Verify installation
    if ! check_installed tilt; then
      report_failed "Tilt installation verification failed"
      return 1
    fi
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

# Validate platform and package manager
validate_platform

# Run installation
install_tilt
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== Tilt installation complete ==="
  log info "Usage: tilt up, tilt down, tilt logs"
  log info "Docs: https://docs.tilt.dev/"
else
  log error "=== Tilt installation failed ==="
fi

exit "${exit_code}"
