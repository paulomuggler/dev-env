# Tmux Configuration Package

This package manages tmux configuration files using XDG-compliant directory structure.

## Files

- `.config/tmux/tmux.conf` → `~/.config/tmux/tmux.conf` - Main tmux configuration

## Configuration Highlights

### Prefix Key
- Changed from `Ctrl-b` to `Ctrl-a` (more ergonomic)

### Pane Management
- **Split panes**: `Prefix + |` (vertical), `Prefix + -` (horizontal)
- **Navigate panes**: `Alt + Arrow keys` (no prefix needed) or `Prefix + hjkl` (vim-style)
- **Resize panes**: `Prefix + HJKL` (vim-style, capital letters)

### Key Features
- **True color support**: 256 colors enabled
- **Mouse support**: Click to switch panes, drag to resize
- **Vim-style copy mode**: Enter copy mode with `Prefix + [`, select with `v`, yank with `y`
- **Persistent history**: 50,000 line scrollback buffer
- **Window numbering**: Starts at 1 (not 0) and renumbers automatically

### Quick Reference
- `Prefix + r` - Reload config
- `Prefix + c` - Create new window
- `Prefix + n/p` - Next/previous window
- `Prefix + ,` - Rename window
- `Prefix + [` - Enter copy mode
- `Prefix + ]` - Paste buffer

## Future Enhancements

The following will be added in future updates:
- **TPM (Tmux Plugin Manager)** - Plugin management system
- **Catppuccin theme** - Consistent color scheme
- **tmux-resurrect** - Save/restore sessions
- **tmux-continuum** - Automatic session saving
- **Custom workspace scripts** - LLM CLI integration layouts

## Customization

Edit `.config/tmux/tmux.conf` in this package and re-stow to apply changes.

## Notes

- Configuration uses XDG directory (`~/.config/tmux/`) instead of `~/.tmux.conf`
- Tmux will automatically source config from `~/.config/tmux/tmux.conf` (tmux 3.1+)
- For older tmux versions, you may need to manually source the config
