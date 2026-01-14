#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# NoMachine Installation Script
#
# Installs NoMachine as a backup remote desktop solution.
# NoMachine provides traditional RDP-like remote access, good as a fallback
# when Sunshine/Moonlight has issues.
#
# Prerequisites:
# - Arch Linux / Omarchy
# - yay or paru (AUR helper)
# -----------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../libs/linker.sh"

# -----------------------------------------------------------------------------
# Main Installation
# -----------------------------------------------------------------------------

install_nomachine() {
  log info "=== Installing NoMachine ==="

  # Only supported on Arch
  if ! is_arch; then
    report_skipped "NoMachine installation only supported on Arch Linux"
    return 0
  fi

  # Check if already installed
  if check_installed nxserver.bin "--version" || check::command_exists nxserver; then
    report_ok "NoMachine already installed"
    return 0
  fi

  if dry_run_report "Would install nomachine from AUR"; then
    return 0
  fi

  # Install from AUR
  log info "Installing NoMachine from AUR..."
  if aur_install nomachine; then
    report_changed "NoMachine installed"
  else
    report_failed "Failed to install NoMachine"
    return 1
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Enable NoMachine Service
# -----------------------------------------------------------------------------

enable_service() {
  log info "=== Enabling NoMachine Service ==="

  # NoMachine runs as a system service, not user service
  if systemctl is-enabled nxserver &>/dev/null; then
    report_ok "NoMachine service already enabled"
  else
    if dry_run_report "Would enable NoMachine system service"; then
      return 0
    fi
    log info "Enabling NoMachine service..."
    if sudo systemctl enable nxserver; then
      report_changed "NoMachine service enabled"
    else
      log warn "Failed to enable NoMachine service"
    fi
  fi

  # Start the service
  if systemctl is-active nxserver &>/dev/null; then
    report_ok "NoMachine service already running"
  else
    if dry_run_report "Would start NoMachine service"; then
      return 0
    fi
    log info "Starting NoMachine service..."
    if sudo systemctl start nxserver; then
      report_changed "NoMachine service started"
    else
      log warn "Failed to start NoMachine service"
    fi
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Configure NoMachine for Wayland
# -----------------------------------------------------------------------------

configure_wayland() {
  log info "=== Configuring NoMachine for Wayland ==="

  local nx_config="/usr/NX/etc/server.cfg"

  if [[ ! -f "${nx_config}" ]]; then
    log warn "NoMachine config not found, skipping Wayland configuration"
    return 0
  fi

  # Check if already configured for Wayland
  if grep -q "EnableWayland 1" "${nx_config}" 2>/dev/null; then
    report_ok "NoMachine already configured for Wayland"
    return 0
  fi

  if dry_run_report "Would configure NoMachine for Wayland"; then
    return 0
  fi

  log info "Enabling Wayland support in NoMachine..."

  # Enable Wayland support
  if sudo sed -i 's/#EnableWayland 0/EnableWayland 1/' "${nx_config}" 2>/dev/null; then
    report_changed "Enabled Wayland support"
  else
    log warn "Could not enable Wayland support, may need manual configuration"
  fi

  # Restart to apply changes
  if sudo systemctl restart nxserver; then
    log info "Restarted NoMachine to apply Wayland config"
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

validate_platform

# Run installation steps
install_nomachine
enable_service
configure_wayland

exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info ""
  log info "=== NoMachine Installation Complete ==="
  log info ""
  log info "NoMachine is now running as a system service."
  log info ""
  log info "To connect:"
  log info "  1. Download NoMachine client: https://www.nomachine.com/download"
  log info "  2. Connect to this machine's IP (or Tailscale IP)"
  log info "  3. Login with your system username/password"
  log info ""
  log info "Default port: 4000"
  log info ""
  log info "Note: NoMachine is a backup to Sunshine/Moonlight."
  log info "      For best performance, use Moonlight when possible."
  log info ""
else
  log error "=== NoMachine Installation Failed ==="
fi

exit "${exit_code}"
