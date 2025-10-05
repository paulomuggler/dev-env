#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# DevEnv Master Setup Script
#
# Orchestrates the installation of all development environment tools and
# configurations in the correct dependency order.
# -----------------------------------------------------------------------------

set -uo pipefail  # Exit on undefined vars and pipe failures
# Note: We don't use -e (errexit) because we handle errors explicitly
# and want to continue installation even if some tools fail

# Get the directory where this script is located (project root)
PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source utility functions (loads bashlog, bash-utility, colr.sh)
# Note: utils.sh will set SCRIPT_DIR to libs/, so we use PROJECT_ROOT
source "${PROJECT_ROOT}/libs/utils.sh"

# -----------------------------------------------------------------------------
# Configuration
# -----------------------------------------------------------------------------

# Command-line options
AUTO_YES=false

# Track installation results
declare -a SUCCESSFUL_INSTALLS=()
declare -a FAILED_INSTALLS=()
declare -a SKIPPED_INSTALLS=()

# Installation phases
# Each phase contains scripts that must run in order
declare -a PHASE1_FOUNDATION=(
  "install-homebrew.sh"
  "install-stow.sh"
)

declare -a PHASE2_SHELL=(
  "install-shell.sh"
)

declare -a PHASE3_CORE_TOOLS=(
  "install-git.sh"
  "install-starship.sh"
  "install-tmux.sh"
)

declare -a PHASE4_CLI_TOOLS=(
  "install-bat.sh"
  "install-eza.sh"
  "install-fzf.sh"
  "install-zoxide.sh"
  "install-ripgrep.sh"
  "install-fd.sh"
  "install-lazygit.sh"
  "install-yazi.sh"
  "install-bottom.sh"
  "install-gdu.sh"
  "install-htop.sh"
  "install-tree.sh"
  "install-jq.sh"
)

declare -a PHASE5_DEVELOPMENT=(
  "install-nvim.sh"
  "install-lazyllm.sh"
)

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

# Run a single install script
run_install_script() {
  local script_name="$1"
  local script_path="${PROJECT_ROOT}/install-scripts/${script_name}"

  if [[ ! -f "$script_path" ]]; then
    log warn "Script not found: ${script_name}"
    SKIPPED_INSTALLS+=("${script_name} (not found)")
    return 0
  fi

  if [[ ! -x "$script_path" ]]; then
    log error "Script not executable: ${script_name}"
    FAILED_INSTALLS+=("${script_name} (not executable)")
    return 1
  fi

  log info ""
  log info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log info "Running: ${script_name}"
  log info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if bash "$script_path"; then
    SUCCESSFUL_INSTALLS+=("${script_name}")
    log info "✓ ${script_name} completed successfully"
    return 0
  else
    FAILED_INSTALLS+=("${script_name}")
    log error "✗ ${script_name} failed"
    return 1
  fi
}

# Continue to next script even on failure

# Run a phase of installations
run_phase() {
  local phase_name="$1"
  shift
  local scripts=("$@")

  log info ""
  log info "════════════════════════════════════════════════════════════════════"
  log info "  ${phase_name}"
  log info "════════════════════════════════════════════════════════════════════"
  log info ""

  local phase_failed=false

  for script in "${scripts[@]}"; do
    if ! run_install_script "$script"; then
      phase_failed=true
      # Continue to next script even if one fails
      # This allows us to install as much as possible
      log warn "Continuing despite failure..."
    fi
  done

  if [[ "$phase_failed" == "true" ]]; then
    log warn "${phase_name} completed with some failures"
    return 1
  else
    log info "${phase_name} completed successfully"
    return 0
  fi
}

