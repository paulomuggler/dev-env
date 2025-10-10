# Multi-Platform Support Implementation

## Context

We want to add Ubuntu (and later Arch/Omarchy) support to the dev-env project while keeping a single unified codebase. The approach abstracts platform-specific package installation into utility functions, avoiding the need for separate platform branches.

## Design Decisions

### 1. No Platform Branches (For Now)
- **Single unified branch** with runtime platform detection
- 99% of install scripts just call package manager - easily abstracted
- Dotfile structure identical across platforms (XDG standard)
- Shell configs are portable bash
- Only difference: which package manager to call, and some package names

**When we'd need branches:**
- Significant platform-specific code blocks appearing everywhere
- Completely different installation approaches per platform
- Config file format differences

**Current assessment:** We shouldn't hit these issues. Branch if/when needed.

### 2. Minimal Platform Abstraction Functions

Only what we **currently use** in existing install scripts (in `libs/platform.sh`):

```bash
# Platform detection (expand existing in utils.sh)
get_platform()              # Returns: macos, ubuntu, arch (cached)
is_macos()                  # Existing
is_linux()                  # Existing
is_ubuntu()                 # New
is_arch()                   # New (for future Omarchy support)
is_supported_platform()     # Check if we support this platform
has_package_manager()       # Check if brew/apt/pacman available

# Core package operations (ONLY these - add more later as needed)
pkg_install <package>       # Install single package (dispatch to brew/apt/pacman)
pkg_update                  # Update package cache (apt update, brew update)
pkg_installed <package>     # Check if package is installed

# Package name mapping
get_package_name <tool_name> <ARRAY_NAME>  # Lookup from PACKAGE_NAMES array
                                            # Defaults to tool_name if not in array
```

**No search, no upgrade, no service management yet** - add when needed!

### 3. Package Name Mapping (In Each Install Script)

At the **top of each install script**, declare package names:

```bash
# Package names per platform
declare -A PACKAGE_NAMES=(
  [macos]="bat"
  [ubuntu]="bat"
  [arch]="bat"
)

# Get package name for current platform
PACKAGE_NAME=$(get_package_name "bat" PACKAGE_NAMES)
```

**If package names are the same**, you can omit the array entirely:
```bash
PACKAGE_NAME=$(get_package_name "bat")  # Defaults to "bat" on all platforms
```

**Benefits:**
- ✅ Close to where they're used
- ✅ Easy to find and modify
- ✅ Self-documenting per tool
- ✅ No central file to maintain

### 4. Design Questions - ANSWERED

**Q: Naming convention for get_package_name?**
- **A: Option A** - Array optional, defaults to tool name
  ```bash
  get_package_name "bat" PACKAGE_NAMES  # Returns "bat" if not in array
  get_package_name "bat"                # Always returns "bat" (no array)
  ```

**Q: Platform detection caching?**
- **A: Yes, cache it** - No reason not to, can't see circumstances where this would be an issue

**Q: Error handling for unsupported platforms?**
- **A: Exit immediately** - Unsupported platforms are just that, installation should not proceed

## Standard Install Script Structure

