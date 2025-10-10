#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Zstandard Installation Script
# Installs zstd (Zstandard compression - .zst files, modern and fast)
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions (loads bashlog, bash-utility)
source "${SCRIPT_DIR}/../libs/utils.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_zstd() {
  log info "=== Installing zstd ==="

  # Check if already installed
  if ! check_installed zstd; then
    # Dry-run check
    if dry_run_report "Would install zstd via brew"; then
      return 0
    fi

    # Install via Homebrew
    log info "Installing zstd via Homebrew..."
    if brew install zstd; then
      report_changed "zstd installed successfully"
    else
      report_failed "Failed to install zstd via brew"
      return 1
    fi

    # Verify installation
    if ! check_installed zstd; then
      report_failed "zstd installation verification failed"
      return 1
    fi
  else
    local version
    version=$(zstd --version 2>&1 || echo "version unknown")
    report_ok "zstd is already installed ($version)"
  fi

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
install_zstd
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== zstd installation complete ==="
  log info "Usage: zstd file.txt (compress to file.txt.zst)"
  log info "       unzstd file.txt.zst (decompress)"
  log info "       zstd -d file.txt.zst (decompress, keep original)"
else
  log error "=== zstd installation failed ==="
fi

exit "${exit_code}"
