# AeroSpace Configuration

i3-like tiling window manager for macOS with automatic tiling, workspaces, and vim-style navigation.

## Overview

AeroSpace is a tiling window manager for macOS that provides:
- **Automatic window tiling** - Windows automatically arrange in tiles
- **Multiple workspaces** - Organize windows across virtual desktops
- **Vim-style navigation** - hjkl keys for moving between windows
- **i3-inspired** - Similar to i3wm on Linux
- **Native macOS** - Works with System Integrity Protection enabled

## Features

### Window Management
- Automatic tiling with horizontal/vertical splits
- Floating window support
- Window resizing with smart layouts
- Focus follows mouse between monitors

### Workspaces
- 9 numbered workspaces (1-9)
- 26 lettered workspaces (A-Z)
- Quick workspace switching
- Move windows between workspaces

### Layouts
- **Tiles** - Traditional tiling (default)
- **Accordion** - All windows visible simultaneously
- **Floating** - Traditional overlapping windows

## Key Bindings

### Window Navigation
- `Alt + h/j/k/l` - Focus left/down/up/right window (vim-style)

### Window Movement
- `Alt + Shift + h/j/k/l` - Move window left/down/up/right

### Window Resizing
- `Alt + -` - Decrease window size
- `Alt + =` - Increase window size

### Layout Control
- `Alt + /` - Toggle tiles layout (horizontal/vertical)
- `Alt + ,` - Toggle accordion layout

### Workspace Switching
- `Alt + 1-9` - Switch to numbered workspace
- `Alt + a-z` - Switch to lettered workspace
- `Alt + Tab` - Switch to previous workspace

### Move Window to Workspace
- `Alt + Shift + 1-9` - Move window to numbered workspace
- `Alt + Shift + a-z` - Move window to lettered workspace
- `Alt + Shift + Tab` - Move workspace to next monitor

### Service Mode
- `Alt + Shift + ;` - Enter service mode

**Service mode commands:**
- `Esc` - Reload config and exit service mode
- `r` - Reset layout (flatten workspace tree)
- `f` - Toggle floating/tiling layout
- `Backspace` - Close all windows except current
- `Alt + Shift + h/j/k/l` - Join window with neighbor
- `Up/Down` - Volume control
- `Shift + Down` - Mute volume

## Configuration

The configuration file is located at:
```
~/.config/aerospace/aerospace.toml
```

### Common Customizations

#### Enable Auto-start
```toml
start-at-login = true
```

#### Add Window Gaps
```toml
[gaps]
    inner.horizontal = 8
    inner.vertical = 8
    outer.left = 8
    outer.bottom = 8
    outer.top = 8
    outer.right = 8
```

#### Change Default Layout
```toml
default-root-container-layout = 'accordion'  # or 'tiles'
```

#### Add Terminal Shortcut
```toml
# In [mode.main.binding] section
alt-enter = '''exec-and-forget osascript -e '
tell application "iTerm"
    create window with default profile
    activate
end tell'
'''
```

#### Startup Commands
```toml
after-startup-command = [
    'exec-and-forget borders active_color=0xffe1e3e4 inactive_color=0xff494d64 width=5.0'
]
```

## Reloading Configuration

After editing the config:

1. **Via keyboard**: `Alt + Shift + ;` then `Esc`
2. **Via command**: `aerospace reload-config`

## Files

```
dotfiles/aerospace/
└── .config/aerospace/
    └── aerospace.toml  → ~/.config/aerospace/aerospace.toml
```

## Post-Installation

After running `install-aerospace.sh`:

1. **Launch AeroSpace** from Applications or Spotlight
2. **Grant permissions** when prompted (Accessibility permissions required)
3. **Test keybindings** - Try `Alt + 1`, `Alt + 2` to switch workspaces
4. **Open multiple windows** and see automatic tiling in action
5. **Enable auto-start** if desired (edit config)

## Usage Examples

### Basic Workflow
```
# Open a few applications
# They will automatically tile

Alt + h/j/k/l        # Navigate between windows
Alt + /              # Change layout orientation
Alt + 2              # Switch to workspace 2
Alt + Shift + 3      # Move current window to workspace 3
```

### Multi-Monitor Setup
```
Alt + Tab            # Switch between workspaces on current monitor
Alt + Shift + Tab    # Move workspace to next monitor
```

### Service Mode Workflow
```
Alt + Shift + ;      # Enter service mode
r                    # Reset layout if things get messy
f                    # Toggle floating for current window
Esc                  # Exit service mode
```

## Tips & Tricks

### Window Management
- Windows automatically tile when you open them
- Use workspaces to organize different tasks (code, communication, browsing)
- Service mode is great for quick layout adjustments

### Keyboard Layout
If you use Dvorak or Colemak:
```toml
[key-mapping]
    preset = 'dvorak'  # or 'colemak'
```

### Disable macOS Hide (Cmd-H)
Prevent accidental hiding:
```toml
automatically-unhide-macos-hidden-apps = true
```

### Integration with Other Tools
- Works great with **Hammerspoon** for additional automation
- Complements **Karabiner-Elements** for keyboard customization
- Use with **Raycast** or **Alfred** for app launching

## Troubleshooting

### Windows not tiling
- Check if AeroSpace is running (menu bar icon)
- Ensure accessibility permissions are granted
- Try reloading config: `Alt + Shift + ;` then `Esc`

### Keybindings not working
- Check for conflicts with other apps (especially Alt key)
- Some apps capture Alt key (Terminal, VSCode) - may need to configure
- Use different modifier if needed (edit config)

### Application not in menu bar
- Launch manually: `open /Applications/AeroSpace.app`
- Check Activity Monitor for AeroSpace process
- Reinstall if necessary

### Reset to defaults
```bash
# Backup current config
cp ~/.config/aerospace/aerospace.toml ~/.config/aerospace/aerospace.toml.backup

# Restore from dotfiles
cd ~/Projects/dev-env/dotfiles
stow -R --dotfiles -t "${HOME}" aerospace
```

## Documentation

- **Official site**: https://nikitabobko.github.io/AeroSpace/
- **Commands reference**: https://nikitabobko.github.io/AeroSpace/commands
- **Configuration guide**: https://nikitabobko.github.io/AeroSpace/guide
- **GitHub**: https://github.com/nikitabobko/AeroSpace

## Alternative Window Managers

If AeroSpace doesn't fit your workflow, consider:
- **Amethyst** - Similar tiling WM with different approach
- **Rectangle** - Simpler window snapping (not full tiling)
- **yabai** - More powerful but requires SIP disabling
- **Hammerspoon** - Scriptable window management

## Credits

- AeroSpace by Nikita Bobko
- Inspired by i3wm
- Default configuration from official documentation
