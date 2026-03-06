#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Neovim Installation Script
# Installs neovim, language providers, and optional LazyVim dependencies
# -----------------------------------------------------------------------------

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Get the directory where this script is located
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source all libraries (bashlog, bash-utility, utils, platform)
source "${SCRIPT_DIR}/../libs/linker.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Minimum version required for LazyVim
NVIM_MIN_VERSION="0.10.0"

# GitHub release install location (Linux)
NVIM_INSTALL_DIR="${HOME}/.local/nvim"

# -----------------------------------------------------------------------------
# Dependency Check Functions
# -----------------------------------------------------------------------------

check_git_version() {
  local min_version="2.19.0"
  local current_version

  if ! check::command_exists git; then
    log error "Git is not installed"
    return 1
  fi

  current_version=$(git --version | awk '{print $3}')

  if ! printf '%s\n' "$min_version" "$current_version" | sort -V -C; then
    log error "Git version $min_version or higher required. Current: $current_version"
    return 1
  fi

  log info "Git version check passed ($current_version)"
  return 0
}

check_nvim_version() {
  local min_version="${1:-$NVIM_MIN_VERSION}"
  local current_version

  if ! check::command_exists nvim; then
    return 1
  fi

  current_version=$(nvim --version | head -n 1 | sed -E 's/NVIM v([0-9]+\.[0-9]+\.[0-9]+).*/\1/')

  if ! printf '%s\n' "$min_version" "$current_version" | sort -V -C; then
    log warn "Neovim version $min_version or higher required. Current: $current_version"
    return 1
  fi

  return 0
}

check_nerd_font() {
  if ! check::command_exists fc-list; then
    log warn "fontconfig not found, cannot check for Nerd Fonts"
    return 1
  fi

  if ! fc-list | grep -i "Nerd Font" > /dev/null; then
    log warn "Nerd Font not detected. Install from https://www.nerdfonts.com/"
    return 1
  fi

  log info "Nerd Font detected"
  return 0
}

# -----------------------------------------------------------------------------
# Core Installation Functions
# -----------------------------------------------------------------------------

install_neovim() {
  log info "=== Installing Neovim ==="

  # Check git version first
  if ! check_git_version; then
    report_failed "Git version check failed"
    return 1
  fi

  # Check if neovim already installed and meets version requirement
  if check_nvim_version; then
    local version
    version=$(nvim --version | head -n 1)
    report_ok "neovim already installed ($version)"
  else
    if dry_run_report "Would install neovim ${NVIM_MIN_VERSION}+"; then
      return 0
    fi

    if is_macos; then
      # macOS: Homebrew always has a recent version
      local pkg
      pkg=$(get_package_name "neovim")
      log info "Installing ${pkg} via Homebrew..."
      if ! pkg_install "${pkg}"; then
        report_failed "Failed to install neovim"
        return 1
      fi
    else
      # Linux: install from GitHub release (distro packages are outdated)
      install_nvim_from_github || return 1
    fi

    # Verify installation
    if ! check_nvim_version; then
      report_failed "neovim installation verification failed"
      return 1
    fi
  fi

  # Check for Nerd Font (warning only)
  check_nerd_font || true

  return 0
}

