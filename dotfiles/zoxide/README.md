# Zoxide Configuration Package

This package manages `zoxide` (smart cd command) configuration.

## Files

- `zoxide.sh` → Symlinked to `shell.d/zoxide.sh` - Shell initialization

## Shell Integration

The `zoxide.sh` file initializes zoxide in bash:

```bash
if command -v zoxide &> /dev/null; then
  eval "$(zoxide init bash)"
fi
```

This replaces the `cd` command with zoxide's smart navigation.

## Usage

Once installed, zoxide provides:

### Basic Commands
- `z <directory>` - Jump to a directory (fuzzy match based on frecency)
- `zi` - Interactive directory selection with fzf
- `zoxide query <keywords>` - Query the database
- `zoxide remove <path>` - Remove a path from the database

### Examples
```bash
# Jump to a directory you've visited before
z projects              # Goes to ~/Projects or ~/work/projects
z dev nvim              # Goes to ~/Projects/dev-env or similar

# Interactive selection
zi                      # Opens fzf to select from your history

# Still works like cd for new paths
z /usr/local/bin        # Regular cd if path exists
```

### How It Works
- Tracks directories you visit with `cd` or `z`
- Ranks them by "frecency" (frequency + recency)
- Fuzzy matches partial names
- Works with fzf for interactive selection

### Customization

Edit `dotfiles/zoxide/zoxide.sh` to customize initialization options.

Example customizations:
```bash
# Use a different command name (e.g., 'j' instead of 'z')
eval "$(zoxide init bash --cmd j)"

# Don't create the 'zi' interactive command
eval "$(zoxide init bash --no-cmd zi)"
```

The install script automatically:
1. Symlinks `zoxide.sh` → `shell.d/zoxide.sh`
2. Re-stows the shell package
3. Configuration becomes active in new shells

## Notes

- zoxide is installed via Homebrew
- Database stored at `~/.local/share/zoxide/db.zo`
- Works best with fzf for interactive mode (`zi`)
- No separate config file needed - configured via init options
- Safe to use alongside `cd` (which still works normally)
