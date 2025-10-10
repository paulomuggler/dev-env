#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Library Linker
#
# Sources all library modules in the correct dependency order:
# 1. bashlog (logging)
# 2. bash-utility (standard library)
# 3. utils.sh (state reporting, common utilities)
# 4. platform.sh (platform abstraction - needs utils.sh functions)
# -----------------------------------------------------------------------------

# Get script directory
LIBS_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# 1. Source bashlog for logging
source "${LIBS_DIR}/bashlog/log.sh"

# 2. Source bash-utility for standard library functions
BASH_UTILITY_DIR="${LIBS_DIR}/bash-utility"
# shellcheck disable=SC1091,SC1090
for module in "${BASH_UTILITY_DIR}"/src/*.sh; do
    source "${module}"
done

# 3. Source utils.sh (provides report_*, check_installed, etc.)
source "${LIBS_DIR}/utils.sh"

# 4. Source platform.sh (provides platform detection and pkg_* functions)
source "${LIBS_DIR}/platform.sh"
