# Homebrew Configuration

Configuration files for Homebrew package manager (macOS only).

## Files

### homebrew.sh
Shell configuration for Homebrew:
- Enables bash completion for brew commands
- Only loaded on macOS systems

## Installation

Installed via `install-scripts/install-homebrew.sh`:
1. Installs Homebrew if not present
2. Adds brew shellenv to `~/.bash_path`
3. Links `homebrew.sh` into `~/.shell.d/`
4. Stows shell package to apply configuration

## Notes

- Homebrew is macOS-specific
- PATH configuration handled in `~/.bash_path`
- Shell integration handled via `~/.shell.d/homebrew.sh`
- Requires `/opt/homebrew/etc/profile.d/bash_completion.sh` to be present
