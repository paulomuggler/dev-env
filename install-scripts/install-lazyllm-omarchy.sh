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
# 2. Symlinks lazy-llm nvim plugins into ~/.config/nvim/lua/plugins/
# 3. Installs lazy-llm tmux scripts
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
# Install lazy-llm Neovim Plugins to Omarchy
# -----------------------------------------------------------------------------

install_nvim_plugins() {
  log info "=== Installing lazy-llm Neovim Plugins ==="

  local project_root
  project_root="$(cd "${SCRIPT_DIR}/.." && pwd)"
  local lazyllm_plugins="${project_root}/external/lazy-llm/lua/plugins"
  local nvim_plugins="${HOME}/.config/nvim/lua/plugins"

  # Ensure lazy-llm has plugins
  if [[ ! -d "${lazyllm_plugins}" ]]; then
    log warn "lazy-llm plugins directory not found"
    log warn "The lazy-llm submodule may have a different structure"
    report_skipped "lazy-llm nvim plugins not found"
    return 0
  fi

  # Ensure nvim plugins directory exists (omarchy-nvim should have this)
  if [[ ! -d "${nvim_plugins}" ]]; then
    log info "Creating nvim plugins directory..."
    mkdir -p "${nvim_plugins}"
  fi

  # List of plugins to link
  local plugins=(
    "llm-send.lua"    # Send prompt to LLM pane
    "git.lua"         # Git integration for lazy-llm
  )

  for plugin in "${plugins[@]}"; do
    local source="${lazyllm_plugins}/${plugin}"
    local target="${nvim_plugins}/lazyllm-${plugin}"

    if [[ ! -f "${source}" ]]; then
      log warn "Plugin ${plugin} not found in lazy-llm"
      continue
    fi

    if [[ -L "${target}" ]] && [[ "$(readlink "${target}")" == "${source}" ]]; then
      report_ok "Plugin ${plugin} already linked"
    elif [[ -e "${target}" ]]; then
      log warn "Plugin ${plugin} exists but is not a symlink to lazy-llm"
      log warn "Backing up and relinking..."
      mv "${target}" "${target}.bak"
      ln -s "${source}" "${target}"
      report_changed "Plugin ${plugin} relinked (backup created)"
    else
      if dry_run_report "Would symlink ${plugin}"; then
        continue
      fi
      ln -s "${source}" "${target}"
      report_changed "Plugin ${plugin} linked"
    fi
  done

  return 0
}

# -----------------------------------------------------------------------------
# Install lazy-llm Scripts
# -----------------------------------------------------------------------------

install_scripts() {
  log info "=== Installing lazy-llm Scripts ==="

  local project_root
  project_root="$(cd "${SCRIPT_DIR}/.." && pwd)"
  local lazyllm_bin="${project_root}/external/lazy-llm/bin"
  local local_bin="${HOME}/.local/bin"

  # Check if lazy-llm has bin directory
  if [[ ! -d "${lazyllm_bin}" ]]; then
    log warn "lazy-llm bin directory not found"
    report_skipped "lazy-llm scripts not found"
    return 0
  fi

  # Ensure local bin exists
  mkdir -p "${local_bin}"

  # Link all scripts from lazy-llm/bin
  for script in "${lazyllm_bin}"/*; do
    if [[ ! -f "${script}" ]]; then
      continue
    fi

    local script_name
    script_name=$(basename "${script}")
    local target="${local_bin}/${script_name}"

    if [[ -L "${target}" ]] && [[ "$(readlink "${target}")" == "${script}" ]]; then
      report_ok "Script ${script_name} already linked"
    elif [[ -e "${target}" ]]; then
      log warn "Script ${script_name} exists, backing up..."
      mv "${target}" "${target}.bak"
      ln -s "${script}" "${target}"
      report_changed "Script ${script_name} relinked"
    else
      if dry_run_report "Would symlink ${script_name}"; then
        continue
      fi
      ln -s "${script}" "${target}"
      report_changed "Script ${script_name} linked"
    fi
  done

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
    log info "No lazy-llm install.sh found or not executable"
    report_skipped "lazy-llm install.sh not available"
    return 0
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

# Install components
install_nvim_plugins
install_scripts
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
