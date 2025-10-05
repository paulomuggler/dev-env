# fzf Configuration Package

This package manages `fzf` (fuzzy finder) configuration.

## Files

- `fzf.sh` → Symlinked to `shell.d/fzf.sh` - Shell initialization and configuration

## Shell Integration

The `fzf.sh` file provides:

### Initialization
```bash
if command -v fzf &> /dev/null; then
  eval "$(fzf --bash)"
fi
```

This sets up:
- **Ctrl+R** - Fuzzy search through command history
- **Ctrl+T** - Fuzzy find files/directories to insert into command line
- **Alt+C** - Fuzzy cd into a directory
- **Tab completion** - Enhanced fuzzy completion for various commands

### Configuration Options

**Ctrl+R Preview:**
- `FZF_CTRL_R_OPTS` - Shows preview of command, 40% height with border

**Default Options:**
- `FZF_DEFAULT_OPTS` - Global fzf settings: 40% height, reverse layout, border

### Customization

Edit `dotfiles/fzf/fzf.sh` to customize:
- Key bindings behavior
- Preview window settings
- Default search options
- Color scheme (can use Catppuccin colors)

Example additional customizations:
```bash
# Use ripgrep for file search
export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'

# Catppuccin Mocha colors (example)
export FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS \
  --color=fg:#cdd6f4,bg:#1e1e2e,hl:#f38ba8 \
  --color=fg+:#cdd6f4,bg+:#313244,hl+:#f38ba8 \
  --color=info:#cba6f7,prompt:#cba6f7,pointer:#f5e0dc"
```

The install script automatically:
1. Symlinks `fzf.sh` → `shell.d/fzf.sh`
2. Re-stows the shell package
3. Configuration becomes active in new shells

## Notes

- fzf is installed via Homebrew
- Works best with ripgrep (rg) for fast file searching
- Integrates with bat for syntax-highlighted previews
- Key bindings are bash-specific (uses `fzf --bash`)
- No separate config file needed - configured via environment variables
