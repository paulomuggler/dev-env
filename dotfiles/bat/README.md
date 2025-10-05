# Bat Configuration Package

This package manages `bat` (a cat clone with syntax highlighting) configuration.

## Files

- `bat.sh` → Symlinked to `shell.d/bat.sh` - Shell aliases and configuration
- `.config/bat/config` → `~/.config/bat/config` - bat configuration file (stowed)

## Shell Integration

The `bat.sh` file provides:

### Aliases
- `cat` → `bat --paging=never --style=plain` - Drop-in replacement for cat
- `batcat` → `bat` - Full bat with paging and line numbers
- `batp` → `bat --paging=always` - Force paging

### Customization

Edit `dotfiles/bat/bat.sh` to modify aliases or add bat-specific shell configuration. The install script automatically:
1. Symlinks `bat.sh` → `shell.d/bat.sh`
2. Re-stows the shell package
3. Configuration becomes active in new shells

## Bat Configuration

The `.config/bat/config` file sets:
- **Theme**: Monokai Extended (will be Catppuccin Mocha when available)
- **Style**: Line numbers, git changes, file header
- **Paging**: Auto (uses pager for large files)
- **Syntax mappings**: Custom file extension mappings

Edit `dotfiles/bat/.config/bat/config` to customize bat's behavior.

## Notes

- `bat` integrates with git to show file modifications
- Supports syntax highlighting for 200+ languages
- Respects `.gitignore` when used with `--show-all`
