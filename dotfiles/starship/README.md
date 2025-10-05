# Starship Configuration Package

This package manages `starship` (cross-shell prompt) configuration.

## Files

- `starship.sh` → Symlinked to `shell.d/starship.sh` - Shell initialization
- `.config/starship/starship.toml` → `~/.config/starship.toml` - Starship configuration (stowed)

## Shell Integration

The `starship.sh` file initializes the starship prompt in bash:

```bash
if command -v starship &> /dev/null; then
  eval "$(starship init bash)"
fi
```

This replaces the previous inline initialization in `.bashrc`.

## Starship Configuration

The `starship.toml` file contains the prompt configuration:
- **Theme**: Gruvbox Dark color palette
- **Format**: Multi-line prompt with OS, user, directory, git, languages, time
- **Modules**: Git metrics, command duration, memory usage, jobs, status
- **Nerd Font Icons**: Requires FiraCode Nerd Font or similar

### Current Theme
Currently using Gruvbox Dark. When ready to migrate to Catppuccin Mocha:
1. Update the `[palettes.gruvbox_dark]` section with Catppuccin colors
2. Change `palette = 'gruvbox_dark'` to `palette = 'catppuccin_mocha'`

### Customization

Edit `dotfiles/starship/.config/starship/starship.toml` to customize the prompt. The install script will:
1. Stow the configuration to `~/.config/starship.toml`
2. Symlink `starship.sh` → `shell.d/starship.sh`
3. Re-stow the shell package
4. Configuration becomes active in new shells

## Notes

- Starship is a cross-shell prompt (works with bash, zsh, fish, etc.)
- Supports git repository information and status
- Shows language versions when in project directories
- Fast and customizable with TOML configuration
- Requires a Nerd Font for icons
