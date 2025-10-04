#!/bin/bash
# -----------------------------------------------------------------------------
# DevEnv Utility Functions
#
# Project-specific utilities that extend included libraries:
# - bashlog (libs/bashlog/): Logging functionality
# - bash-utility (libs/bash-utility/): Bash standard library
# - colr.sh (libs/colr/): Terminal colors
#
# This file provides ONLY functions not available in the above libraries.
# -----------------------------------------------------------------------------

# Get script directory
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source bashlog for logging
source "${SCRIPT_DIR}/bashlog/log.sh"

# Source bash-utility for standard library functions
# Note: bash_utility.sh uses relative paths, must cd into directory
# shellcheck disable=SC1091
(
    cd "${SCRIPT_DIR}/bash-utility" || exit 1
    source bash_utility.sh
) || {
    log error "Failed to source bash-utility library"
    exit 1
}

# Source colr.sh for terminal colors
source "${SCRIPT_DIR}/colr/colr.sh"

# -----------------------------------------------------------------------------
# State Reporting Functions (Ansible-inspired)
# These wrap bashlog with consistent state indicators
# -----------------------------------------------------------------------------

# Report that a change was made (installation, configuration update, etc.)
report_changed() {
    log info "$(colr "✓ CHANGED:" --green) $1"
}

# Report that the desired state already exists
report_ok() {
    log info "$(colr "✓ OK:" --blue) $1"
}

# Report that an operation was intentionally skipped
report_skipped() {
    log warn "$(colr "⊘ SKIPPED:" --yellow) $1"
}

# Report that an operation failed
report_failed() {
    log error "$(colr "✗ FAILED:" --red) $1"
    return 1
}

# -----------------------------------------------------------------------------
# Installation Validation Functions
# These wrap bash-utility with version reporting
# -----------------------------------------------------------------------------

# Check if a tool is installed and report its version
# Usage: check_installed <command> [version_flag]
# Returns: 0 if installed, 1 if not
check_installed() {
    local cmd="$1"
    local version_flag="${2:---version}"

    if check::command_exists "${cmd}"; then
        local version
        version=$("${cmd}" "${version_flag}" 2>&1 | head -n1)
        report_ok "${cmd} already installed (${version})"
        return 0
    else
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Dry-Run Mode Support
# -----------------------------------------------------------------------------

# Check if running in dry-run mode
# Usage: if is_dry_run; then ...; fi
is_dry_run() {
    [[ "${DRY_RUN:-false}" == "true" ]]
}

# Report dry-run action and return success to skip actual execution
# Usage: dry_run_report "Would install neovim" || return
dry_run_report() {
    if is_dry_run; then
        log info "$(colr "[DRY-RUN]" --cyan) $1"
        return 0
    fi
    return 1
}

# -----------------------------------------------------------------------------
# Platform Detection Helpers
# Convenience wrappers around os::detect_os for common checks
# -----------------------------------------------------------------------------

# Check if running on macOS
is_macos() {
    [[ "$(os::detect_os)" == "mac" ]]
}

# Check if running on Linux
is_linux() {
    [[ "$(os::detect_os)" == "linux" ]]
}

# Get platform name (backward compatibility)
get_platform() {
    os::detect_os
}

# -----------------------------------------------------------------------------
# Backup and Safety Functions
# These handle existing config backups before stowing
# -----------------------------------------------------------------------------

# Create a timestamped backup directory
# Usage: backup_dir=$(create_backup_dir)
# Returns: Path to created backup directory
create_backup_dir() {
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="${HOME}/.config_backup_${timestamp}"
    mkdir -p "${backup_dir}"
    echo "${backup_dir}"
}

# Backup a file or directory if it exists and is not a symlink
# Usage: backup_path <source> <backup_dir>
# Returns: 0 if backed up or doesn't exist, 1 on error
backup_path() {
    local source="$1"
    local backup_dir="$2"

    # Only backup if exists and is NOT a symlink
    if [[ -e "${source}" ]] && [[ ! -L "${source}" ]]; then
        if cp -r "${source}" "${backup_dir}/"; then
            log warn "Backed up ${source} to ${backup_dir}/"
            return 0
        else
            log error "Failed to backup ${source}"
            return 1
        fi
    fi
    return 0
}

# -----------------------------------------------------------------------------
# Export functions for use in sourced scripts
# -----------------------------------------------------------------------------

export -f report_changed
export -f report_ok
export -f report_skipped
export -f report_failed
export -f check_installed
export -f is_dry_run
export -f dry_run_report
export -f is_macos
export -f is_linux
export -f get_platform
export -f create_backup_dir
export -f backup_path