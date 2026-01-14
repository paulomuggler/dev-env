#!/usr/bin/env bash
# =============================================================================
# DevEnv Setup for Omarchy (Arch Linux + Hyprland)
# =============================================================================
#
# This script configures dev-env on top of an existing Omarchy installation.
# Omarchy provides the base system; this adds:
#   - tmux + lazy-llm workflow
#   - Additional CLI tools not in Omarchy
#   - LLM CLI tools (claude-code, gemini-cli, etc.)
#   - Remote access stack (Sunshine, NoMachine, Tailscale)
#   - Headless/remote-first configuration
#
# Usage:
#   ./setup-omarchy.sh              # Full setup (interactive)
#   ./setup-omarchy.sh --remote     # Include remote access setup
#   ./setup-omarchy.sh --headless   # Include auto-login + headless config
#   ./setup-omarchy.sh --llm        # Include LLM CLI tools
#   ./setup-omarchy.sh --all        # Everything
#   DRY_RUN=true ./setup-omarchy.sh # Preview without changes
#
# Prerequisites:
#   - Fresh Omarchy installation
#   - Internet connection
#   - User account with sudo access
# =============================================================================

set -uo pipefail

# Get script directory
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Initialize submodules BEFORE sourcing libraries (they depend on submodules)
if [[ ! -f "${SCRIPT_DIR}/libs/bashlog/log.sh" ]]; then
  echo "Initializing git submodules..."
  (cd "${SCRIPT_DIR}" && git submodule update --init --recursive)
fi

# Source libraries
source "${SCRIPT_DIR}/libs/linker.sh"

# =============================================================================
# Configuration
# =============================================================================

# Parse command line flags
SETUP_REMOTE=false
SETUP_HEADLESS=false
SETUP_LLM=false
SKIP_CONFIRM=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --remote)
      SETUP_REMOTE=true
      shift
      ;;
    --headless)
      SETUP_HEADLESS=true
      shift
      ;;
    --llm)
      SETUP_LLM=true
      shift
      ;;
    --all)
      SETUP_REMOTE=true
      SETUP_HEADLESS=true
      SETUP_LLM=true
      shift
      ;;
    -y|--yes)
      SKIP_CONFIRM=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --remote     Include remote access (Sunshine, NoMachine, Tailscale)"
      echo "  --headless   Include auto-login and headless configuration"
      echo "  --llm        Include LLM CLI tools (claude-code, gemini-cli)"
      echo "  --all        All of the above"
      echo "  -y, --yes    Skip confirmation prompts"
      echo "  -h, --help   Show this help"
      echo ""
      echo "Environment:"
      echo "  DRY_RUN=true   Preview changes without executing"
      exit 0
      ;;
    *)
      log error "Unknown option: $1"
      exit 1
      ;;
  esac
done

# =============================================================================
# Result Tracking
# =============================================================================

declare -a SUCCESSFUL_INSTALLS=()
declare -a FAILED_INSTALLS=()
declare -a SKIPPED_INSTALLS=()

# =============================================================================
# Helper Functions
# =============================================================================

run_install_script() {
  local script="$1"
  local script_path="${SCRIPT_DIR}/install-scripts/${script}"

  if [[ ! -f "${script_path}" ]]; then
    log error "Script not found: ${script}"
    FAILED_INSTALLS+=("${script}")
    return 1
  fi

  log info "----------------------------------------"
  log info "Running: ${script}"
  log info "----------------------------------------"

  if bash "${script_path}"; then
    SUCCESSFUL_INSTALLS+=("${script}")
    return 0
  else
    log error "Failed: ${script}"
    FAILED_INSTALLS+=("${script}")
    return 1
  fi
}

run_phase() {
  local phase_name="$1"
  shift
  local scripts=("$@")

  log info ""
  log info "========================================"
  log info "  ${phase_name}"
  log info "========================================"
  log info ""

  for script in "${scripts[@]}"; do
    run_install_script "${script}" || true  # Continue on failure
  done
}