# Install neovim from GitHub release tarball (Linux)
install_nvim_from_github() {
  local arch
  arch=$(uname -m)
  local tarball_arch
  case "$arch" in
    x86_64)  tarball_arch="linux-x86_64" ;;
    aarch64) tarball_arch="linux-arm64" ;;
    *)
      report_failed "Unsupported architecture: $arch"
      return 1
      ;;
  esac

  # Get latest release tag
  local latest_tag
  latest_tag=$(curl -fsSL "https://api.github.com/repos/neovim/neovim/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
  if [[ -z "$latest_tag" ]]; then
    report_failed "Failed to fetch latest neovim release"
    return 1
  fi

  local tarball_name="nvim-${tarball_arch}.tar.gz"
  local download_url="https://github.com/neovim/neovim/releases/download/${latest_tag}/${tarball_name}"

  log info "Installing neovim ${latest_tag} for ${arch}..."

  # Remove old apt neovim if present (it's in the way)
  if is_ubuntu && pkg_installed neovim; then
    log info "Removing outdated system neovim package..."
    sudo apt-get remove -y neovim 2>/dev/null || true
  fi

  # Download and extract
  local tmp_dir
  tmp_dir=$(mktemp -d)
  if ! curl -fsSL "$download_url" -o "${tmp_dir}/${tarball_name}"; then
    rm -rf "$tmp_dir"
    report_failed "Failed to download neovim ${latest_tag}"
    return 1
  fi

  # Clean previous install and extract
  rm -rf "$NVIM_INSTALL_DIR"
  mkdir -p "$NVIM_INSTALL_DIR"
  tar -xzf "${tmp_dir}/${tarball_name}" -C "$NVIM_INSTALL_DIR" --strip-components=1
  rm -rf "$tmp_dir"

  # Symlink binary into ~/.local/bin
  mkdir -p "${HOME}/.local/bin"
  ln -sf "${NVIM_INSTALL_DIR}/bin/nvim" "${HOME}/.local/bin/nvim"

  report_changed "neovim ${latest_tag} installed from GitHub release"
}

# -----------------------------------------------------------------------------
# Language Provider Installation Functions
# -----------------------------------------------------------------------------

setup_python_provider() {
  log info "=== Setting up Python provider ==="

  local venv_dir="$HOME/.venvs/nvim"

  if [[ -d "$venv_dir" ]] && [[ -f "$venv_dir/bin/python3" ]]; then
    # Check if pynvim is installed
    if "$venv_dir/bin/python3" -c "import pynvim" 2>/dev/null; then
      report_ok "Python venv already configured with pynvim"
      return 0
    fi
  fi

  if dry_run_report "Would create Python venv at ~/.venvs/nvim"; then
    return 0
  fi

  # On Ubuntu/Debian, ensure python3-venv is installed
  if is_ubuntu; then
    if ! dpkg -l python3-venv 2>/dev/null | grep -q "^ii"; then
      log info "Installing python3-venv package (required on Ubuntu/Debian)..."
      if ! pkg_install "python3-venv"; then
        log error "Failed to install python3-venv"
        log error "Please run: sudo apt install python3-venv"
        return 1
      fi
    fi
  fi

  log info "Creating Python virtual environment..."
  mkdir -p "$HOME/.venvs"

  if ! python3 -m venv "$venv_dir"; then
    report_failed "Failed to create Python venv"
    if is_ubuntu; then
      log error "Try: sudo apt install python3-venv"
    fi
    return 1
  fi

  log info "Installing pynvim..."
  if ! "$venv_dir/bin/pip" install --quiet pynvim; then
    report_failed "Failed to install pynvim"
    return 1
  fi

  report_changed "Python provider configured"
  return 0
}

setup_nodejs_provider() {
  log info "=== Setting up Node.js provider ==="

  if ! check::command_exists npm; then
    log warn "npm not found, skipping Node.js provider"
    report_skipped "Node.js provider (npm not available)"
    return 0
  fi

  # Check if neovim package is installed
  local is_installed=false
  if npm list -g --depth=0 2>/dev/null | grep -q "neovim"; then
    is_installed=true
  fi

  if $is_installed; then
    # Check if it's up to date
    local current_version
    local latest_version
    current_version=$(npm list -g neovim 2>/dev/null | grep neovim@ | sed -E 's/.*neovim@([0-9.]+).*/\1/')
    latest_version=$(npm view neovim version 2>/dev/null)

    if [[ "$current_version" == "$latest_version" ]]; then
      report_ok "Node.js neovim package already up to date ($current_version)"
      return 0
    else
      log info "Node.js neovim package outdated ($current_version -> $latest_version)"
      if dry_run_report "Would update neovim npm package globally"; then
        return 0
      fi
      log info "Updating neovim npm package..."
      if npm install -g neovim; then
        report_changed "Node.js provider updated to $latest_version"
        return 0
      else
        log warn "Failed to update Node.js provider"
        return 0
      fi
    fi
  fi

  if dry_run_report "Would install neovim npm package globally"; then
    return 0
  fi

  log info "Installing neovim npm package..."
  if npm install -g neovim; then
    report_changed "Node.js provider installed"
  else
    log warn "Failed to install Node.js provider"
    report_skipped "Node.js provider (installation failed)"
  fi

  return 0
}