# Print installation summary
print_summary() {
  log info ""
  log info "════════════════════════════════════════════════════════════════════"
  log info "  INSTALLATION SUMMARY"
  log info "════════════════════════════════════════════════════════════════════"
  log info ""

  if [[ ${#SUCCESSFUL_INSTALLS[@]} -gt 0 ]]; then
    log info "✓ Successful (${#SUCCESSFUL_INSTALLS[@]}):"
    for item in "${SUCCESSFUL_INSTALLS[@]}"; do
      log info "  ✓ ${item}"
    done
    log info ""
  fi

  if [[ ${#SKIPPED_INSTALLS[@]} -gt 0 ]]; then
    log warn "⊝ Skipped (${#SKIPPED_INSTALLS[@]}):"
    for item in "${SKIPPED_INSTALLS[@]}"; do
      log warn "  ⊝ ${item}"
    done
    log info ""
  fi

  if [[ ${#FAILED_INSTALLS[@]} -gt 0 ]]; then
    log error "✗ Failed (${#FAILED_INSTALLS[@]}):"
    for item in "${FAILED_INSTALLS[@]}"; do
      log error "  ✗ ${item}"
    done
    log info ""
  fi

  local total=$((${#SUCCESSFUL_INSTALLS[@]} + ${#FAILED_INSTALLS[@]} + ${#SKIPPED_INSTALLS[@]}))
  log info "Total: ${total} installs (${#SUCCESSFUL_INSTALLS[@]} succeeded, ${#FAILED_INSTALLS[@]} failed, ${#SKIPPED_INSTALLS[@]} skipped)"
  log info ""
}

# Print next steps
print_next_steps() {
  log info "════════════════════════════════════════════════════════════════════"
  log info "  NEXT STEPS"
  log info "════════════════════════════════════════════════════════════════════"
  log info ""
  log info "1. Restart your terminal or run:"
  log info "   source ~/.bashrc"
  log info ""
  log info "2. Install yazi Catppuccin flavor (if yazi was installed):"
  log info "   ya pkg add yazi-rs/flavors:catppuccin-mocha"
  log info ""
  log info "3. Test your tools:"
  log info "   lg          # lazygit"
  log info "   y           # yazi"
  log info "   btm         # bottom"
  log info "   nvim        # neovim"
  log info ""
  log info "4. Check Neovim health:"
  log info "   nvim +checkhealth"
  log info ""

  if [[ ${#FAILED_INSTALLS[@]} -gt 0 ]]; then
    log warn "5. Review failed installations and try running them manually:"
    for item in "${FAILED_INSTALLS[@]}"; do
      log warn "   ./install-scripts/${item}"
    done
    log info ""
  fi

  log info "════════════════════════════════════════════════════════════════════"
  log info ""
}

# -----------------------------------------------------------------------------
# Main Installation Flow
# -----------------------------------------------------------------------------

main() {
  log info ""
  log info "╔════════════════════════════════════════════════════════════════════╗"
  log info "║                                                                    ║"
  log info "║              DevEnv - Development Environment Setup               ║"
  log info "║                                                                    ║"
  log info "╚════════════════════════════════════════════════════════════════════╝"
  log info ""
  log info "This script will install and configure your complete development"
  log info "environment with modern CLI tools, shell configurations, and more."
  log info ""
  log info "Installation will proceed in phases:"
  log info "  • Phase 1: Foundation (Homebrew, Stow)"
  log info "  • Phase 2: Shell Configuration"
  log info "  • Phase 3: Core Tools (Git, Starship, Tmux)"
  log info "  • Phase 4: CLI Productivity Tools"
  log info "  • Phase 5: Development Environment (Neovim)"
  log info ""

  # Platform check
  if ! is_macos; then
    log error "This setup currently only supports macOS"
    exit 1
  fi

  log info "Platform: macOS $(sw_vers -productVersion)"
  log info "Installation directory: ${PROJECT_ROOT}"
  log info ""

  # Initialize git submodules
  log info "Initializing git submodules..."
  if (cd "${PROJECT_ROOT}" && git submodule update --init --recursive); then
    log info "✓ Submodules initialized"
  else
    log warn "Failed to initialize submodules, some features may not work"
  fi
  log info ""

  # Confirmation prompt (skip if --yes flag provided)
  if [[ "${AUTO_YES}" != "true" ]]; then
    read -p "Continue with installation? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      log info "Installation cancelled by user"
      exit 0
    fi
  else
    log info "Auto-confirming installation (--yes flag provided)"
  fi

  # Run installation phases
  # Errors are tracked in FAILED_INSTALLS array, so we continue regardless
  run_phase "PHASE 1: Foundation" "${PHASE1_FOUNDATION[@]}"
  run_phase "PHASE 2: Shell Configuration" "${PHASE2_SHELL[@]}"
  run_phase "PHASE 3: Core Tools" "${PHASE3_CORE_TOOLS[@]}"
  run_phase "PHASE 4: CLI Productivity Tools" "${PHASE4_CLI_TOOLS[@]}"
  run_phase "PHASE 5: Development Environment" "${PHASE5_DEVELOPMENT[@]}"

  # Print summary and next steps
  print_summary
  print_next_steps

  # Exit with appropriate code
  if [[ ${#FAILED_INSTALLS[@]} -gt 0 ]]; then
    log warn "Setup completed with some failures"
    exit 1
  else
    log info "🎉 Setup completed successfully!"
    exit 0
  fi
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -y|--yes)
      AUTO_YES=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  -y, --yes    Skip confirmation prompt"
      echo "  -h, --help   Show this help message"
      echo ""
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Run '$0 --help' for usage information"
      exit 1
      ;;
  esac
done

# Allow script to be sourced for testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
