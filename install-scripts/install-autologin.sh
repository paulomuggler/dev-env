#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Auto-Login Setup for Headless Omarchy Workstation
#
# Configures TTY1 to auto-login and start Hyprland automatically.
# This enables headless operation - no manual login required after reboot.
#
# What this does:
# 1. Creates systemd override for getty@tty1 to auto-login
# 2. Adds Hyprland auto-start to shell profile (for TTY1 only)
#
# Prerequisites:
# - Omarchy installed
# - User account exists
# -----------------------------------------------------------------------------

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries
source "${SCRIPT_DIR}/../libs/linker.sh"

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

# Get the current user (or allow override)
AUTOLOGIN_USER="${AUTOLOGIN_USER:-$(whoami)}"

# TTY to use for auto-login
AUTOLOGIN_TTY="${AUTOLOGIN_TTY:-tty1}"

# -----------------------------------------------------------------------------
# Setup TTY Auto-Login
# -----------------------------------------------------------------------------

setup_tty_autologin() {
  log info "=== Setting up TTY Auto-Login ==="

  if ! is_arch; then
    report_skipped "TTY auto-login setup only supported on Arch Linux"
    return 0
  fi

  local override_dir="/etc/systemd/system/getty@${AUTOLOGIN_TTY}.service.d"
  local override_file="${override_dir}/autologin.conf"

  # Check if already configured
  if [[ -f "${override_file}" ]]; then
    if grep -q "autologin ${AUTOLOGIN_USER}" "${override_file}"; then
      report_ok "TTY auto-login already configured for ${AUTOLOGIN_USER}"
      return 0
    fi
  fi

  if dry_run_report "Would configure auto-login for ${AUTOLOGIN_USER} on ${AUTOLOGIN_TTY}"; then
    return 0
  fi

  log info "Creating getty override for auto-login..."

  # Create override directory
  sudo mkdir -p "${override_dir}"

  # Create override file
  sudo tee "${override_file}" > /dev/null << EOF
# Auto-login configuration for headless operation
# Created by dev-env install-autologin.sh

[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin ${AUTOLOGIN_USER} --noclear %I \$TERM
EOF

  # Reload systemd
  sudo systemctl daemon-reload

  report_changed "Configured auto-login for ${AUTOLOGIN_USER} on ${AUTOLOGIN_TTY}"
  return 0
}

# -----------------------------------------------------------------------------
# Setup Hyprland Auto-Start
# -----------------------------------------------------------------------------

setup_hyprland_autostart() {
  log info "=== Setting up Hyprland Auto-Start ==="

  local profile_file="${HOME}/.bash_profile"
  local autostart_marker="# dev-env: Hyprland auto-start"

  # Check if already configured
  if [[ -f "${profile_file}" ]] && grep -q "${autostart_marker}" "${profile_file}"; then
    report_ok "Hyprland auto-start already configured"
    return 0
  fi

  if dry_run_report "Would add Hyprland auto-start to ${profile_file}"; then
    return 0
  fi

  log info "Adding Hyprland auto-start to bash profile..."

  # Append auto-start block to .bash_profile
  cat >> "${profile_file}" << 'EOF'

# dev-env: Hyprland auto-start
# Automatically start Hyprland when logging in on TTY1
# This enables headless remote desktop operation
if [[ -z "${WAYLAND_DISPLAY:-}" ]] && [[ "$(tty)" == "/dev/tty1" ]]; then
  # Use uwsm if available (Omarchy default), otherwise direct Hyprland
  if command -v uwsm &>/dev/null; then
    exec uwsm start hyprland-uwsm.desktop
  else
    exec Hyprland
  fi
fi
EOF

  report_changed "Added Hyprland auto-start to ${profile_file}"
  return 0
}

# -----------------------------------------------------------------------------
# Setup Recovery SSH Access
# -----------------------------------------------------------------------------

setup_ssh_recovery() {
  log info "=== Setting up SSH Recovery Access ==="

  # For headless operation, SSH is critical - enable it
  if systemctl is-enabled sshd &>/dev/null || systemctl is-enabled ssh &>/dev/null; then
    report_ok "SSH service already enabled"
  else
    if dry_run_report "Would enable sshd service"; then
      return 0
    fi

    log info "Enabling SSH service for recovery access..."
    if sudo systemctl enable --now sshd; then
      report_changed "SSH service enabled"
    else
      report_failed "Failed to enable SSH service"
      log warn "You may need to install openssh: sudo pacman -S openssh"
    fi
  fi

  # Verify SSH is running
  if systemctl is-active sshd &>/dev/null; then
    report_ok "SSH service is running"
  else
    if ! is_dry_run; then
      log warn "SSH service is not running, attempting to start..."
      sudo systemctl start sshd || true
    fi
  fi

  # Check if Tailscale is available
  if check::command_exists tailscale; then
    if tailscale status &>/dev/null; then
      local tailscale_ip
      tailscale_ip=$(tailscale ip -4 2>/dev/null || echo "unknown")
      report_ok "Tailscale connected (${tailscale_ip})"
    else
      log warn "Tailscale installed but not connected"
      log warn "Connect with: tailscale up"
      report_skipped "Tailscale not connected"
    fi
  else
    log warn "Tailscale not installed"
    log warn "Recommend installing Tailscale for secure remote SSH"
    report_skipped "Tailscale not installed"
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Main Installation
# -----------------------------------------------------------------------------

main() {
  log info "============================================"
  log info "  Headless Auto-Login Setup"
  log info "  User: ${AUTOLOGIN_USER}"
  log info "  TTY:  ${AUTOLOGIN_TTY}"
  log info "============================================"
  log info ""

  # Validate we're on Arch/Omarchy
  if ! is_arch; then
    report_failed "This script is designed for Arch Linux / Omarchy"
    exit 1
  fi

  # Setup auto-login
  setup_tty_autologin

  # Setup Hyprland auto-start
  setup_hyprland_autostart

  # Verify recovery access
  setup_ssh_recovery

  log info ""
  log info "============================================"
  log info "  Setup Complete!"
  log info "============================================"
  log info ""
  log info "After reboot:"
  log info "  1. System will auto-login as ${AUTOLOGIN_USER} on ${AUTOLOGIN_TTY}"
  log info "  2. Hyprland will start automatically"
  log info "  3. Sunshine will start (if enabled)"
  log info ""
  log info "Recovery access:"
  log info "  - SSH: ssh ${AUTOLOGIN_USER}@<tailscale-ip>"
  log info "  - TTY: Switch to another TTY with Ctrl+Alt+F2"
  log info ""

  return 0
}

# Run main
main "$@"
