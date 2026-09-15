#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Screenshots Installation Script
#
# Omarchy 4 ships a complete capture stack of its own (omarchy-capture-*: slurp
# region picker with keyboard window selection, editor hand-off, OCR, screen
# recording), so there this only stows the hypr package, whose bindings.lua
# points Ctrl+Shift+4 at that stack. Everywhere else it installs grim +
# flameshot and configures flameshot to use the grim adapter.
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_screenshots() {
  log info "=== Installing screenshot tools ==="

  # This script is Linux-only (grim is Wayland-specific, flameshot on Linux)
  if is_macos; then
    report_skipped "Screenshot tools are Linux-only (macOS has built-in Cmd+Shift+4)"
    return 0
  fi

  # Omarchy has its own capture stack; a second screenshot program would only
  # compete with it. Stow the keybinding and stop.
  if is_omarchy; then
    log info "Omarchy detected - using the native omarchy-capture-* stack"
    if ! stow_package "hypr"; then
      report_failed "Failed to apply Hyprland screenshot configuration"
      return 1
    fi
    report_ok "Ctrl+Shift+4 bound to omarchy-capture-screenshot (hypr/bindings.lua)"
    return 0
  fi

  # Install grim (Wayland screenshot backend)
  if ! check_installed grim; then
    if dry_run_report "Would install grim via package manager"; then
      return 0
    fi

    log info "Installing grim..."
    if pkg_install "grim"; then
      report_changed "grim installed successfully"
    else
      report_failed "Failed to install grim"
      return 1
    fi

    if ! check_installed grim; then
      report_failed "grim installation verification failed"
      return 1
    fi
  fi

  # Install flameshot (interactive screenshot with annotation)
  if ! check_installed flameshot; then
    if dry_run_report "Would install flameshot via package manager"; then
      return 0
    fi

    log info "Installing flameshot..."
    if pkg_install "flameshot"; then
      report_changed "flameshot installed successfully"
    else
      report_failed "Failed to install flameshot"
      return 1
    fi

    if ! check_installed flameshot; then
      report_failed "flameshot installation verification failed"
      return 1
    fi
  fi

  # Ensure screenshots directory exists
  local screenshots_dir="${HOME}/Pictures/Screenshots"
  if [[ ! -d "${screenshots_dir}" ]]; then
    mkdir -p "${screenshots_dir}"
    report_changed "Created ${screenshots_dir}"
  fi

  # Stow flameshot configuration (enables grim adapter for Wayland)
  log info "Applying flameshot configuration..."
  if ! stow_package "flameshot"; then
    report_failed "Failed to apply flameshot configuration"
    return 1
  fi

  # Stow hypr configuration (includes the Ctrl+Shift+4 keybinding)
  if is_hyprland; then
    log info "Applying Hyprland screenshot keybinding (Ctrl+Shift+4)..."
    if ! stow_package "hypr"; then
      report_failed "Failed to apply Hyprland screenshot configuration"
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
install_screenshots
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== Screenshot tools installation complete ==="
  log info "Use Ctrl+Shift+4 to capture screenshots (Hyprland)"
else
  log error "=== Screenshot tools installation failed ==="
fi

exit "${exit_code}"
