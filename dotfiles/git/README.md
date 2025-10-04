# Git Configuration Package

This stow package manages Git configuration files.

## Files Managed

- `dot-gitconfig` → `~/.gitconfig` - Main Git configuration file

## Configuration Highlights

### User Information
- Name and email configured for commits

### Editor
- Uses `nvim` as default editor (was `nano`)

### Aliases
- `st` = status
- `co` = checkout
- `br` = branch
- `ci` = commit
- `unstage` = reset HEAD --
- `last` = log -1 HEAD
- `visual` = log --graph --oneline --all --decorate

### Behavior
- Color UI enabled
- Pull strategy: merge (not rebase)
- Default branch: `main`

## Installation

This package is stowed via the main setup script, but can be manually applied:

```bash
cd /path/to/devenv
stow -d dotfiles -t ~ git
```

## Customization

Edit `dotfiles/git/dot-gitconfig` and re-stow to apply changes.