#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# jq Installation Script
# Installs jq (command-line JSON processor)
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions (loads bashlog, bash-utility)
source "${SCRIPT_DIR}/../libs/utils.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_jq() {
  log info "=== Installing jq ==="

  # Check if already installed
  if ! check_installed jq; then
    # Dry-run check
    if dry_run_report "Would install jq via brew"; then
      return 0
    fi

    # Install via Homebrew
    log info "Installing jq via Homebrew..."
    if brew install jq; then
      report_changed "jq installed successfully"
    else
      report_failed "Failed to install jq via brew"
      return 1
    fi

    # Verify installation
    if ! check_installed jq; then
      report_failed "jq installation verification failed"
      return 1
    fi
  else
    report_ok "jq is already installed ($(jq --version 2>&1 || echo 'version unknown'))"
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
install_jq
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== jq installation complete ==="
  log info "Usage: jq '.' file.json - Pretty-print JSON"
  log info "Common: jq '.key' (extract), jq '.[]' (array), jq -r (raw output)"
else
  log error "=== jq installation failed ==="
fi

exit "${exit_code}"
