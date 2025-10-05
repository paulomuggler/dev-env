# fd Configuration

Fast and user-friendly alternative to `find`. Written in Rust, with intuitive syntax and smart defaults.

## Features

- **Fast**: Parallel directory traversal
- **Smart Defaults**: Ignores hidden files and respects .gitignore
- **Colored Output**: Syntax highlighting for results
- **Intuitive Syntax**: No need for `-name` or complex flags

## Shell Integration

The `fd.sh` file provides convenient aliases and functions:

### Basic Aliases
- `fda` - Search all files (including hidden/ignored)
- `fdd` - Find directories only
- `fdf` - Find files only
- `fdx` - Find executables only
- `fdl` - Find symlinks only
- `fdcas` - Case-sensitive search
- `fdfull` - Search full path (not just filename)
- `fdext` - Find by extension

### Useful Functions
- `fdexec <pattern> <command>` - Find and execute command on results
- `fdrecent [days]` - Find files modified in last N days (default: 7)
- `fdlarge [size_mb]` - Find files larger than N MB (default: 100)
- `fdfzf [pattern]` - Interactive file finder with preview (requires fzf + bat)
- `fddir [pattern]` - Interactive directory finder and cd (requires fzf)

## Usage Examples

```bash
# Basic search
fd pattern

# Find JavaScript files
fd -e js

# Find in specific directory
fd pattern ~/Documents

# Find directories only
fdd config

# Find files modified in last 3 days
fdrecent 3

# Find large files (>50MB)
fdlarge 50

# Interactive file search with preview
fdfzf

# Interactive directory navigation
fddir

# Find and execute command
fdexec '.log$' rm
```

## Common Options

- `-e, --extension` - Filter by file extension
- `-t, --type` - Filter by type (f=file, d=directory, l=symlink, x=executable)
- `-H, --hidden` - Include hidden files
- `-I, --no-ignore` - Don't respect .gitignore
- `-d, --max-depth` - Set maximum search depth
- `-x, --exec` - Execute command on results
- `-s, --case-sensitive` - Case-sensitive search (default: smart case)

## fd vs find

```bash
# Find all JavaScript files (fd vs find)
fd -e js
find . -name '*.js'

# Find directories named 'src' (fd vs find)
fd -t d src
find . -type d -name 'src'

# Find files modified in last day (fd vs find)
fd --changed-within 1d
find . -mtime -1
```

## Documentation

- [fd GitHub](https://github.com/sharkdp/fd)
- [fd Documentation](https://github.com/sharkdp/fd#usage)
