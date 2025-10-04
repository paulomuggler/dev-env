# shell.d/ - Tool-Specific Shell Configuration

This directory contains modular shell configuration files, one per tool. Each file is sourced by `.bashrc` during shell initialization.

## Purpose

Instead of cluttering `.bashrc` or `.bash_aliases` with tool-specific configurations, each tool gets its own file here. This provides:

- **Isolation**: Easy to enable/disable individual tools
- **Clarity**: Clean git diffs, one file per tool
- **Maintainability**: Install scripts can add/update their own config files
- **Organization**: All tool configs in one predictable location

## Naming Convention

Files should be named after the tool: `<tool-name>.sh`

Examples:
- `bat.sh` - bat (cat replacement) aliases and config
- `fzf.sh` - fzf keybindings and options
- `zoxide.sh` - zoxide initialization
- `starship.sh` - starship prompt initialization

## File Template

```bash
# <tool-name>.sh - <Tool Name> configuration
# Added by install-<tool>.sh

# Tool-specific aliases
alias foo='bar'

# Tool initialization (if needed)
if command -v tool &> /dev/null; then
  eval "$(tool init bash)"
fi

# Tool-specific environment variables
export TOOL_OPTION="value"
```

## How It Works

1. Install script creates symlink in `dotfiles/shell/dot-shell.d/<tool>.sh` → `../../<tool>/<tool>.sh`
2. Re-stow shell package: `stow -R shell`
3. `.bashrc` sources all `*.sh` files from `~/.shell.d/`
4. Tool configuration is active in new shells

Note: Files in this directory are symlinks to the actual config files in each tool's package directory.

## Disabling a Tool

To temporarily disable a tool's shell configuration:
```bash
# Rename to disable sourcing
mv ~/.shell.d/tool.sh ~/.shell.d/tool.sh.disabled
```

Or remove it entirely and unstow shell package.
