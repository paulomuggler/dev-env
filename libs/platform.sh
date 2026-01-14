#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Platform Abstraction Layer
#
# Provides platform detection and package manager abstraction for multi-platform
# support (macOS, Ubuntu/Debian, Arch Linux).
#
# Design principles:
# - Minimal abstraction - only what we currently use
# - Package name mapping done in install scripts
# - Platform-agnostic package operations
#
# NOTE: This file is sourced by libs/linker.sh - DO NOT source directly
#       Requires utils.sh functions (report_*, log)
# -----------------------------------------------------------------------------

# Cache for platform detection
_PLATFORM_CACHE=""

# -----------------------------------------------------------------------------
# Platform Detection
# -----------------------------------------------------------------------------

# Get current platform (cached)
# Returns: macos, ubuntu, arch, or linux (generic)
get_platform() {
  if [[ -n "$_PLATFORM_CACHE" ]]; then
    echo "$_PLATFORM_CACHE"
    return 0
  fi

  local platform=""
  case "$(uname -s)" in
    Darwin)
      platform="macos"
      ;;
    Linux)
      if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        source /etc/os-release
        case "$ID" in
          ubuntu|debian)
            platform="ubuntu"
            ;;
          arch|manjaro)
            platform="arch"
            ;;
          *)
            platform="linux"
            ;;
        esac
      else
        platform="linux"
      fi
      ;;
    *)
      platform="unknown"
      ;;
  esac

  _PLATFORM_CACHE="$platform"
  echo "$platform"
}

# Platform detection helpers
is_ubuntu() {
  [[ "$(get_platform)" == "ubuntu" ]]
}

is_arch() {
  [[ "$(get_platform)" == "arch" ]]
}

is_supported_platform() {
  local platform
  platform=$(get_platform)
  [[ "$platform" == "macos" || "$platform" == "ubuntu" || "$platform" == "arch" ]]
}

# -----------------------------------------------------------------------------
# Omarchy / Hyprland Detection
# -----------------------------------------------------------------------------

# Check if running Omarchy (Arch + Hyprland + Omarchy marker)
is_omarchy() {
  is_arch && [[ -d "${HOME}/.local/share/omarchy" ]]
}

# Check if running under Wayland
is_wayland() {
  [[ -n "${WAYLAND_DISPLAY:-}" ]] || [[ "${XDG_SESSION_TYPE:-}" == "wayland" ]]
}

# Check if Hyprland is the compositor
is_hyprland() {
  [[ "${XDG_CURRENT_DESKTOP:-}" == "Hyprland" ]] || \
  [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] || \
  command -v hyprctl &>/dev/null && hyprctl version &>/dev/null 2>&1
}

# Get display server type
# Returns: wayland, x11, tty, or unknown
get_display_server() {
  if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    echo "wayland"
  elif [[ -n "${DISPLAY:-}" ]]; then
    echo "x11"
  elif [[ -t 0 ]] && [[ "$(tty)" == /dev/tty* ]]; then
    echo "tty"
  else
    echo "unknown"
  fi
}

# Check if appropriate package manager is available
has_package_manager() {
  case "$(get_platform)" in
    macos)
      check::command_exists brew
      ;;
    ubuntu)
      check::command_exists apt-get
      ;;
    arch)
      check::command_exists pacman
      ;;
    *)
      return 1
      ;;
  esac
}

# -----------------------------------------------------------------------------
# Package Name Mapping
# -----------------------------------------------------------------------------

# Get package name for current platform
# Usage: get_package_name "tool" PACKAGE_NAMES_ARRAY
# Returns tool name if not in array (sane default)
get_package_name() {
  local tool_name="$1"
  local array_name="${2:-}"

  if [[ -z "$array_name" ]]; then
    # No array provided, return default
    echo "$tool_name"
    return 0
  fi

  local platform
  platform=$(get_platform)

  # Try to get from array
  local -n arr="$array_name"
  if [[ -n "${arr[$platform]:-}" ]]; then
    echo "${arr[$platform]}"
  else
    # Not in array, return default
    echo "$tool_name"
  fi
}

# -----------------------------------------------------------------------------
# Package Operations
# -----------------------------------------------------------------------------

# Install package via platform package manager
pkg_install() {
  local package="$1"

  case "$(get_platform)" in
    macos)
      brew install "$package"
      ;;
    ubuntu)
      sudo apt-get install -y "$package"
      ;;
    arch)
      sudo pacman -S --noconfirm "$package"
      ;;
    *)
      log error "Unsupported platform for package installation"
      return 1
      ;;
  esac
}

# Install package from AUR (Arch Linux only)
# Uses yay (Omarchy default) or paru as fallback
aur_install() {
  local package="$1"

  if ! is_arch; then
    log error "AUR packages only available on Arch Linux"
    return 1
  fi

  # Prefer yay (Omarchy default), fall back to paru
  local aur_helper=""
  if check::command_exists yay; then
    aur_helper="yay"
  elif check::command_exists paru; then
    aur_helper="paru"
  else
    log error "No AUR helper found (yay or paru required)"
    return 1
  fi

  log info "Installing ${package} from AUR via ${aur_helper}..."
  "${aur_helper}" -S --noconfirm "$package"
}

# Update package manager cache
pkg_update() {
  case "$(get_platform)" in
    macos)
      brew update
      ;;
    ubuntu)
      sudo apt-get update
      ;;
    arch)
      sudo pacman -Sy
      ;;
    *)
      log error "Unsupported platform for package update"
      return 1
      ;;
  esac
}

# Check if package is installed
pkg_installed() {
  local package="$1"

  case "$(get_platform)" in
    macos)
      brew list --formula | grep -q "^${package}$"
      ;;
    ubuntu)
      dpkg -l "$package" 2>/dev/null | grep -q "^ii"
      ;;
    arch)
      pacman -Q "$package" >/dev/null 2>&1
      ;;
    *)
      return 1
      ;;
  esac
}

# -----------------------------------------------------------------------------
# Validation Functions
# -----------------------------------------------------------------------------

# Validate platform support and package manager availability
# Call this once at the start of install scripts
# Returns: 0 if valid, exits with error if not
validate_platform() {
  # Check if platform is supported
  if ! is_supported_platform; then
    report_failed "Unsupported platform: $(uname -s)"
    log error "Supported platforms: macOS, Ubuntu/Debian, Arch Linux"
    exit 1
  fi

  # Check if package manager is available
  if ! has_package_manager; then
    local platform
    platform=$(get_platform)
    case "$platform" in
      macos)
        report_failed "Homebrew is required but not installed"
        log error "Please run install-homebrew.sh first"
        ;;
      ubuntu)
        report_failed "apt-get not found"
        log error "This script requires Ubuntu/Debian with apt-get"
        ;;
      arch)
        report_failed "pacman not found"
        log error "This script requires Arch Linux with pacman"
        ;;
      *)
        report_failed "No package manager found"
        ;;
    esac
    exit 1
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Export functions for use in sourced scripts
# -----------------------------------------------------------------------------

export -f get_platform
export -f is_ubuntu
export -f is_arch
export -f is_supported_platform
export -f is_omarchy
export -f is_wayland
export -f is_hyprland
export -f get_display_server
export -f has_package_manager
export -f get_package_name
export -f pkg_install
export -f aur_install
export -f pkg_update
export -f pkg_installed
export -f validate_platform
