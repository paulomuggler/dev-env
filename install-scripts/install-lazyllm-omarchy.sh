#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Lazy-LLM Installation for Omarchy
#
# Integrates lazy-llm workflow with Omarchy's nvim config (omarchy-nvim).
# This adds lazy-llm's nvim plugins to the existing LazyVim setup without
# replacing Omarchy's configuration.
#
# What this does:
# 1. Initializes lazy-llm submodule
# 2. Runs lazy-llm's own install.sh, which stows its nvim plugins into
#    ~/.config/nvim/lua/plugins/ and its scripts into ~/.local/bin
#
# Prerequisites:
# - Omarchy installed
# - tmux installed
# - Node.js installed (for some LLM CLIs)
# -----------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../libs/linker.sh"

# -----------------------------------------------------------------------------
# Initialize lazy-llm Submodule
# -----------------------------------------------------------------------------

init_submodule() {
  log info "=== Initializing lazy-llm Submodule ==="

  local project_root
  project_root="$(cd "${SCRIPT_DIR}/.." && pwd)"
  local submodule_path="${project_root}/external/lazy-llm"

  # Check if submodule needs initialization
  if [[ ! -d "${submodule_path}" ]] || [[ ! -f "${submodule_path}/install.sh" ]]; then
    if dry_run_report "Would initialize lazy-llm submodule"; then
      return 0
    fi

    log info "Cloning lazy-llm submodule..."
    if (cd "${project_root}" && git submodule update --init --recursive external/lazy-llm); then
      report_changed "lazy-llm submodule initialized"
    else
      report_failed "Failed to initialize lazy-llm submodule"
      return 1
    fi
  else
    report_ok "lazy-llm submodule already initialized"
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Run lazy-llm Install Script (if available)
# -----------------------------------------------------------------------------

run_lazyllm_install() {
  log info "=== Running lazy-llm Install Script ==="

  local project_root
  project_root="$(cd "${SCRIPT_DIR}/.." && pwd)"
  local install_script="${project_root}/external/lazy-llm/install.sh"

  if [[ ! -x "${install_script}" ]]; then
    report_failed "lazy-llm install.sh missing or not executable at ${install_script}"
    return 1
  fi

  if dry_run_report "Would run lazy-llm install.sh"; then
    return 0
  fi

  log info "Running lazy-llm/install.sh..."
  if (cd "${project_root}/external/lazy-llm" && ./install.sh); then
    report_changed "lazy-llm install.sh completed"
  else
    log warn "lazy-llm install.sh had issues"
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

log info "============================================"
log info "  Lazy-LLM Integration for Omarchy"
log info "============================================"
log info ""

# Initialize submodule first
init_submodule

# lazy-llm's install.sh owns the symlinking: it is stow-based, and its packages
# (nvim-*-plugin, *-bin) are the authoritative layout.
run_lazyllm_install

exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info ""
  log info "=== Lazy-LLM Integration Complete ==="
  log info ""
  log info "Neovim plugins added to ~/.config/nvim/lua/plugins/"
  log info "Scripts added to ~/.local/bin/"
  log info ""
  log info "Usage:"
  log info "  lazy-llm              # Start lazy-llm workspace"
  log info "  lazy-llm -t claude    # Start with Claude"
  log info "  lazy-llm -t gemini    # Start with Gemini"
  log info ""
  log info "In Neovim, use the configured keybindings to send"
  log info "prompts to the LLM pane."
  log info ""
else
  log error "=== Lazy-LLM Integration Failed ==="
fi

exit "${exit_code}"
