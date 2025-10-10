#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Lazy-LLM Installation Script
# Ensures lazy-llm submodule is available and runs its install script
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_lazyllm() {
  log info "=== Installing Lazy-LLM Tools ==="

  local project_root
  project_root="$(cd "${SCRIPT_DIR}/.." && pwd)"
  local submodule_path="${project_root}/external/lazy-llm"

  # Check if submodule directory exists and is populated
  if [[ ! -d "$submodule_path" ]] || [[ ! -f "$submodule_path/install.sh" ]]; then
    if dry_run_report "Would initialize and clone lazy-llm submodule"; then
      return 0
    fi

    log info "Initializing and cloning lazy-llm submodule..."
    if ! (cd "$project_root" && git submodule update --init --recursive external/lazy-llm); then
      report_failed "Failed to initialize lazy-llm submodule"
      return 1
    fi
    report_changed "Cloned lazy-llm submodule"
  else
    # Update existing submodule
    if dry_run_report "Would update lazy-llm submodule"; then
      return 0
    fi

    log info "Updating lazy-llm submodule..."
    if (cd "$project_root" && git submodule update --remote external/lazy-llm 2>&1 | grep -q "Submodule path"); then
      report_changed "Updated lazy-llm submodule"
    else
      report_ok "lazy-llm submodule already up to date"
    fi
  fi

  # Run the lazy-llm install script
  log info "Running lazy-llm install script..."

  if dry_run_report "Would run lazy-llm/install.sh"; then
    return 0
  fi

  if [[ ! -x "$submodule_path/install.sh" ]]; then
    report_failed "lazy-llm install.sh not found or not executable"
    return 1
  fi

  # Run the install script from the submodule directory
  if (cd "$submodule_path" && ./install.sh); then
    report_changed "Lazy-LLM tools installed"
  else
    report_failed "lazy-llm install.sh failed"
    return 1
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

# Validate platform and package manager
validate_platform

# Ensure git is available (needed for submodule operations)
if ! check::command_exists git; then
  report_failed "Git is required but not installed"
  exit 1
fi

# Run installation
install_lazyllm
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== Lazy-LLM installation complete ==="
  log info ""
  log info "The lazy-llm install script has completed."
  log info "Check output above for any required PATH configuration."
else
  log error "=== Lazy-LLM installation failed ==="
fi

exit "${exit_code}"