```bash
#!/usr/bin/env bash
# install-scripts/install-<tool>.sh

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../libs/utils.sh"
source "${SCRIPT_DIR}/../libs/platform.sh"

# ============================================================================
# PACKAGE CONFIGURATION
# ============================================================================

# Package names per platform (only declare if different from tool name)
declare -A PACKAGE_NAMES=(
  [macos]="tool-name"
  [ubuntu]="tool-name-ubuntu"
  # [arch]="tool-name"  # Optional: omit if same as default
)

# Get package name for current platform
PACKAGE_NAME=$(get_package_name "tool" PACKAGE_NAMES)

# ============================================================================
# INSTALLATION
# ============================================================================

install_tool() {
  log info "=== Installing tool ==="

  # Check if already installed
  if ! check_installed tool; then
    if dry_run_report "Would install ${PACKAGE_NAME} via package manager"; then
      return 0
    fi

    # Platform-agnostic install!
    log info "Installing ${PACKAGE_NAME}..."
    if pkg_install "${PACKAGE_NAME}"; then
      report_changed "tool installed successfully"
    else
      report_failed "Failed to install tool"
      return 1
    fi

    if ! check_installed tool; then
      report_failed "tool installation verification failed"
      return 1
    fi
  fi

  # Stow configuration (platform-agnostic)
  if ! stow_package "tool"; then
    report_failed "Failed to apply tool configuration"
    return 1
  fi

  # Shell integration (platform-agnostic)
  if ! link_shell_config "tool"; then
    report_failed "Failed to link tool shell configuration"
    return 1
  fi

  # Re-stow shell package
  local dotfiles_dir
  dotfiles_dir="$(cd "${SCRIPT_DIR}/../dotfiles" && pwd)"

  if (cd "${dotfiles_dir}" && stow -R --dotfiles -t "${HOME}" shell); then
    report_changed "Applied tool shell configuration"
  else
    report_failed "Failed to re-stow shell configuration"
    return 1
  fi

  return 0
}

# ============================================================================
# ENTRY POINT
# ============================================================================

# Platform check
if ! is_supported_platform; then
  report_failed "Unsupported platform: $(uname -s)"
  exit 1
fi

# Ensure package manager available
if ! has_package_manager; then
  report_failed "No package manager found. Please install Homebrew (macOS) or run on Ubuntu/Debian"
  exit 1
fi

install_tool
exit $?
```

## Implementation Plan

### Phase 1: Create Platform Layer (libs/platform.sh)

New file: `libs/platform.sh`

```bash
#!/usr/bin/env bash
# libs/platform.sh
# Platform abstraction layer for multi-platform support

# Cache for platform detection
_PLATFORM_CACHE=""

# Get current platform (cached)
get_platform() {
  if [[ -n "$_PLATFORM_CACHE" ]]; then
    echo "$_PLATFORM_CACHE"
    return 0
  fi

  local platform=""
  case "$(uname -s)" in
    Darwin)
      platform="macos"
      ;;
    Linux)
      if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        case "$ID" in
          ubuntu|debian)
            platform="ubuntu"
            ;;
          arch|manjaro)
            platform="arch"
            ;;
          *)
            platform="linux"
            ;;
        esac
      else
        platform="linux"
      fi
      ;;
    *)
      platform="unknown"
      ;;
  esac

  _PLATFORM_CACHE="$platform"
  echo "$platform"
}

# Platform detection helpers
is_ubuntu() {
  [[ "$(get_platform)" == "ubuntu" ]]
}

is_arch() {
  [[ "$(get_platform)" == "arch" ]]
}

is_supported_platform() {
  local platform
  platform=$(get_platform)
  [[ "$platform" == "macos" || "$platform" == "ubuntu" || "$platform" == "arch" ]]
}

has_package_manager() {
  case "$(get_platform)" in
    macos)
      check::command_exists brew
      ;;
    ubuntu)
      check::command_exists apt-get
      ;;
    arch)
      check::command_exists pacman
      ;;
    *)
      return 1
      ;;
  esac
}

# Get package name for current platform
# Usage: get_package_name "tool" PACKAGE_NAMES_ARRAY
# Returns tool name if not in array (sane default)
get_package_name() {
  local tool_name="$1"
  local array_name="${2:-}"

  if [[ -z "$array_name" ]]; then
    # No array provided, return default
    echo "$tool_name"
    return 0
  fi

  local platform
  platform=$(get_platform)

  # Try to get from array
  local -n arr="$array_name"
  if [[ -v "arr[$platform]" ]]; then
    echo "${arr[$platform]}"
  else
    # Not in array, return default
    echo "$tool_name"
  fi
}

# Install package via platform package manager
pkg_install() {
  local package="$1"

  case "$(get_platform)" in
    macos)
      brew install "$package"
      ;;
    ubuntu)
      sudo apt-get install -y "$package"
      ;;
    arch)
      sudo pacman -S --noconfirm "$package"
      ;;
    *)
      log error "Unsupported platform for package installation"
      return 1
      ;;
  esac
}

# Update package manager cache
pkg_update() {
  case "$(get_platform)" in
    macos)
      brew update
      ;;
    ubuntu)
      sudo apt-get update
      ;;
    arch)
      sudo pacman -Sy
      ;;
    *)
      log error "Unsupported platform for package update"
      return 1
      ;;
  esac
}

# Check if package is installed
pkg_installed() {
  local package="$1"

  case "$(get_platform)" in
    macos)
      brew list --formula | grep -q "^${package}$"
      ;;
    ubuntu)
      dpkg -l "$package" 2>/dev/null | grep -q "^ii"
      ;;
    arch)
      pacman -Q "$package" >/dev/null 2>&1
      ;;
    *)
      return 1
      ;;
  esac
}
```

