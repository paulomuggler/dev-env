#!/usr/bin/env bash
# =============================================================================
# DevEnv Setup for Ubuntu (e.g., DGX Spark)
# =============================================================================
#
# This script configures dev-env on Ubuntu systems.
# It installs CLI tools, shell configuration, and development environment
# without Arch/Hyprland-specific components.
#
# Usage:
#   ./setup-ubuntu.sh              # Full setup (interactive)
#   ./setup-ubuntu.sh --llm        # Include LLM CLI tools
#   ./setup-ubuntu.sh -y           # Skip confirmation
#   DRY_RUN=true ./setup-ubuntu.sh # Preview without changes
#
# Prerequisites:
#   - Ubuntu 24.04+
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

SETUP_LLM=false
SKIP_CONFIRM=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --llm)
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
      echo "  --llm        Include LLM CLI tools (claude-code, gemini-cli)"
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
    run_install_script "${script}" || true
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

  if ! is_ubuntu; then
    log error "This script is designed for Ubuntu"
    log error "Detected platform: $(get_platform)"
    exit 1
  fi
  report_ok "Running on Ubuntu ($(lsb_release -ds 2>/dev/null || echo 'unknown'))"

  # Check for required tools
  local required_tools=("git" "apt-get")
  for tool in "${required_tools[@]}"; do
    if check::command_exists "${tool}"; then
      report_ok "${tool} available"
    else
      report_failed "${tool} not found"
      exit 1
    fi
  done

  # Check internet connectivity
  if ping -c 1 ubuntu.com &>/dev/null; then
    report_ok "Internet connectivity"
  else
    log warn "Internet check failed (may be firewall)"
  fi

  log info ""
}

# =============================================================================
# Main Setup Phases
# =============================================================================

setup_foundation() {
  run_phase "Phase 1: Foundation" \
    "install-stow.sh"
}

setup_shell() {
  run_phase "Phase 2: Shell Configuration" \
    "install-shell.sh"
}

setup_core_tools() {
  run_phase "Phase 3: Core Tools" \
    "install-git.sh" \
    "install-gh.sh" \
    "install-glab.sh" \
    "install-nerd-fonts.sh" \
    "install-starship.sh" \
    "install-tmux.sh"
}

setup_cli_tools() {
  run_phase "Phase 4: CLI Productivity Tools" \
    "install-bat.sh" \
    "install-eza.sh" \
    "install-fd.sh" \
    "install-ripgrep.sh" \
    "install-sd.sh" \
    "install-dust.sh" \
    "install-duf.sh" \
    "install-xh.sh" \
    "install-fzf.sh" \
    "install-zoxide.sh" \
    "install-lazygit.sh" \
    "install-ast-grep.sh" \
    "install-yazi.sh" \
    "install-bottom.sh" \
    "install-gdu.sh" \
    "install-ncdu.sh" \
    "install-htop.sh" \
    "install-tree.sh" \
    "install-jq.sh" \
    "install-b2.sh" \
    "install-glow.sh" \
    "install-lynx.sh" \
    "install-xz.sh" \
    "install-zstd.sh" \
    "install-p7zip.sh" \
    "install-unrar.sh"
}

setup_dev_env() {
  run_phase "Phase 5: Development Environment" \
    "install-pyenv.sh" \
    "install-node.sh" \
    "install-rbenv.sh" \
    "install-dotnet.sh" \
    "install-nvim.sh" \
    "install-lazyllm.sh"
}

setup_llm_tools() {
  run_phase "Phase 6: LLM CLI Tools" \
    "install-claude-code.sh" \
    "install-gemini-cli.sh" \
    "install-grok-cli.sh" \
    "install-openai-codex.sh"
}

# =============================================================================
# Main Entry Point
# =============================================================================

main() {
  log info ""
  log info "╔══════════════════════════════════════════════════════════════╗"
  log info "║        DevEnv Setup for Ubuntu                               ║"
  log info "║        Development Environment                               ║"
  log info "╚══════════════════════════════════════════════════════════════╝"
  log info ""

  log info "This will install:"
  log info "  • Foundation: stow"
  log info "  • Shell: bash configuration, starship prompt"
  log info "  • Core: git, gh, glab, nerd-fonts, tmux"
  log info "  • CLI tools: bat, eza, fd, ripgrep, fzf, zoxide, lazygit, yazi, ..."
  log info "  • Dev: pyenv, node, rbenv, dotnet, nvim, lazy-llm"
  if ${SETUP_LLM}; then
    log info "  • LLM: claude-code, gemini-cli, grok-cli, openai-codex"
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

  # Ensure all git submodules are up to date
  log info "Ensuring git submodules are initialized..."
  (cd "${SCRIPT_DIR}" && git submodule update --init --recursive) || true

  # Run setup phases
  setup_foundation
  setup_shell
  setup_core_tools
  setup_cli_tools
  setup_dev_env

  # Optional phases
  if ${SETUP_LLM}; then
    setup_llm_tools
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
  log info "2. Start tmux and test your tools:"
  log info "   lg          # lazygit"
  log info "   y           # yazi"
  log info "   btm         # bottom"
  log info "   nvim        # neovim"
  log info ""

  # Exit with appropriate code
  if [[ ${#FAILED_INSTALLS[@]} -gt 0 ]]; then
    exit 1
  else
    exit 0
  fi
}

# Run main
main "$@"
