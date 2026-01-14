#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Node.js Installation via mise (Omarchy)
#
# Installs Node.js using mise (Omarchy's version manager) and sets up
# npm packages needed for LLM CLI tools.
#
# This is the Omarchy equivalent of install-node.sh (which uses nvm/fnm).
#
# Prerequisites:
# - Omarchy installed (mise included)
# -----------------------------------------------------------------------------

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../libs/linker.sh"

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

# Node.js LTS version to install (20.x required for Gemini CLI)
NODE_VERSION="${NODE_VERSION:-20}"

# Global npm packages to install
NPM_PACKAGES=(
  "neovim"         # Neovim Node.js client
)

# -----------------------------------------------------------------------------
# Install Node.js via mise
# -----------------------------------------------------------------------------

install_node_mise() {
  log info "=== Installing Node.js via mise ==="

  # Check if mise is available
  if ! check::command_exists mise; then
    report_failed "mise not found - is Omarchy installed?"
    return 1
  fi

  # Check if Node is already installed via mise
  if mise list node 2>/dev/null | grep -q "${NODE_VERSION}"; then
    report_ok "Node.js ${NODE_VERSION} already installed via mise"
  else
    if dry_run_report "Would install Node.js ${NODE_VERSION} via mise"; then
      return 0
    fi

    log info "Installing Node.js ${NODE_VERSION} via mise..."
    if mise install "node@${NODE_VERSION}"; then
      report_changed "Node.js ${NODE_VERSION} installed via mise"
    else
      report_failed "Failed to install Node.js via mise"
      return 1
    fi
  fi

  # Set as global default if not already
  local current_global
  current_global=$(mise current node 2>/dev/null || echo "none")

  if [[ "${current_global}" == *"${NODE_VERSION}"* ]]; then
    report_ok "Node.js ${NODE_VERSION} is global default"
  else
    if dry_run_report "Would set Node.js ${NODE_VERSION} as global default"; then
      return 0
    fi

    log info "Setting Node.js ${NODE_VERSION} as global default..."
    if mise use --global "node@${NODE_VERSION}"; then
      report_changed "Node.js ${NODE_VERSION} set as global default"
    else
      log warn "Failed to set global default, but Node is installed"
    fi
  fi

  # Verify node is available
  if check::command_exists node; then
    local version
    version=$(node --version)
    report_ok "Node.js ${version} available"
  else
    log warn "Node not in PATH - you may need to restart shell or run 'mise reshim'"
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Install Global npm Packages
# -----------------------------------------------------------------------------

install_npm_packages() {
  log info "=== Installing npm packages ==="

  # Ensure npm is available
  if ! check::command_exists npm; then
    log warn "npm not available - skipping npm packages"
    log warn "Try: mise reshim && npm --version"
    return 0
  fi

  for pkg in "${NPM_PACKAGES[@]}"; do
    # Check if package is installed globally
    if npm list -g "${pkg}" &>/dev/null; then
      report_ok "npm package ${pkg} already installed"
    else
      if dry_run_report "Would install npm package ${pkg}"; then
        continue
      fi

      log info "Installing npm package ${pkg}..."
      if npm install -g "${pkg}"; then
        report_changed "npm package ${pkg} installed"
      else
        log warn "Failed to install npm package ${pkg}"
      fi
    fi
  done

  return 0
}

# -----------------------------------------------------------------------------
# Reshim mise (ensure binaries are linked)
# -----------------------------------------------------------------------------

reshim_mise() {
  log info "=== Refreshing mise shims ==="

  if dry_run_report "Would run mise reshim"; then
    return 0
  fi

  if mise reshim; then
    report_changed "mise shims refreshed"
  else
    log warn "mise reshim had issues"
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

# Run installation steps
install_node_mise
reshim_mise
install_npm_packages

exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info ""
  log info "=== Node.js Setup Complete ==="
  log info ""

  if check::command_exists node; then
    log info "Node version: $(node --version)"
    log info "npm version:  $(npm --version)"
  fi

  log info ""
  log info "LLM CLI tools can now be installed:"
  log info "  npm install -g @anthropic-ai/claude-code"
  log info "  npm install -g @anthropic-ai/tokenizer"
  log info "  npm install -g @google/generative-ai-cli"
  log info ""
else
  log error "=== Node.js Setup Failed ==="
fi

exit "${exit_code}"
