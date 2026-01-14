#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Sunshine Installation Script
#
# Installs Sunshine GameStream server for low-latency remote desktop.
# Optimized for AMD VAAPI encoding on Arch Linux / Omarchy.
#
# Prerequisites:
# - Arch Linux / Omarchy
# - AMD GPU with VAAPI support (e.g., Radeon 780M)
# - yay or paru (AUR helper)
# -----------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../libs/linker.sh"

# -----------------------------------------------------------------------------
# Main Installation
# -----------------------------------------------------------------------------

install_sunshine() {
  log info "=== Installing Sunshine ==="

  # Only supported on Arch
  if ! is_arch; then
    report_skipped "Sunshine installation only supported on Arch Linux"
    return 0
  fi

  # Check if already installed
  if check_installed sunshine; then
    return 0
  fi

  if dry_run_report "Would install sunshine from AUR"; then
    return 0
  fi

  # Install from AUR (sunshine-bin is pre-built, faster install)
  log info "Installing Sunshine from AUR..."
  if aur_install sunshine; then
    report_changed "Sunshine installed"
  else
    # Fallback to building from source
    log warn "sunshine package failed, trying sunshine-git..."
    if aur_install sunshine-git; then
      report_changed "Sunshine (git) installed"
    else
      report_failed "Failed to install Sunshine"
      return 1
    fi
  fi

  # Verify installation
  if ! check_installed sunshine; then
    report_failed "Sunshine installation verification failed"
    return 1
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Install VAAPI Dependencies
# -----------------------------------------------------------------------------

install_vaapi_deps() {
  log info "=== Installing VAAPI Dependencies ==="

  # AMD VAAPI packages
  local packages=(
    "libva-mesa-driver"   # AMD VAAPI driver
    "mesa-vdpau"          # VDPAU support
    "vulkan-radeon"       # Vulkan for AMD
  )

  for pkg in "${packages[@]}"; do
    if pkg_installed "${pkg}"; then
      report_ok "${pkg} already installed"
    else
      if dry_run_report "Would install ${pkg}"; then
        continue
      fi
      log info "Installing ${pkg}..."
      if pkg_install "${pkg}"; then
        report_changed "${pkg} installed"
      else
        log warn "Failed to install ${pkg}"
      fi
    fi
  done

  return 0
}

# -----------------------------------------------------------------------------
# Configure User Groups
# -----------------------------------------------------------------------------

configure_groups() {
  log info "=== Configuring User Groups ==="

  local user
  user=$(whoami)

  # Groups needed for Sunshine
  local groups=("input" "video" "render")

  for group in "${groups[@]}"; do
    if id -nG "${user}" | grep -qw "${group}"; then
      report_ok "User ${user} already in group ${group}"
    else
      if dry_run_report "Would add ${user} to group ${group}"; then
        continue
      fi
      log info "Adding ${user} to group ${group}..."
      if sudo usermod -aG "${group}" "${user}"; then
        report_changed "Added ${user} to group ${group}"
      else
        log warn "Failed to add ${user} to group ${group}"
      fi
    fi
  done

  return 0
}

# -----------------------------------------------------------------------------
# Apply Configuration
# -----------------------------------------------------------------------------

apply_config() {
  log info "=== Applying Sunshine Configuration ==="

  # Stow sunshine configuration
  if ! stow_package "sunshine"; then
    log warn "Failed to stow Sunshine config (may not exist yet)"
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Enable Systemd Service
# -----------------------------------------------------------------------------

enable_service() {
  log info "=== Enabling Sunshine Service ==="

  # Copy user service if not present
  local service_dir="${HOME}/.config/systemd/user"
  local service_file="${service_dir}/sunshine.service"

  if [[ ! -f "${service_file}" ]]; then
    log info "Systemd service file will be created by stow"
  fi

  # Reload systemd user daemon
  systemctl --user daemon-reload

  # Enable but don't start (need to configure credentials first)
  if systemctl --user is-enabled sunshine &>/dev/null; then
    report_ok "Sunshine service already enabled"
  else
    if dry_run_report "Would enable Sunshine user service"; then
      return 0
    fi
    log info "Enabling Sunshine service..."
    if systemctl --user enable sunshine; then
      report_changed "Sunshine service enabled"
    else
      log warn "Failed to enable Sunshine service"
      log warn "You can enable manually: systemctl --user enable sunshine"
    fi
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

validate_platform

# Run installation steps
install_vaapi_deps
install_sunshine
configure_groups
apply_config
enable_service

exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info ""
  log info "=== Sunshine Installation Complete ==="
  log info ""
  log info "Next steps:"
  log info "  1. Start Sunshine: systemctl --user start sunshine"
  log info "  2. Open web UI: https://localhost:47990"
  log info "  3. Set username and password"
  log info "  4. Pair Moonlight client with PIN"
  log info ""
  log info "NOTE: You may need to log out and back in for group changes"
  log info ""
else
  log error "=== Sunshine Installation Failed ==="
fi

exit "${exit_code}"
