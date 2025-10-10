#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Nerd Fonts Installation Script
# Installs FiraCode Nerd Font for terminal use
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# CONFIGURATION
# ============================================================================

FONT_NAME="FiraCode"
NERD_FONT_VERSION="v3.3.0"  # Update this to latest version as needed
DOWNLOAD_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONT_VERSION}/FiraCode.zip"

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

check_font_installed() {
  if command -v fc-list >/dev/null 2>&1; then
    if fc-list | grep -qi "FiraCode Nerd Font"; then
      return 0
    fi
  fi
  return 1
}

install_macos() {
  local fonts_dir="${HOME}/Library/Fonts"
  local temp_dir
  temp_dir=$(mktemp -d)

  log info "Downloading ${FONT_NAME} Nerd Font..."
  if ! curl -fsSL "${DOWNLOAD_URL}" -o "${temp_dir}/FiraCode.zip"; then
    report_failed "Failed to download font"
    rm -rf "${temp_dir}"
    return 1
  fi

  log info "Extracting fonts..."
  if ! unzip -q "${temp_dir}/FiraCode.zip" -d "${temp_dir}/fonts"; then
    report_failed "Failed to extract fonts"
    rm -rf "${temp_dir}"
    return 1
  fi

  log info "Installing fonts to ${fonts_dir}..."
  mkdir -p "${fonts_dir}"

  # Install only .ttf files (skip .otf to avoid duplicates)
  local installed=0
  while IFS= read -r -d '' font_file; do
    cp "${font_file}" "${fonts_dir}/"
    ((installed++))
  done < <(find "${temp_dir}/fonts" -name "*.ttf" -print0)

  rm -rf "${temp_dir}"

  if [[ $installed -gt 0 ]]; then
    report_changed "Installed ${installed} FiraCode Nerd Font variants"
    log info "Fonts installed. Restart your terminal to use them."
    return 0
  else
    report_failed "No font files found in download"
    return 1
  fi
}

install_linux() {
  local fonts_dir="${HOME}/.local/share/fonts/NerdFonts"
  local temp_dir
  temp_dir=$(mktemp -d)

  log info "Downloading ${FONT_NAME} Nerd Font..."
  if ! curl -fsSL "${DOWNLOAD_URL}" -o "${temp_dir}/FiraCode.zip"; then
    report_failed "Failed to download font"
    rm -rf "${temp_dir}"
    return 1
  fi

  log info "Extracting fonts..."
  if ! unzip -q "${temp_dir}/FiraCode.zip" -d "${temp_dir}/fonts"; then
    report_failed "Failed to extract fonts"
    rm -rf "${temp_dir}"
    return 1
  fi

  log info "Installing fonts to ${fonts_dir}..."
  mkdir -p "${fonts_dir}"

  # Install only .ttf files (skip .otf to avoid duplicates)
  local installed=0
  while IFS= read -r -d '' font_file; do
    cp "${font_file}" "${fonts_dir}/"
    ((installed++))
  done < <(find "${temp_dir}/fonts" -name "*.ttf" -print0)

  rm -rf "${temp_dir}"

  if [[ $installed -gt 0 ]]; then
    # Refresh font cache on Linux
    log info "Refreshing font cache..."
    if command -v fc-cache >/dev/null 2>&1; then
      fc-cache -f "${fonts_dir}"
    fi

    report_changed "Installed ${installed} FiraCode Nerd Font variants"
    log info "Fonts installed. Restart your terminal to use them."
    return 0
  else
    report_failed "No font files found in download"
    return 1
  fi
}

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_nerd_fonts() {
  log info "=== Installing FiraCode Nerd Font ==="

  # Check if already installed
  if check_font_installed; then
    report_ok "FiraCode Nerd Font already installed"
    return 0
  fi

  if dry_run_report "Would install FiraCode Nerd Font from GitHub releases"; then
    return 0
  fi

  # Check for required tools
  if ! check::command_exists curl; then
    report_failed "curl is required but not installed"
    return 1
  fi

  if ! check::command_exists unzip; then
    report_failed "unzip is required but not installed"
    log error "Install unzip: brew install unzip (macOS) or apt install unzip (Ubuntu)"
    return 1
  fi

  # Platform-specific installation
  if is_macos; then
    install_macos
  elif is_ubuntu || is_linux; then
    install_linux
  else
    report_failed "Unsupported platform"
    return 1
  fi
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

# Validate platform
validate_platform

# Run installation
install_nerd_fonts
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== FiraCode Nerd Font installation complete ==="
  log info ""
  log info "Configure your terminal to use 'FiraCode Nerd Font':"
  log info "- Terminal.app: Preferences → Profiles → Font"
  log info "- iTerm2: Preferences → Profiles → Text → Font"
  log info "- Alacritty: Edit ~/.config/alacritty/alacritty.yml"
  log info "- tmux: Set in dotfiles/tmux/.config/tmux/tmux.conf"
  log info ""
  log info "Font variants installed:"
  log info "  - FiraCode Nerd Font (Regular, Bold, Medium, Light, etc.)"
  log info "  - FiraCode Nerd Font Mono (for terminals)"
  log info "  - FiraCode Nerd Font Propo (proportional spacing)"
else
  log error "=== FiraCode Nerd Font installation failed ==="
fi

exit "${exit_code}"
