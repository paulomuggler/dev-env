#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Tailscale Installation and SSH Lifeline Setup
#
# Configures Tailscale as the secure network layer for remote access.
# Enables Tailscale SSH as a lifeline - always available even if GUI fails.
#
# Features:
# - Secure mesh VPN (no port forwarding needed)
# - Tailscale SSH (works even without local SSH server)
# - Magic DNS for easy hostname access
#
# Prerequisites:
# - Arch Linux / Omarchy
# - Tailscale account (free tier works fine)
# -----------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../libs/linker.sh"

# -----------------------------------------------------------------------------
# Install Tailscale
# -----------------------------------------------------------------------------

install_tailscale() {
  log info "=== Installing Tailscale ==="

  # Check if already installed
  if check_installed tailscale; then
    return 0
  fi

  if dry_run_report "Would install tailscale"; then
    return 0
  fi

  # Install via package manager (available in official repos)
  log info "Installing Tailscale..."
  if pkg_install tailscale; then
    report_changed "Tailscale installed"
  else
    report_failed "Failed to install Tailscale"
    return 1
  fi

  # Verify
  if ! check_installed tailscale; then
    report_failed "Tailscale installation verification failed"
    return 1
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Enable Tailscale Service
# -----------------------------------------------------------------------------

enable_service() {
  log info "=== Enabling Tailscale Service ==="

  if systemctl is-enabled tailscaled &>/dev/null; then
    report_ok "Tailscale service already enabled"
  else
    if dry_run_report "Would enable tailscaled service"; then
      return 0
    fi
    log info "Enabling Tailscale daemon..."
    if sudo systemctl enable tailscaled; then
      report_changed "Tailscale service enabled"
    else
      report_failed "Failed to enable Tailscale service"
      return 1
    fi
  fi

  # Start the service
  if systemctl is-active tailscaled &>/dev/null; then
    report_ok "Tailscale service already running"
  else
    if dry_run_report "Would start tailscaled service"; then
      return 0
    fi
    log info "Starting Tailscale daemon..."
    if sudo systemctl start tailscaled; then
      report_changed "Tailscale service started"
    else
      report_failed "Failed to start Tailscale service"
      return 1
    fi
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Configure Tailscale SSH
# -----------------------------------------------------------------------------

configure_ssh() {
  log info "=== Configuring Tailscale SSH ==="

  # Check current status
  if ! tailscale status &>/dev/null; then
    log warn "Tailscale not connected yet"
    log warn "Run 'tailscale up --ssh' to connect and enable SSH"
    report_skipped "Tailscale not connected"
    return 0
  fi

  # Check if SSH is enabled
  local ssh_status
  ssh_status=$(tailscale status --json | jq -r '.Self.SSHEnabled // false' 2>/dev/null || echo "unknown")

  if [[ "${ssh_status}" == "true" ]]; then
    report_ok "Tailscale SSH already enabled"
  else
    log info "Tailscale SSH not enabled"
    log info "To enable SSH lifeline, run:"
    log info "  tailscale up --ssh"
    log info ""
    log info "This allows SSH access via Tailscale without needing local sshd"
    report_skipped "Tailscale SSH not enabled (run 'tailscale up --ssh')"
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Enable Local SSH (Belt + Suspenders)
# -----------------------------------------------------------------------------

enable_local_ssh() {
  log info "=== Enabling Local SSH Service ==="

  # Even with Tailscale SSH, local sshd provides a backup
  local ssh_service="sshd"

  if ! pkg_installed openssh; then
    if dry_run_report "Would install openssh"; then
      return 0
    fi
    log info "Installing OpenSSH..."
    pkg_install openssh
  fi

  if systemctl is-enabled "${ssh_service}" &>/dev/null; then
    report_ok "Local SSH service already enabled"
  else
    if dry_run_report "Would enable ${ssh_service}"; then
      return 0
    fi
    log info "Enabling local SSH service..."
    if sudo systemctl enable "${ssh_service}"; then
      report_changed "Local SSH service enabled"
    else
      log warn "Failed to enable local SSH"
    fi
  fi

  if systemctl is-active "${ssh_service}" &>/dev/null; then
    report_ok "Local SSH service running"
  else
    if dry_run_report "Would start ${ssh_service}"; then
      return 0
    fi
    log info "Starting local SSH service..."
    if sudo systemctl start "${ssh_service}"; then
      report_changed "Local SSH service started"
    else
      log warn "Failed to start local SSH"
    fi
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Print Connection Info
# -----------------------------------------------------------------------------

print_connection_info() {
  log info ""
  log info "=== Connection Information ==="
  log info ""

  if tailscale status &>/dev/null; then
    local tailscale_ip
    local hostname
    tailscale_ip=$(tailscale ip -4 2>/dev/null || echo "not connected")
    hostname=$(tailscale status --json | jq -r '.Self.DNSName' 2>/dev/null | sed 's/\.$//' || echo "unknown")

    log info "Tailscale IP:    ${tailscale_ip}"
    log info "Tailscale name:  ${hostname}"
    log info ""
    log info "SSH access:"
    log info "  ssh ${USER}@${tailscale_ip}"
    log info "  ssh ${USER}@${hostname}"
  else
    log info "Tailscale not connected."
    log info "Run: tailscale up --ssh"
  fi

  log info ""
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

validate_platform

# Run installation steps
install_tailscale
enable_service
enable_local_ssh
configure_ssh
print_connection_info

exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== Tailscale Setup Complete ==="
  log info ""
  log info "If not already connected, run:"
  log info "  tailscale up --ssh --accept-routes"
  log info ""
  log info "This provides:"
  log info "  - Secure VPN access from anywhere"
  log info "  - Tailscale SSH (no sshd needed)"
  log info "  - Magic DNS (access by hostname)"
  log info ""
  log info "Tailscale SSH is your lifeline if the GUI fails!"
  log info ""
else
  log error "=== Tailscale Setup Failed ==="
fi

exit "${exit_code}"
