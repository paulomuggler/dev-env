# Lazygit Configuration

Terminal UI for Git commands with a beautiful, intuitive interface.

## Features

- **Catppuccin Mocha Theme**: Soothing pastel colors matching the rest of the environment
- **File Tree View**: Visual representation of changed files
- **Delta Integration**: Enhanced diff viewing with syntax highlighting
- **Nerd Fonts Support**: Icons and symbols for better visual clarity

## Configuration Files

- `.config/lazygit/config.yml` - Main configuration with theme and UI settings

## Shell Integration

The `lazygit.sh` file provides convenient aliases:

- `lg` / `lgg` - Launch lazygit in current directory
- `lgr` - Launch lazygit in git repository root

## Key Features in Config

### Theme
- Uses Catppuccin Mocha color scheme
- Blue accents for active elements
- Red for unstaged changes
- Yellow for search highlights

### UI Enhancements
- File tree view enabled
- Nerd Fonts v3 icons
- Delta pager for better diffs
- Random tips disabled for cleaner UI

## Usage

```bash
# Basic usage
lg

# From anywhere in a repo, jump to root
lgr
```

## Documentation

- [Lazygit Docs](https://github.com/jesseduffield/lazygit)
- [Catppuccin Theme](https://github.com/catppuccin/lazygit)
- [Config Options](https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md)
