# Ghostty Configuration

dev-env additions for Ghostty terminal emulator on Omarchy/Hyprland.

## Quick Terminal (Dropdown)

Press **F12** anywhere to toggle a dropdown terminal from the top of the screen.

This uses Ghostty's native `toggle_quick_terminal` feature (added in v1.2) which works on Wayland compositors that support `wlr-layer-shell` protocol (including Hyprland).

## Configuration

Omarchy manages Ghostty theming via its `colors.toml` system. This config only adds:

- Quick terminal settings (position, animation, hotkey)
- Shell integration
- Performance hints

## Keybindings

| Key | Action |
|-----|--------|
| F12 (global) | Toggle quick terminal |

## Files

- `~/.config/ghostty/config` - Main configuration

## Notes

- Colors are managed by Omarchy's theming system
- To customize colors, use `Super+Alt+Space` > Setup > Colors, or edit `~/.config/ghostty/colors.toml` directly
- Quick terminal has full keyboard focus and can run tmux sessions
