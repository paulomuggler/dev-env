#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# DevEnv Utility Functions
#
# Project-specific utilities that extend included libraries:
# - bashlog (libs/bashlog/): Logging functionality
# - bash-utility (libs/bash-utility/): Bash standard library
#
# This file provides ONLY functions not available in the above libraries.
# -----------------------------------------------------------------------------

# Get script directory
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source bashlog for logging
source "${SCRIPT_DIR}/bashlog/log.sh"

# Source bash-utility for standard library functions
# Source each module with absolute paths
BASH_UTILITY_DIR="${SCRIPT_DIR}/bash-utility"
# shellcheck disable=SC1091,SC1090
for module in "${BASH_UTILITY_DIR}"/src/*.sh; do
    source "${module}"
done

# -----------------------------------------------------------------------------
# State Reporting Functions (Ansible-inspired)
# Using bashlog's built-in colors
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
        log info "[DRY-RUN] $1"
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
# Note: Removes the original file after successful backup
backup_path() {
    local source="$1"
    local backup_dir="$2"

    # Only backup if exists and is NOT a symlink
    if [[ -e "${source}" ]] && [[ ! -L "${source}" ]]; then
        if cp -r "${source}" "${backup_dir}/"; then
            log warn "Backed up ${source} to ${backup_dir}/"
            # Remove original so stow can create symlink
            if rm -rf "${source}"; then
                return 0
            else
                log error "Failed to remove ${source} after backup"
                return 1
            fi
        else
            log error "Failed to backup ${source}"
            return 1
        fi
    fi
    return 0
}

# -----------------------------------------------------------------------------
# Stow Configuration Management
# Handles adopting existing configs or backing up and stowing
# -----------------------------------------------------------------------------

# Apply stow package for a tool
# Usage: stow_package <package_name>
# - If dotfiles/<package>/dot_<file> doesn't exist in repo, use --adopt to import existing config
# - If dotfiles/<package>/dot_<file> exists, backup existing config and stow normally
# Returns: 0 on success, 1 on error
stow_package() {
    local package="$1"
    local dotfiles_dir
    dotfiles_dir="$(cd "${SCRIPT_DIR}/../dotfiles" && pwd)"
    local package_dir="${dotfiles_dir}/${package}"

    if [[ ! -d "${package_dir}" ]]; then
        log warn "Stow package ${package} does not exist at ${package_dir}"
        return 1
    fi

    # Check if we have any config files in the package already
    local has_configs=false
    if [[ -n "$(find "${package_dir}" -name 'dot-*' -type f)" ]]; then
        has_configs=true
    fi

    if ! ${has_configs}; then
        # No configs in repo yet - adopt existing user configs
        if dry_run_report "Would adopt existing configs for ${package} into repo"; then
            return 0
        fi

        log info "No configs found for ${package}, adopting existing user configs..."
        if (cd "${dotfiles_dir}" && stow --dotfiles --target="${HOME}" --adopt "${package}"); then
            report_changed "Adopted existing configs for ${package}"
            return 0
        else
            report_failed "Failed to adopt configs for ${package}"
            return 1
        fi
    else
        # We have configs in repo - check if already stowed, backup if needed, then stow
        if dry_run_report "Would backup existing configs and stow ${package}"; then
            return 0
        fi

        # Check if configs are already properly stowed
        local all_stowed=true
        local needs_backup=false

        while IFS= read -r -d '' config_file; do
            local base_name
            base_name=$(basename "${config_file}")
            # Convert dot- prefix to . for actual filename
            local actual_name=".${base_name#dot-}"
            local user_config="${HOME}/${actual_name}"

            # If config exists and is not a symlink, we need to backup
            if [[ -e "${user_config}" ]] && [[ ! -L "${user_config}" ]]; then
                all_stowed=false
                needs_backup=true
                break
            fi

            # If it's a symlink but doesn't point to our stow package, not fully stowed
            if [[ -L "${user_config}" ]]; then
                local link_target
                link_target=$(readlink "${user_config}")
                # Resolve to absolute path if relative
                if [[ "${link_target}" != /* ]]; then
                    link_target="${HOME}/${link_target}"
                fi
                local expected_target="${package_dir}/${base_name}"
                if [[ "${link_target}" != "${expected_target}" ]]; then
                    all_stowed=false
                fi
            elif [[ ! -e "${user_config}" ]]; then
                # File doesn't exist yet, not stowed
                all_stowed=false
            fi
        done < <(find "${package_dir}" -name 'dot-*' -type f -print0)

        # If already fully stowed, report and return
        if ${all_stowed} && ! ${needs_backup}; then
            # Run stow to verify it's happy with current state
            if (cd "${dotfiles_dir}" && stow --dotfiles --target="${HOME}" "${package}" 2>/dev/null); then
                report_ok "${package} configuration already stowed"
                return 0
            fi
        fi

        # Create backup of any existing configs that aren't symlinks
        if ${needs_backup}; then
            local backup_dir
            backup_dir=$(create_backup_dir)
            local backed_up=false

            while IFS= read -r -d '' config_file; do
                local base_name
                base_name=$(basename "${config_file}")
                local actual_name=".${base_name#dot-}"
                local user_config="${HOME}/${actual_name}"

                if backup_path "${user_config}" "${backup_dir}"; then
                    backed_up=true
                fi
            done < <(find "${package_dir}" -name 'dot-*' -type f -print0)

            if ${backed_up}; then
                log warn "Backed up existing configs to ${backup_dir}"
            fi
        fi

        # Stow the package (target is HOME directory)
        log info "Stowing ${package} configuration..."
        if (cd "${dotfiles_dir}" && stow --dotfiles --target="${HOME}" "${package}"); then
            report_changed "Stowed ${package} configuration"
            return 0
        else
            report_failed "Failed to stow ${package} configuration"
            return 1
        fi
    fi
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
export -f stow_package