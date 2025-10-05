# Tmux Configuration

Modern tmux setup with TPM plugin manager, sensible defaults, and beautiful Catppuccin theme.

## Features

### Core Enhancements
- **100,000 line scrollback** - Extensive history buffer
- **Mouse support** - Click panes, drag to resize, scroll through history
- **Vim-style navigation** - hjkl pane switching, visual mode selection
- **Smart window management** - Auto-renumbering, current path preservation
- **Fast escape time** - 10ms for better responsiveness

### Plugin Manager (TPM)
All plugins managed via [TPM (Tmux Plugin Manager)](https://github.com/tmux-plugins/tpm)

**Plugin Management:**
- `prefix + I` - Install new plugins
- `prefix + U` - Update all plugins
- `prefix + alt + u` - Remove/uninstall plugins

## Installed Plugins

### 🎨 Theme & Visual
- **[catppuccin/tmux](https://github.com/catppuccin/tmux)** - Beautiful Catppuccin Mocha theme
  - Matches nvim, bat, lazygit color scheme
  - Shows current directory and session name
  - Clean, modern status bar

- **[tmux-prefix-highlight](https://github.com/tmux-plugins/tmux-prefix-highlight)** - Visual indicator when prefix is active
  - Shows copy mode in yellow
  - Shows sync mode in green

### 💾 Session Persistence
- **[tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect)** - Save and restore sessions
  - `prefix + Ctrl-s` - Save session
  - `prefix + Ctrl-r` - Restore session
  - Restores pane contents, nvim sessions, running programs

- **[tmux-continuum](https://github.com/tmux-plugins/tmux-continuum)** - Automatic session saving
  - Auto-saves every 15 minutes
  - Auto-restores last session on tmux start

### 📋 Copy & Clipboard
- **[tmux-yank](https://github.com/tmux-plugins/tmux-yank)** - Copy to system clipboard
  - Works with macOS `pbcopy`
  - Automatic clipboard integration

- **[tmux-copycat](https://github.com/tmux-plugins/tmux-copycat)** - Enhanced search in copy mode
  - `prefix + /` - Search regex
  - `prefix + Ctrl-f` - Find files
  - `prefix + Ctrl-u` - Find URLs
  - `prefix + Ctrl-d` - Find numbers

### 🚀 Productivity
- **[tmux-sensible](https://github.com/tmux-plugins/tmux-sensible)** - Sensible default settings
  - Industry-standard tmux configuration

- **[tmux-open](https://github.com/tmux-plugins/tmux-open)** - Open files and URLs from tmux
  - Highlight and open files/URLs with `o` in copy mode

- **[tmux-fzf](https://github.com/sainnhe/tmux-fzf)** - Fuzzy finder integration
  - `prefix + F` - Fuzzy-find and switch windows/panes/sessions
  - Command palette-like experience

- **[vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator)** - Seamless vim↔tmux navigation
  - `Ctrl-h/j/k/l` - Navigate between vim splits and tmux panes
  - Works with LazyVim/Neovim

## Key Bindings

### Prefix Key
- **Prefix**: `Ctrl-a` (instead of default `Ctrl-b`)
- **Send prefix**: `Ctrl-a Ctrl-a` (sends Ctrl-a to application)

### Window Management
- `prefix + c` - Create new window (in current directory)
- `prefix + ,` - Rename window
- `prefix + n/p` - Next/previous window
- `Shift + Left/Right` - Switch windows (no prefix needed)

### Pane Management
- `prefix + |` - Split pane vertically (in current directory)
- `prefix + -` - Split pane horizontally (in current directory)
- `prefix + h/j/k/l` - Navigate panes (vim-style)
- `Alt + Arrow keys` - Navigate panes (no prefix needed)
- `prefix + H/J/K/L` - Resize panes (vim-style, repeatable)
- `prefix + Ctrl-a` - Cycle through panes

### Copy Mode (Vim-style)
- `prefix + [` - Enter copy mode
- `v` - Begin selection (in copy mode)
- `y` - Yank selection to clipboard
- `r` - Rectangle toggle
- `q` - Exit copy mode

### Session Management
- `prefix + Ctrl-s` - Save session (tmux-resurrect)
- `prefix + Ctrl-r` - Restore session (tmux-resurrect)
- `prefix + F` - Fuzzy-find sessions/windows/panes (tmux-fzf)

### Other
- `prefix + r` - Reload configuration
- `prefix + ?` - Show all key bindings

## Configuration Highlights

### Catppuccin Theme
- **Flavor**: Mocha (dark theme)
- **Status modules**: Directory, session name
- **Consistent with**: nvim, lazygit, bat, yazi

### Session Persistence
- **Auto-save**: Every 15 minutes
- **Auto-restore**: On tmux start
- **Restored programs**: nvim, vim, ssh, lazygit
- **Pane contents**: Captured and restored

### Performance
- **Escape time**: 10ms (fast vim mode switching)
- **History**: 100,000 lines
- **Status refresh**: Every 5 seconds

## Files

```
dotfiles/tmux/
└── .config/tmux/tmux.conf  → ~/.config/tmux/tmux.conf
```

## Post-Installation

After running `install-tmux.sh`:

1. **Start tmux**: `tmux`
2. **Install plugins**: `prefix + I` (if not auto-installed)
3. **Verify**: All plugins should load automatically

## Plugin Updates

```bash
# Inside tmux
prefix + U                # Update all plugins
prefix + alt + u          # Remove unlisted plugins
```

## Customization

Edit `.config/tmux/tmux.conf` in this package:

```bash
# Change theme flavor
set -g @catppuccin_flavour 'latte'  # or frappe, macchiato, mocha

# Disable auto-restore
set -g @continuum-restore 'off'

# Change save interval
set -g @continuum-save-interval '30'  # 30 minutes
```

Then re-stow:
```bash
cd ~/Projects/dev-env/dotfiles
stow -R --dotfiles tmux
```

## Troubleshooting

### Plugins not loading
```bash
# Reinstall TPM
rm -rf ~/.tmux/plugins/tpm
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Inside tmux
prefix + I
```

### Colors look wrong
```bash
# Check terminal supports true color
echo $TERM  # Should be screen-256color or tmux-256color

# In your terminal emulator, enable true color support
```

### Vim navigation not working
Ensure `vim-tmux-navigator` is installed in both tmux and nvim:
- Tmux: Already configured in this package
- Nvim: LazyVim includes this by default

## Documentation

- [Tmux Manual](https://man.openbsd.org/tmux)
- [TPM GitHub](https://github.com/tmux-plugins/tpm)
- [Catppuccin for tmux](https://github.com/catppuccin/tmux)
- [Awesome Tmux Plugins](https://github.com/rothgar/awesome-tmux)