### Phase 2: Refactor One Example (install-bat.sh)

- Add PACKAGE_NAMES declaration
- Replace `brew install` with `pkg_install`
- Replace platform checks with new functions
- Test on macOS
- Verify no regression

### Phase 3: Refactor All Install Scripts

Apply same pattern to all ~20 install scripts:
- `install-bat.sh`
- `install-bottom.sh`
- `install-eza.sh`
- `install-fd.sh`
- `install-fzf.sh`
- `install-gdu.sh`
- `install-git.sh`
- `install-glow.sh`
- `install-homebrew.sh` (special case - macOS only)
- `install-htop.sh`
- `install-jq.sh`
- `install-lazygit.sh`
- `install-lynx.sh`
- `install-nvim.sh`
- `install-ripgrep.sh`
- `install-shell.sh`
- `install-starship.sh` (special case - curl script, already platform-agnostic)
- `install-stow.sh`
- `install-tmux.sh`
- `install-tree.sh`
- `install-yazi.sh`
- `install-zoxide.sh`

**Scripts that DON'T need refactoring** (already platform-agnostic):
- Tools installed via curl scripts (Starship)
- Tools installed via pip/venv (Neovim Python providers)
- Tools installed via git clone (LazyVim)
- Shell configuration (stow-based)

### Phase 4: Ubuntu Support (Future Session)

- Test on Ubuntu VM
- Fix any edge cases discovered
- Update PACKAGE_NAMES where needed
- Document Ubuntu-specific quirks

### Phase 5: Arch Support (Later)

- Same as Ubuntu phase
- Add pacman logic to platform.sh (already in template)
- Test on Arch/Manjaro VM

## Edge Cases to Handle

### 1. Tools Not in Package Managers

Some tools we install via other means:
- **Starship**: curl script (same across platforms ✅)
- **Neovim Python providers**: pip venv (same across platforms ✅)
- **LazyVim**: git clone (same across platforms ✅)

These scripts **don't need refactoring** - already platform-agnostic!

### 2. Homebrew-Specific Features

We use some brew-specific things:
- `brew bundle` - No apt equivalent
- Cask installs - Linux uses different methods

**Solution:** Keep these in platform.sh conditionals, error gracefully on non-macOS

### 3. macOS-Only Tools

Some tools only make sense on macOS:
- `install-homebrew.sh` - Should check platform and skip on Linux

**Solution:** Add platform check at script entry point, skip with report_skipped

### 4. Package Name Differences

Examples where names differ:
- `fd` (macOS) vs `fd-find` (Ubuntu)
- `bat` (macOS) vs `bat` or `batcat` (Ubuntu - varies by version)

**Solution:** Declare in PACKAGE_NAMES at top of each script

## Testing Strategy

1. **macOS (current)**: Test all refactored scripts still work
2. **Ubuntu VM**: Test full setup.sh run
3. **Arch VM** (later): Test full setup.sh run
4. **CI/CD** (future): GitHub Actions matrix for all platforms

## Platform Support Priority

1. **macOS** - Current platform, fully supported ✅
2. **Ubuntu** - Next priority, implement in Phase 4
3. **Arch/Omarchy** - Future, implement in Phase 5
4. **Other distros** - As needed, add to get_platform() detection

## Success Criteria

- ✅ Single codebase works on macOS and Ubuntu without modification
- ✅ Install scripts are 95%+ platform-agnostic
- ✅ Platform-specific logic isolated to libs/platform.sh
- ✅ No platform branches needed (for now)
- ✅ Easy to add new platform support (add to platform.sh, test, update PACKAGE_NAMES)

## Notes

- Keep the approach minimal and pragmatic
- Add abstraction functions only as needed
- Revisit branch strategy if platform-specific code starts appearing everywhere
- XDG standards (~/.config, ~/.local) should work across all target platforms
- Shell configs are portable bash - no platform differences expected
