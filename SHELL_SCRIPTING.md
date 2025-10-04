# Shell Scripting Development Guidelines

This document provides guidelines and best practices for developing shell scripts in the DevEnv project.

## Style Guide

### Follow Google Shell Style Guide
Adhere to the **[Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)** for:
- Naming conventions (lowercase with underscores for functions/variables)
- Indentation (2 spaces, no tabs)
- Quoting practices
- Command substitution (`$(command)` not backticks)
- Function declarations
- Error handling patterns

## Testing Strategy

### Use ShellCheck for Linting
**Run [ShellCheck](https://www.shellcheck.net/) regularly** before committing:

```bash
shellcheck install-scripts/*.sh libs/utils.sh
```

**Benefits:**
- Catches common bugs and anti-patterns
- Enforces quoting best practices
- Identifies portability issues

**Consider adding a git pre-commit hook:**
```bash
# .git/hooks/pre-commit
#!/bin/bash
shellcheck install-scripts/*.sh libs/utils.sh || exit 1
```

### Manual Testing Approach
For this project, we prioritize **manual testing** over automated unit tests:

1. **Dry-run mode**: `DRY_RUN=true ./install-scripts/install-tool.sh`
2. **Idempotency test**: Run script twice, verify second run reports "OK"
3. **Real execution**: Test on actual system
4. **Fresh environment**: Periodically test on clean macOS VM

**Why not BATS?** Our use case (personal dev environment setup) benefits more from real integration testing than unit tests. The complexity of mocking brew/stow/system state outweighs the benefits.

## Library Usage Priority

**Always check existing libraries before writing custom code:**

1. **Use library first**: Check bash-utility, bashlog, utils.sh, colr.sh, or other libs under `libs/`
2. **Improve/adapt library**: Implement directly in included libs when feasible; consider contributing upstream
3. **Roll your own**: Only when no suitable baseline exists or adaptation is too cumbersome

### Available Libraries

#### bash-utility (`libs/bash-utility/`)
Comprehensive bash standard library with modules for:
- **String**: `string::trim`, `string::split`, `string::contains`, etc.
- **Array**: `array::join`, `array::contains`, `array::dedupe`, etc.
- **File**: `file::make_temp_dir`, `file::name`, `file::size`, etc.
- **Validation**: `validation::email`, `validation::ipv4`, etc.
- **Check**: `check::command_exists`, `check::is_root`, etc.
- **Date**: `date::now`, `date::epoc`, etc.

**Usage:**
```bash
source "$PROJECT_ROOT/libs/utils.sh"  # This sources bash-utility

# Use namespaced functions
trimmed=$(string::trim "  hello  ")
joined=$(array::join "," "${my_array[@]}")
```

#### bashlog (`libs/bashlog/`)
Logging with severity levels and multiple outputs:
```bash
log info "Installing package..."
log warn "Configuration already exists"
log error "Installation failed"
log debug "Verbose debugging info"  # Only shows if DEBUG=1
```

#### colr.sh (`libs/colr/`)
Advanced terminal colors (256-color support) - use when bashlog's built-in colors aren't sufficient.

#### utils.sh (`libs/utils.sh`)
Project-specific utilities NOT provided by bash-utility:
- **State reporting (Ansible-style)**: `report_changed`, `report_ok`, `report_skipped`, `report_failed` - colored status output
- **Installation validation**: `check_installed` - wraps `check::command_exists` with version reporting
- **Dry-run support**: `is_dry_run`, `dry_run_report` - preview mode for scripts
- **Platform helpers**: `is_macos`, `is_linux`, `get_platform` - convenience wrappers for `os::detect_os`
- **Backup/safety**: `create_backup_dir`, `backup_path` - timestamped backups for existing configs before stowing

All install scripts should source `utils.sh` which automatically loads bash-utility, bashlog, and colr.sh. 

## Function Isolation and Sourcing

### Script-Relative Paths: The Gold Standard

**Always anchor paths to the script's own directory**, not `$PWD`.

**Why?** Relative paths like `. ./lib/helpers.sh` only work when the current directory happens to match the script location. Run from elsewhere and it breaks.

**The pattern:**
```bash
#!/usr/bin/env bash
set -euo pipefail

# Resolve script's directory, following symlinks safely
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# Source relative to script location
# NOTE: shellcheck source path is relative to project root
# shellcheck source=lib/helpers.sh
source "${SCRIPT_DIR}/../lib/helpers.sh"
```

**Benefits:**
- ✅ Location-independent (works from any directory)
- ✅ Portable (no `cd` gymnastics needed)
- ✅ Predictable (paths relative to code layout, not environment)
- ✅ ShellCheck-friendly (`# shellcheck source=...` hints work)

**For project-wide libraries:**
```bash
PROJECT_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
source "${PROJECT_ROOT}/libs/utils.sh"
```

**Anti-patterns (DON'T):**
- ❌ `cd "$(dirname "$0")"` - Mutates working directory, breaks caller context
- ❌ Hardcoded relative paths (`. ../lib.sh`) - Fragile
- ❌ Relying on `$PWD` or `$0` for directory - Unreliable under sourcing/subshells

### Key Takeaway from [Bash Library Practices](https://stackoverflow.com/questions/11369522/how-to-find-or-make-a-bash-utility-script-library)

**Prefer non-subshell sourcing** for utility libraries:
- **DO**: `source lib.sh` - Functions available in current shell
- **DON'T**: `$(lib.sh)` or `./lib.sh` - Runs in subshell, state is lost

**Variable scoping:**
```bash
# Use 'local' in functions to avoid polluting global namespace
my_function() {
    local temp_var="value"  # Only exists within function
    GLOBAL_VAR="value"      # Persists after function returns
}
```

**Export for subprocesses:**
```bash
export -f my_function  # Make function available to child processes
```

## Reference Resources

### Primary References

1. **[Pure Bash Bible](https://github.com/dylanaraps/pure-bash-bible)**
   - Snippets for common tasks using only bash built-ins
   - Use when adding custom functionality to `libs/utils.sh`
   - Avoid external commands when bash built-ins suffice

2. **[Bash Guide (Wooledge)](http://mywiki.wooledge.org/BashGuide)**
   - Comprehensive bash tutorial and reference
   - Explains bash concepts thoroughly
   - Good for understanding "why" behind best practices

3. **[Bash Pitfalls (Wooledge)](http://mywiki.wooledge.org/BashPitfalls)**
   - **Read this!** Common mistakes and anti-patterns
   - Learn what NOT to do
   - Reference when debugging strange behavior

### Quick Reference Examples

**String manipulation (Pure Bash):**
```bash
# Remove prefix
${var#prefix}

# Remove suffix
${var%suffix}

# Replace first occurrence
${var/pattern/replacement}

# Replace all occurrences
${var//pattern/replacement}

# Default value
${var:-default}
```

**Array handling:**
```bash
# Array length
${#array[@]}

# Iterate array
for item in "${array[@]}"; do
    echo "$item"
done

# Check if array contains element (use bash-utility)
if array::contains "value" "${array[@]}"; then
    echo "Found"
fi
```

## DevEnv-Specific Patterns

### State Reporting
Use consistent state reporting for all operations:

```bash
# Check if already done
if check_installed git; then
    return 0  # Already installed, reports "OK"
fi

# Report changes
if brew install git; then
    report_changed "Git installed successfully"
else
    report_failed "Failed to install git"
    return 1
fi
```

### Dry-Run Support
Always check dry-run mode before making changes:

```bash
if dry_run_report "Would install neovim via brew"; then
    return 0
fi

# Actual installation logic here
```

### Platform Detection
Use utility functions for platform checks:

```bash
if ! is_macos; then
    report_failed "This script only supports macOS"
    exit 1
fi
```

## Common Pitfalls to Avoid

1. **Unquoted variables**: Always quote: `"${var}"` not `$var` (braces optional but recommended)
2. **Word splitting**: Use arrays for lists, not space-separated strings
3. **`[` vs `[[`**: Prefer `[[` for conditionals (more features, fewer gotchas)
4. **`-a` and `-o`**: Don't use in `[` - use `&&` and `||` with `[[`
5. **Command substitution in quotes**: `"$(command)"` preserves whitespace
6. **Exit codes**: Check with `$?` immediately after command
7. **Arithmetic**: Use `(( ... ))` for arithmetic operations: `(( i++ ))` or `if (( count > 10 )); then`

## Debugging Techniques

### Enable Bash Debugging
```bash
set -x  # Print commands as they execute
set -e  # Exit on first error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failures
```

### Use bashlog DEBUG Mode
```bash
DEBUG=1 ./install-scripts/install-tool.sh
```

### ShellCheck Integration
```bash
# Install shellcheck via brew
brew install shellcheck

# Run on script
shellcheck -x install-scripts/install-git.sh
```

## Summary: Development Workflow

1. **Plan**: Understand what the script needs to do
2. **Check libraries**: Look in bash-utility, Pure Bash Bible for existing solutions
3. **Write**: Follow Google Style Guide, use library functions
4. **Lint**: Run ShellCheck before testing
5. **Test**: Dry-run → Manual test → Idempotency test
6. **Review**: Check against Bash Pitfalls
7. **Commit**: Ensure ShellCheck passes

**Remember**: Look for existing → improve existing → roll your own
