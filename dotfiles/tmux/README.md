# Tmux Configuration

Modern tmux setup based on [Oh my tmux!](https://github.com/gpakosz/.tmux) with TPM plugin manager, sensible defaults, and comprehensive plugin ecosystem.

## Overview

This configuration uses **gpakosz's Oh my tmux!** as the base configuration, which provides a well-tested, feature-rich foundation. We then layer our custom settings and plugins on top via `.tmux.conf.local`.

## Architecture

```
.config/tmux/
├── tmux.conf        → Main config from gpakosz/.tmux (DO NOT EDIT)
└── tmux.conf.local  → Custom overrides and plugins (EDIT THIS)
```

The main `tmux.conf` is the stock Oh my tmux! configuration and should never be modified directly. All customizations go in `.tmux.conf.local`.

## Features

### Core Enhancements
- **100,000 line scrollback** - Extensive history buffer
- **Mouse support** - Click panes, drag to resize, scroll through history
- **Vim-style navigation** - hjkl pane switching, visual mode selection
- **Smart window management** - Auto-renumbering, current path preservation
- **Fast escape time** - 10ms for better responsiveness
- **True color support** - 24-bit color automatically detected
- **Battery status** - Shows battery percentage and charging status
- **Uptime display** - System uptime in status bar
- **SSH awareness** - Special handling for SSH sessions

### Plugin Manager (TPM)
All plugins managed via [TPM (Tmux Plugin Manager)](https://github.com/tmux-plugins/tpm)

**Plugin Management:**
- `prefix + I` - Install new plugins
- `prefix + U` - Update all plugins (custom binding in Oh my tmux!)
- `prefix + alt + u` - Remove/uninstall plugins (custom binding in Oh my tmux!)

## Installed Plugins

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
- **[tmux-open](https://github.com/tmux-plugins/tmux-open)** - Open files and URLs from tmux
  - Highlight and open files/URLs with `o` in copy mode

- **[tmux-fzf](https://github.com/sainnhe/tmux-fzf)** - Fuzzy finder integration
  - `prefix + F` - Fuzzy-find and switch windows/panes/sessions
  - Command palette-like experience

- **[vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator)** - Seamless vim↔tmux navigation
  - `Ctrl-h/j/k/l` - Navigate between vim splits and tmux panes
  - Works with LazyVim/Neovim

- **[tmux-grimoire](https://github.com/navahas/tmux-grimoire)** - Popup shells
  - `prefix + f` - Open main popup shell
  - `prefix + Shift-F` - Open ephemeral popup shell
  - `prefix + C` - Close popup shell
  - Customizable floating terminal windows

### 🎨 Visual Enhancement
- **[tmux-prefix-highlight](https://github.com/tmux-plugins/tmux-prefix-highlight)** - Visual indicator when prefix is active
  - Shows copy mode in yellow
  - Shows sync mode in green

## Key Bindings

### Prefix Key
- **Prefix**: `Ctrl-a` (instead of default `Ctrl-b`)
- **Send prefix**: `Ctrl-a Ctrl-a` (sends Ctrl-a to application)

### Window Management
- `prefix + c` - Create new window (in current directory)
- `prefix + C` - Create new session
- `prefix + ,` - Rename window
- `prefix + $` - Rename session
- `prefix + n/p` - Next/previous window
- `prefix + Tab` - Last window
- `Shift + Left/Right` - Switch windows (no prefix needed)

### Pane Management
- `prefix + -` - Split pane horizontally (Oh my tmux! default)
- `prefix + _` - Split pane vertically (Oh my tmux! default)
- `prefix + h/j/k/l` - Navigate panes (vim-style)
- `prefix + H/J/K/L` - Resize panes (vim-style, repeatable)
- `prefix + Ctrl-a` - Cycle through panes
- `prefix + <` / `prefix + >` - Move pane left/right
- `prefix + +` - Maximize/restore pane

### Copy Mode (Vim-style)
- `prefix + Enter` - Enter copy mode
- `v` - Begin selection (in copy mode)
- `C-v` - Rectangle selection
- `y` - Yank selection to clipboard
- `r` - Rectangle toggle
- `Escape` - Exit copy mode

### Session Management
- `prefix + Ctrl-s` - Save session (tmux-resurrect)
- `prefix + Ctrl-r` - Restore session (tmux-resurrect)
- `prefix + F` - Fuzzy-find sessions/windows/panes (tmux-fzf)

### Other
- `prefix + r` - Reload configuration
- `prefix + e` - Edit configuration (opens `.tmux.conf.local`)
- `prefix + m` - Toggle mouse mode (with notification)
- `prefix + ?` - Show all key bindings
- `prefix + t` - Show clock

## Configuration Highlights

### Oh my tmux! Features
- **Intelligent theme** - Adapts to terminal capabilities
- **Status bar widgets** - Username, hostname, uptime, battery
- **SSH detection** - Highlights SSH sessions
- **Clipboard integration** - Works across platforms
- **Automatic TPM management** - Plugins install/update automatically

### Session Persistence
- **Auto-save**: Every 15 minutes
- **Auto-restore**: On tmux start
- **Restored programs**: nvim, vim, ssh, lazygit
- **Pane contents**: Captured and restored
- **Nvim session strategy**: Full session restoration

### Performance
- **Escape time**: 10ms (fast vim mode switching)
- **History**: 100,000 lines (increased from default 5000)
- **Status refresh**: Every 5 seconds (via Oh my tmux!)
- **Display time**: 4 seconds for messages
- **Focus events**: Enabled for better terminal integration

### Smart Behavior
- **Current path retention**: New windows/panes open in current directory
- **Window renumbering**: Gaps automatically filled
- **Activity monitoring**: Visual notification of activity in other windows
- **Aggressive resize**: Better multi-monitor support

## Files

```
dotfiles/tmux/
└── .config/tmux/
    ├── tmux.conf        → Main Oh my tmux! config (from gpakosz)
    ├── tmux.conf.local  → Custom configuration (this is where you edit)
    └── tmux.conf.backup → Backup of previous config
```

## Post-Installation

After running `install-tmux.sh`:

1. **Start tmux**: `tmux`
2. **Plugins auto-install**: Oh my tmux! will automatically install and update plugins
3. **Verify**: All plugins should load automatically
4. **Manual install** (if needed): `prefix + I`

## Plugin Updates

```bash
# Inside tmux
prefix + U                # Update all plugins
prefix + alt + u          # Remove unlisted plugins
```

Oh my tmux! automatically updates plugins on launch and reload by default.

## Customization

### Editing Configuration

```bash
# Inside tmux - easiest method
prefix + e                # Opens .tmux.conf.local in $EDITOR

# Or edit directly
nvim ~/Projects/dev-env/dotfiles/tmux/.config/tmux/tmux.conf.local

# Then reload
prefix + r
```

### Common Customizations

All edits go in `.tmux.conf.local`. Use `#!important` to override Oh my tmux! settings:

```bash
# Example: Change history limit
set -g history-limit 50000 #!important

# Example: Disable auto-restore
set -g @continuum-restore 'off'

# Example: Change theme colors
tmux_conf_theme_colour_1="#1e1e2e"    # Catppuccin background
tmux_conf_theme_colour_4="#89b4fa"    # Catppuccin blue

# Example: Change status bar content
tmux_conf_theme_status_left=" ❐ #S | ↑#{?uptime_h, #{uptime_h}h,} "
```

### Adding Plugins

Edit `.tmux.conf.local` and add in the TPM section:

```bash
set -g @plugin 'new-plugin-name/repo'
```

Then reload config (`prefix + r`) or run `prefix + I` to install.

### Theme Customization

Oh my tmux! provides extensive theming through variables in `.tmux.conf.local`. See the file comments for all available options.

Optional: Enable Catppuccin theme by uncommenting the plugin section in `.tmux.conf.local`.

## Troubleshooting

### Plugins not loading
```bash
# Reinstall TPM
rm -rf ~/.config/tmux/plugins/tpm
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

# Inside tmux
prefix + I
```

### Colors look wrong
```bash
# Check terminal supports true color
echo $COLORTERM  # Should be 'truecolor' or '24bit'

# Check tmux version
tmux -V  # Should be 3.2 or higher

# In your terminal emulator, enable true color support
```

### Configuration not loading
```bash
# Check for syntax errors
tmux source-file ~/.config/tmux/tmux.conf

# Check if .tmux.conf.local exists
ls -la ~/.config/tmux/tmux.conf.local

# Verify stow is working
cd ~/Projects/dev-env/dotfiles
stow -n --dotfiles tmux  # Dry run to check
```

### Vim navigation not working
Ensure `vim-tmux-navigator` is installed in both tmux and nvim:
- Tmux: Already configured in this package
- Nvim: LazyVim includes this by default

### Mouse mode not working
```bash
# Inside tmux, toggle mouse mode
prefix + m

# Or check if it's enabled
tmux show-options -g mouse
```

## Lazy-LLM Integration

This configuration is designed to work seamlessly with lazy-llm tool:
- Smart pane navigation preserves lazy-llm workflow
- Copy mode integration for prompt management
- Session persistence across lazy-llm sessions
- Popup shells (grimoire) for quick commands

## Documentation

- **[Oh my tmux! README](https://github.com/gpakosz/.tmux)** - Base configuration documentation
- [Tmux Manual](https://man.openbsd.org/tmux) - Official tmux manual
- [TPM GitHub](https://github.com/tmux-plugins/tpm) - Plugin manager documentation
- [Awesome Tmux Plugins](https://github.com/rothgar/awesome-tmux) - Plugin directory

## Credits

- Base configuration: [Oh my tmux!](https://github.com/gpakosz/.tmux) by Gregory Pakosz
- Plugin management: [TPM](https://github.com/tmux-plugins/tpm)
- Theme inspiration: [Catppuccin](https://github.com/catppuccin/catppuccin)
