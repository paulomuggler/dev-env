# Eza Configuration Package

This package manages `eza` (a modern replacement for ls) configuration.

## Files

- `eza.sh` → Symlinked to `shell.d/eza.sh` - Shell aliases and configuration

## Shell Integration

The `eza.sh` file provides modern ls replacement aliases without overriding the standard `ls` command.

### Aliases

**Basic listings:**
- `ll` → `eza -la --git --icons` - Detailed list with git status and icons
- `la` → `eza -a --icons` - List all files with icons
- `l` → `eza -1 --icons` - Single column list with icons
- `llt` → `eza -la --git --icons --tree --level=2` - Tree view with details

**Tree views:**
- `tree` → `eza --tree --icons` - Tree view
- `tree2` → `eza --tree --level=2 --icons` - Tree view (2 levels)
- `tree3` → `eza --tree --level=3 --icons` - Tree view (3 levels)

**Git-aware:**
- `lg` → `eza -la --git --git-ignore --icons` - List with git info, respecting .gitignore

### Design Decision: No `ls` Override

We intentionally do NOT alias `ls` to `eza` because:
- Many scripts and tools expect POSIX `ls` behavior
- Different argument syntax between `ls` and `eza`
- Avoid breaking automation and compatibility

Instead, use the provided aliases (`ll`, `la`, `tree`, etc.) for interactive use while keeping `ls` for scripts.

### Customization

Edit `dotfiles/eza/eza.sh` to modify aliases or add eza-specific shell configuration. The install script automatically:
1. Symlinks `eza.sh` → `shell.d/eza.sh`
2. Re-stows the shell package
3. Configuration becomes active in new shells

## Notes

- `eza` provides git integration showing file modification status
- Icon support requires a Nerd Font (we use FiraCode Nerd Font)
- Color scheme uses terminal theme colors
- No separate config file needed - eza is configured via command-line flags in aliases