setup_ruby_provider() {
  log info "=== Setting up Ruby provider ==="

  # Check if rbenv is installed
  if ! check::command_exists rbenv; then
    log warn "rbenv not found"
    report_skipped "Ruby provider (rbenv not available - run install-ruby.sh if needed)"
    return 0
  fi

  # Check if neovim gem is installed
  if rbenv exec gem list -i neovim 2>/dev/null | grep -q "true"; then
    report_ok "Ruby neovim gem already installed"
    return 0
  fi

  if dry_run_report "Would install neovim Ruby gem"; then
    return 0
  fi

  log info "Installing neovim Ruby gem..."
  if rbenv exec gem install neovim; then
    report_changed "Ruby provider installed"
  else
    log warn "Failed to install Ruby provider"
    report_skipped "Ruby provider (installation failed)"
  fi

  return 0
}

setup_perl_provider() {
  log info "=== Setting up Perl provider ==="

  if ! check::command_exists cpanm; then
    log warn "cpanm not found"
    report_skipped "Perl provider (cpanminus not available)"
    return 0
  fi

  # Check if Neovim::Ext is installed
  if perl -MNeovim::Ext -e '' 2>/dev/null; then
    report_ok "Perl Neovim::Ext already installed"
    return 0
  fi

  if dry_run_report "Would install Perl Neovim modules"; then
    return 0
  fi

  log info "Installing Perl Neovim modules..."

  # Ensure local::lib is set up
  if [[ ! -d "$HOME/perl5" ]]; then
    log info "Setting up local::lib for Perl..."
    PERL_MM_OPT="INSTALL_BASE=$HOME/perl5" cpanm local::lib
    eval "$(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib=$HOME/perl5)"
  fi

  # Install Neovim Perl modules
  if cpanm MsgPack::Raw && cpanm Neovim::Ext; then
    report_changed "Perl provider installed"
  else
    log warn "Failed to install Perl provider"
    report_skipped "Perl provider (installation failed)"
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Optional LazyVim Dependencies
# -----------------------------------------------------------------------------

install_optional_dependencies() {
  log info "=== Installing optional LazyVim dependencies ==="
  log info "These enhance LazyVim functionality but are not strictly required"

  local tools_to_install=(
    "fish:fish:Shell (required by some LazyVim plugins)"
    "ast-grep:ast-grep:Structural search/replace tool"
    "luarocks:luarocks:Lua package manager"
    "tree-sitter:tree-sitter-cli:Tree-sitter CLI (better syntax highlighting)"
    "go:go:Go language (LSP support)"
    "composer:composer:PHP package manager"
    "php:php:PHP language (LSP support)"
    "rustc:rust:Rust language (LSP support)"
    "java:openjdk:Java (LSP support)"
    "julia:julia:Julia language (LSP support)"
    "ghostscript:ghostscript:Document rendering"
    "tectonic:tectonic:LaTeX engine"
    "fd:fd:Fast file finder"
    "gdu:gdu:Disk usage analyzer"
    "btm:bottom:System monitor"
  )

  local installed_count=0
  local skipped_count=0

  for tool_spec in "${tools_to_install[@]}"; do
    IFS=':' read -r cmd package desc <<< "$tool_spec"

    if check::command_exists "$cmd"; then
      log info "✓ $desc already installed"
      ((skipped_count++))
    else
      if dry_run_report "Would install $package ($desc)"; then
        continue
      fi

      log info "Installing $package ($desc)..."
      if pkg_install "$package" 2>/dev/null; then
        ((installed_count++))
      else
        log warn "Failed to install $package"
      fi
    fi
  done

  # Install mermaid-cli via npm if npm is available
  if check::command_exists npm; then
    if check::command_exists mmdc; then
      log info "✓ Mermaid CLI already installed"
    else
      if ! dry_run_report "Would install @mermaid-js/mermaid-cli"; then
        log info "Installing @mermaid-js/mermaid-cli..."
        npm install -g @mermaid-js/mermaid-cli || log warn "Failed to install mermaid-cli"
      fi
    fi
  fi

  if [[ $installed_count -gt 0 ]]; then
    report_changed "Installed $installed_count optional dependencies"
  else
    report_ok "All optional dependencies already installed"
  fi

  return 0
}

# -----------------------------------------------------------------------------
# Configuration Functions
# -----------------------------------------------------------------------------

configure_nvim_package() {
  log info "=== Configuring Neovim package ==="

  # Stow nvim configuration
  if ! stow_package "nvim"; then
    report_failed "Failed to stow nvim configuration"
    return 1
  fi

  # Link nvim shell configuration into shell.d/
  log info "Configuring nvim shell integration..."
  if ! link_shell_config "nvim"; then
    report_failed "Failed to link nvim shell configuration"
    return 1
  fi

  # Re-stow shell package to include nvim.sh symlink
  # Use stow_package to ensure proper conflict handling
  if ! stow_package "shell"; then
    report_failed "Failed to re-stow shell configuration"
    return 1
  fi

  return 0
}

install_mason_lsp_servers() {
  log info "=== Installing Mason LSP servers ==="
  log info "Mason will auto-install LSP servers when you first open Neovim"
  log info "LSP servers configured: lua_ls, tsserver, pyright, terraformls, ansiblels,"
  log info "  html, cssls, jsonls, yamlls, bashls, omnisharp, clangd, marksman"
  log info ""
  log info "To manually trigger installation, run in Neovim:"
  log info "  :Mason"
  log info "  :MasonInstall <package-name>"

  report_ok "Mason LSP configuration ready (auto-install on first Neovim launch)"
  return 0
}

# -----------------------------------------------------------------------------
# Main Installation Function
# -----------------------------------------------------------------------------

install_nvim_full() {
  # Core installation
  install_neovim || return 1

  # Language providers (core)
  setup_python_provider || return 1
  setup_nodejs_provider || return 1

  # Language providers (optional)
  setup_ruby_provider || true
  setup_perl_provider || true

  # Optional dependencies for LazyVim plugins
  install_optional_dependencies || true

  # Configuration
  configure_nvim_package || return 1

  # Mason LSP servers (informational)
  install_mason_lsp_servers || true

  return 0
}

# -----------------------------------------------------------------------------
# Script Entry Point
# -----------------------------------------------------------------------------

# Validate platform and package manager
validate_platform

# Run installation
install_nvim_full
exit_code=$?

if [[ ${exit_code} -eq 0 ]]; then
  log info "=== Neovim installation complete ==="
  log info ""
  log info "Next steps:"
  log info "1. Restart your terminal or run: source ~/.bashrc"
  log info "2. Run 'nvim' to start LazyVim (plugins will auto-install)"
  log info "3. Run ':checkhealth' in Neovim to verify all providers"
  log info ""
  log info "Additional tools you may want to install:"
  log info "- ripgrep (rg): Fast text search"
  log info "- lazygit: Terminal UI for git"
else
  log error "=== Neovim installation failed ==="
fi

exit "${exit_code}"
