# iTerm2 Configuration

Configuration files for iTerm2 terminal emulator (macOS only).

## Overview

iTerm2 preferences are managed using a **Custom Preferences Folder** approach, which stores all settings in a plist file that can be version controlled and synchronized across machines.

## Files

### .config/iterm2/com.googlecode.iterm2.plist
Complete iTerm2 preferences file including:
- Profile configurations (colors, fonts, key bindings)
- Window arrangements
- Global preferences
- Keyboard shortcuts
- AI integration settings

## How iTerm2 Preferences Work

iTerm2 stores preferences in one of two ways:

1. **Default Location**: `~/Library/Preferences/com.googlecode.iterm2.plist` (standard macOS)
2. **Custom Folder** (recommended): Any directory you specify

### Custom Preferences Folder Benefits
- Version control friendly
- Easy to sync across machines
- Portable and reproducible
- Changes are written to the custom folder instead of Library/Preferences

## Installation

Installed via `install-scripts/install-iterm2.sh`:

1. Installs iTerm2 via Homebrew cask if not present
2. Stows the iterm2 configuration to `~/.config/iterm2/`
3. Configures iTerm2 to use the custom preferences folder
4. Sets up iTerm2 to load preferences from `~/.config/iterm2/`

## Manual Setup (if needed)

If the install script doesn't automatically configure the custom folder:

```bash
# Set the custom preferences folder
defaults write com.googlecode.iterm2 PrefsCustomFolder -string "${HOME}/.config/iterm2"

# Enable loading from custom folder
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true

# Restart iTerm2 for changes to take effect
```

## Verify Configuration

Check if custom folder is configured:

```bash
# Check custom folder location
defaults read com.googlecode.iterm2 PrefsCustomFolder

# Check if loading is enabled (should return 1)
defaults read com.googlecode.iterm2 LoadPrefsFromCustomFolder
```

## Making Changes

1. Open iTerm2 preferences: `⌘,` (Command + Comma)
2. Make your changes
3. Changes are automatically saved to `~/.config/iterm2/com.googlecode.iterm2.plist`
4. Commit changes: `cd ~/Projects/dev-env && git add dotfiles/iterm2/ && git commit`

## Important Notes

- **Backup before first use**: Your existing preferences will be overwritten when stowing
- **Restart required**: Changes to PrefsCustomFolder require restarting iTerm2
- **Automatic sync**: Once configured, all preference changes auto-save to the custom folder
- **Profile-specific settings**: Font, colors, and keybindings are stored in the plist
- **macOS-specific**: This configuration is only for macOS systems

## Key Settings in This Configuration

Based on the exported preferences, this configuration includes:

- **AI Integration**: OpenAI API integration with GPT-4.1 model
- **Smart Selection**: Double-click performs smart selection
- **Custom Key Mappings**: Various keyboard shortcuts configured
- **Clipboard Access**: Enabled for terminal operations
- **Mouse Scrolling**: Alternate mouse scroll enabled
- **Default Profile**: Custom default bookmark configured

## Alternative: Dynamic Profiles

For profile-only configuration (without global settings), you can use Dynamic Profiles:

1. Create JSON files in `~/Library/Application Support/iTerm2/DynamicProfiles/`
2. Changes are picked up automatically without restart
3. Good for managing multiple profiles programmatically

This setup uses the Custom Preferences Folder approach for complete configuration management.

## Troubleshooting

**Preferences not loading:**
- Verify custom folder path: `defaults read com.googlecode.iterm2 PrefsCustomFolder`
- Verify loading enabled: `defaults read com.googlecode.iterm2 LoadPrefsFromCustomFolder`
- Restart iTerm2 completely (Quit, not just close window)

**Changes not saving:**
- Check write permissions on `~/.config/iterm2/`
- Verify plist file exists and is writable
- Check Console.app for iTerm2 errors

**Want to reset:**
```bash
# Disable custom folder
defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool false

# Or delete the settings entirely
defaults delete com.googlecode.iterm2 PrefsCustomFolder
defaults delete com.googlecode.iterm2 LoadPrefsFromCustomFolder
```
