# Shell Configuration Package

This package manages Bash shell configuration files.

## Files

- `dot-bash_profile` → `~/.bash_profile` - Login shell configuration (environment, PATH)
- `dot-bashrc` → `~/.bashrc` - Interactive shell configuration (aliases, functions, prompts)
- `dot-bash_functions` → `~/.bash_functions` - Custom shell functions
- `dot-bash_aliases` → `~/.bash_aliases` - Command aliases
- `dot-bash_env.example` → `~/.bash_env.example` - Template for environment variables with secrets

## Understanding .bash_profile vs .bashrc

### .bash_profile (Login Shells)
- Executed when you first log in or open a new Terminal window on macOS
- Sets up the environment (LANG, TERM, etc.)
- Sources `~/.bash_path` for PATH modifications (managed by install scripts)
- Sources `~/.bashrc` at the end to load interactive shell config

### .bashrc (Interactive Shells)
- Executed by interactive shells
- Loads aliases and functions
- Initializes tools (starship, fzf, zoxide)
- Configures shell prompt and completions

### The Pattern
macOS Terminal.app runs login shells by default, so:
1. `.bash_profile` runs first (sets environment and PATH)
2. `.bash_profile` sources `.bashrc` (loads interactive config)
3. Both login and non-login shells get the same aliases/functions

## Environment Variables & Secrets

**Important:** Never commit files with real API keys or secrets!

1. Copy the example file:
   ```bash
   cp ~/.bash_env.example ~/.bash_env
   ```

2. Edit `~/.bash_env` with your actual API keys

3. The real `~/.bash_env` is in `.gitignore` and won't be committed

## PATH Management

PATH modifications are managed via `~/.bash_path`, which is:
- Created automatically by install scripts
- Sourced by `.bash_profile`
- Keeps all PATH modifications in one place

## Tool Integration

The configuration includes initialization for:
- **Starship** - Modern shell prompt
- **fzf** - Fuzzy finder for files and command history
- **zoxide** - Smarter `cd` command
- **Homebrew** - Bash completion support
- **iTerm2** - Shell integration (if installed)

### Future: Tool-Specific Config Packages

Tool-specific configurations will be migrated to their own stow packages when install scripts are created:

- **fzf configs** (currently FZF_CTRL_R_OPTS in .bash_profile) → `dotfiles/fzf/`
- **starship configs** (currently initialization in .bashrc) → `dotfiles/starship/`
- **zoxide configs** (currently initialization in .bashrc) → `dotfiles/zoxide/`
- Other tools as needed

This keeps tool configurations self-contained and makes it easier to manage, update, or remove individual tools.

## Neovim Configurations

LazyVim is the default Neovim configuration (at `~/.config/nvim`):
- `nvim` or `lazyvim` - Opens LazyVim (the default)
- `nvim-plain` - Opens Neovim without any configuration
  - If `~/.config/nvim-plain` exists, uses that minimal config
  - Otherwise uses `nvim --clean` (completely clean, no config)

## Customization

Edit the files in `dotfiles/shell/` and re-stow to apply changes:
```bash
cd dotfiles && stow -R shell
```