print_summary() {
  log info ""
  log info "========================================"
  log info "  Installation Summary"
  log info "========================================"
  log info ""

  if [[ ${#SUCCESSFUL_INSTALLS[@]} -gt 0 ]]; then
    log info "✓ Successful (${#SUCCESSFUL_INSTALLS[@]}):"
    for item in "${SUCCESSFUL_INSTALLS[@]}"; do
      log info "    ${item}"
    done
  fi

  if [[ ${#SKIPPED_INSTALLS[@]} -gt 0 ]]; then
    log info ""
    log info "⊘ Skipped (${#SKIPPED_INSTALLS[@]}):"
    for item in "${SKIPPED_INSTALLS[@]}"; do
      log info "    ${item}"
    done
  fi

  if [[ ${#FAILED_INSTALLS[@]} -gt 0 ]]; then
    log info ""
    log error "✗ Failed (${#FAILED_INSTALLS[@]}):"
    for item in "${FAILED_INSTALLS[@]}"; do
      log error "    ${item}"
    done
  fi
}

# =============================================================================
# Pre-flight Checks
# =============================================================================

preflight_checks() {
  log info "========================================"
  log info "  Pre-flight Checks"
  log info "========================================"
  log info ""

  # Check we're on Omarchy
  if ! is_omarchy; then
    log error "This script is designed for Omarchy (Arch + Hyprland)"
    log error "Detected platform: $(get_platform)"
    if ! is_arch; then
      log error "Not running on Arch Linux"
      exit 1
    fi
    log warn "Omarchy marker not found, but continuing on Arch..."
  else
    report_ok "Running on Omarchy"
  fi

  # Check for required tools
  local required_tools=("git" "yay")  # stow is installed by the script
  for tool in "${required_tools[@]}"; do
    if check::command_exists "${tool}"; then
      report_ok "${tool} available"
    else
      report_failed "${tool} not found"
      exit 1
    fi
  done

  # Check internet connectivity
  if ping -c 1 archlinux.org &>/dev/null; then
    report_ok "Internet connectivity"
  else
    log warn "Internet check failed (may be firewall)"
  fi

  log info ""
}

# =============================================================================
# Main Setup Phases
# =============================================================================

setup_core() {
  run_phase "Phase 1: Core Tools (Not in Omarchy)" \
    "install-stow.sh" \
    "install-tmux.sh"
}

setup_shell() {
  run_phase "Phase 2: Shell Integration" \
    "install-shell.sh"

  # Stow Omarchy-specific configs
  log info "Applying Omarchy shell integration..."
  if stow_package "omarchy"; then
    report_changed "Omarchy integration stowed"
  else
    log warn "Failed to stow Omarchy integration"
  fi

  # Stow Ghostty config
  log info "Applying Ghostty dropdown config..."
  if stow_package "ghostty"; then
    report_changed "Ghostty config stowed"
  else
    log warn "Failed to stow Ghostty config"
  fi

  # Add devenv-shell.sh sourcing to bashrc
  local bashrc="${HOME}/.bashrc"
  local shell_source="source ~/.config/devenv/devenv-shell.sh"

  if [[ -f "${bashrc}" ]] && grep -qF "devenv-shell.sh" "${bashrc}"; then
    report_ok "Shell integration already in .bashrc"
  else
    if dry_run_report "Would add devenv-shell.sh to .bashrc"; then
      :
    else
      log info "Adding devenv-shell.sh to .bashrc..."
      echo "" >> "${bashrc}"
      echo "# dev-env shell integration" >> "${bashrc}"
      echo "${shell_source}" >> "${bashrc}"
      report_changed "Added shell integration to .bashrc"
    fi
  fi
}

setup_cli_tools() {
  run_phase "Phase 3: Additional CLI Tools" \
    "install-ast-grep.sh" \
    "install-gdu.sh" \
    "install-htop.sh" \
    "install-xh.sh" \
    "install-sd.sh" \
    "install-glow.sh" \
    "install-lynx.sh" \
    "install-xz.sh" \
    "install-zstd.sh" \
    "install-p7zip.sh" \
    "install-unrar.sh"
}

setup_dev_env() {
  run_phase "Phase 4: Development Environment" \
    "install-node-mise.sh" \
    "install-lazyllm-omarchy.sh"
}

setup_llm_tools() {
  run_phase "Phase 5: LLM CLI Tools" \
    "install-claude-code.sh" \
    "install-gemini-cli.sh" \
    "install-grok-cli.sh"
}

setup_remote_access() {
  run_phase "Phase 6: Remote Access Stack" \
    "install-tailscale.sh" \
    "install-sunshine.sh" \
    "install-nomachine.sh"

  # Stow remote configs
  log info "Applying Sunshine configuration..."
  if stow_package "sunshine"; then
    report_changed "Sunshine config stowed"
  else
    log warn "Failed to stow Sunshine config"
  fi
}

setup_headless() {
  run_phase "Phase 7: Headless Configuration" \
    "install-autologin.sh"

  # Add Hyprland remote config sourcing
  local hyprconf="${HOME}/.config/hypr/hyprland.conf"
  local hypr_source="source = ~/.config/hypr/devenv-remote.conf"

  if [[ -f "${hyprconf}" ]] && grep -qF "devenv-remote.conf" "${hyprconf}"; then
    report_ok "Remote config already in hyprland.conf"
  else
    if dry_run_report "Would add devenv-remote.conf to hyprland.conf"; then
      :
    else
      log info "Adding devenv-remote.conf to hyprland.conf..."
      echo "" >> "${hyprconf}"
      echo "# dev-env remote/headless configuration" >> "${hyprconf}"
      echo "${hypr_source}" >> "${hyprconf}"
      report_changed "Added remote config to hyprland.conf"
    fi
  fi
}

# =============================================================================
# Main Entry Point
# =============================================================================

main() {
  log info ""
  log info "╔══════════════════════════════════════════════════════════════╗"
  log info "║        DevEnv Setup for Omarchy                              ║"
  log info "║        Arch Linux + Hyprland Development Environment         ║"
  log info "╚══════════════════════════════════════════════════════════════╝"
  log info ""

  # Show what will be installed
  log info "This will install:"
  log info "  • Core: tmux, stow"
  log info "  • CLI tools: ast-grep, gdu, htop, xh, sd, glow, lynx, compression"
  log info "  • Dev: Node.js (via mise), lazy-llm workflow"
  if ${SETUP_LLM}; then
    log info "  • LLM: claude-code, gemini-cli, grok-cli"
  fi
  if ${SETUP_REMOTE}; then
    log info "  • Remote: Tailscale, Sunshine, NoMachine"
  fi
  if ${SETUP_HEADLESS}; then
    log info "  • Headless: auto-login, virtual display"
  fi
  log info ""

  if is_dry_run; then
    log warn "DRY RUN MODE - No changes will be made"
    log info ""
  fi

  # Confirm unless --yes
  if ! ${SKIP_CONFIRM} && ! is_dry_run; then
    read -p "Continue? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      log info "Aborted."
      exit 0
    fi
  fi

  # Run pre-flight checks
  preflight_checks

  # Ensure all git submodules are up to date (may already be done at script start)
  log info "Ensuring git submodules are initialized..."
  (cd "${SCRIPT_DIR}" && git submodule update --init --recursive) || true

  # Run setup phases
  setup_core
  setup_shell
  setup_cli_tools
  setup_dev_env

  # Optional phases
  if ${SETUP_LLM}; then
    setup_llm_tools
  fi

  if ${SETUP_REMOTE}; then
    setup_remote_access
  fi

  if ${SETUP_HEADLESS}; then
    setup_headless
  fi

  # Print summary
  print_summary

  # Final instructions
  log info ""
  log info "========================================"
  log info "  Next Steps"
  log info "========================================"
  log info ""
  log info "1. Restart your shell or run: source ~/.bashrc"
  log info ""
  log info "2. Start tmux and run lazy-llm:"
  log info "   lazy-llm"
  log info ""

  if ${SETUP_REMOTE}; then
    log info "3. Configure Sunshine (remote access):"
    log info "   - Start: systemctl --user start sunshine"
    log info "   - Web UI: https://localhost:47990"
    log info "   - Set credentials and pair Moonlight client"
    log info ""
  fi

  if ${SETUP_HEADLESS}; then
    log info "4. Test headless setup:"
    log info "   - Reboot to verify auto-login works"
    log info "   - Connect via Moonlight or SSH"
    log info ""
  fi

  # Exit with appropriate code
  if [[ ${#FAILED_INSTALLS[@]} -gt 0 ]]; then
    exit 1
  else
    exit 0
  fi
}

# Run main
main "$@"
