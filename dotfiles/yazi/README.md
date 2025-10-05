# Yazi Configuration

Blazing fast terminal file manager written in Rust, featuring async I/O and full mouse support.

## Features

- **Catppuccin Mocha Theme**: Installed via yazi flavor system
- **Image Previews**: High-quality image rendering in terminal
- **Mouse Support**: Click and scroll through files
- **Bulk Operations**: Select and operate on multiple files
- **Vi-like Keybindings**: Familiar navigation for vim users

## Configuration Files

- `.config/yazi/theme.toml` - Catppuccin Mocha flavor configuration
- `.config/yazi/yazi.toml` - Main configuration (sorting, preview, tasks)

## Shell Integration

The `yazi.sh` file provides:

- `y` - Quick launch yazi
- `yy` - Launch yazi with shell directory change on exit
- `ranger` - Alias for ranger users transitioning to yazi

## Post-Installation Steps

After running the install script, install the Catppuccin theme flavor:

```bash
ya pkg add yazi-rs/flavors:catppuccin-mocha
```

## Key Features in Config

### Manager Settings
- Show hidden files by default
- Sort directories first
- Display file sizes in list

### Preview Settings
- High-quality image previews
- Lanczos3 filtering for best quality
- Optimized preview window size

### Performance
- 5 micro workers for small tasks
- 10 macro workers for large operations
- Automatic retry for failed operations

## Usage

```bash
# Basic usage
y

# Launch with directory persistence (cd on exit)
yy

# Navigate to specific directory
y ~/Documents
```

## Key Bindings (Default)

- `j/k` - Move down/up
- `h/l` - Go to parent/child directory
- `space` - Select/deselect file
- `y` - Copy selected files
- `d` - Cut selected files
- `p` - Paste files
- `r` - Rename file
- `q` - Quit

## Documentation

- [Yazi Docs](https://yazi-rs.github.io/docs/configuration/overview/)
- [Catppuccin Flavor](https://github.com/yazi-rs/flavors/tree/main/catppuccin-mocha.yazi)
- [Yazi GitHub](https://github.com/sxyazi/yazi)
