#!/bin/bash
# -----------------------------------------------------------------------------
# ShellCheck Wrapper
# Runs shellcheck from each script's directory so it can resolve relative paths
# -----------------------------------------------------------------------------

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

errors=0
checked=0

echo "Running shellcheck on all scripts..."
echo

# Check libs/utils.sh from its directory
echo "Checking libs/utils.sh..."
if (cd "${PROJECT_ROOT}/libs" && shellcheck -x utils.sh); then
    echo -e "${GREEN}✓${NC} libs/utils.sh passed"
else
    echo -e "${RED}✗${NC} libs/utils.sh failed"
    ((errors++))
fi
((checked++))
echo

# Check each install script from its directory
for script in "${PROJECT_ROOT}/install-scripts"/*.sh; do
    if [[ ! -f "${script}" ]]; then
        continue
    fi

    script_name="$(basename "${script}")"
    echo "Checking install-scripts/${script_name}..."

    # Run shellcheck from the script's directory so relative paths resolve
    if (cd "$(dirname "${script}")" && shellcheck -x "${script_name}"); then
        echo -e "${GREEN}✓${NC} install-scripts/${script_name} passed"
    else
        echo -e "${RED}✗${NC} install-scripts/${script_name} failed"
        ((errors++))
    fi
    ((checked++))
    echo
done

# Summary
echo "========================================="
if [[ ${errors} -eq 0 ]]; then
    echo -e "${GREEN}✓ All ${checked} scripts passed shellcheck!${NC}"
    exit 0
else
    echo -e "${RED}✗ ${errors} of ${checked} scripts failed${NC}"
    exit 1
fi