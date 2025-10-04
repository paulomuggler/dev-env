#!/bin/bash
# -----------------------------------------------------------------------------
# DevEnv Utility Functions
# Common validation, state reporting, and helper functions for install scripts
#
# This file provides project-specific utilities that leverage:
# - bashlog (libs/bashlog/log.sh): Logging functionality
# - colr.sh (libs/colr/): Terminal colors (when needed beyond bashlog)
# - bash-utility (libs/bash-utility/): Bash standard library functions
# -----------------------------------------------------------------------------

# Get script directory and source libraries
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Source bashlog for logging capabilities
source "${SCRIPT_DIR}/bashlog/log.sh"

# Source bash-utility for standard library functions
# Note: bash_utility.sh uses relative paths, so cd into its directory first
(
    cd "${SCRIPT_DIR}/bash-utility" || exit 1
    source bash_utility.sh
) || {
    log error "Failed to source bash-utility library"
    exit 1
}

# -----------------------------------------------------------------------------
# State Reporting Functions (Ansible-inspired)
# Using bashlog's log function with custom formatting
# -----------------------------------------------------------------------------

# Report that a change was made (installation, configuration update, etc.)
report_changed() {
    log info "✓ CHANGED: $1"
}

# Report that the desired state already exists
report_ok() {
    log info "✓ OK: $1"
}

# Report that an operation was intentionally skipped
report_skipped() {
    log warn "⊘ SKIPPED: $1"
}

# Report that an operation failed
report_failed() {
    log error "✗ FAILED: $1"
    return 1
}

# -----------------------------------------------------------------------------
# Common Validation Functions
# -----------------------------------------------------------------------------

# Check if a command exists in PATH
# Usage: command_exists <command>
# Returns: 0 if exists, 1 if not
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if a tool is installed and return its state
# Usage: check_installed <command> [version_flag]
# Returns: 0 if installed, 1 if not
# Side effect: Reports state via log functions
check_installed() {
    local cmd="$1"
    local version_flag="${2:---version}"

    if command_exists "$cmd"; then
        local version
        version=$($cmd $version_flag 2>&1 | head -n1)
        report_ok "$cmd already installed ($version)"
        return 0
    else
        return 1
    fi
}

# Verify a file or directory exists
# Usage: verify_path <path> <description>
# Returns: 0 if exists, 1 if not
verify_path() {
    local path="$1"
    local desc="$2"

    if [[ -e "$path" ]]; then
        report_ok "$desc exists at $path"
        return 0
    else
        report_failed "$desc not found at $path"
        return 1
    fi
}

# Check if running in dry-run mode
# Usage: if is_dry_run; then ...; fi
is_dry_run() {
    [[ "${DRY_RUN:-false}" == "true" ]]
}

# Report dry-run action
# Usage: dry_run_report "Would install neovim"
dry_run_report() {
    if is_dry_run; then
        log info "[DRY-RUN] $1"
        return 0
    fi
    return 1
}

# -----------------------------------------------------------------------------
# Platform Detection
# -----------------------------------------------------------------------------

# Check if running on macOS
is_macos() {
    [[ "$OSTYPE" == "darwin"* ]]
}

# Check if running on Linux
is_linux() {
    [[ "$OSTYPE" == "linux-gnu"* ]]
}

# Get platform name
get_platform() {
    if is_macos; then
        echo "macos"
    elif is_linux; then
        echo "linux"
    else
        echo "unknown"
    fi
}

# -----------------------------------------------------------------------------
# Backup and Safety Functions
# -----------------------------------------------------------------------------

# Create a timestamped backup directory
# Usage: backup_dir=$(create_backup_dir)
create_backup_dir() {
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$HOME/.config_backup_$timestamp"
    mkdir -p "$backup_dir"
    echo "$backup_dir"
}

# Backup a file or directory
# Usage: backup_path <source> <backup_dir>
backup_path() {
    local source="$1"
    local backup_dir="$2"

    if [[ -e "$source" ]] && [[ ! -L "$source" ]]; then
        cp -r "$source" "$backup_dir/"
        log warn "Backed up $source to $backup_dir/"
        return 0
    fi
    return 1
}

# -----------------------------------------------------------------------------
# Export functions for use in scripts
# -----------------------------------------------------------------------------

export -f report_changed
export -f report_ok
export -f report_skipped
export -f report_failed
export -f command_exists
export -f check_installed
export -f verify_path
export -f is_dry_run
export -f dry_run_report
export -f is_macos
export -f is_linux
export -f get_platform
export -f create_backup_dir
export -f backup_path