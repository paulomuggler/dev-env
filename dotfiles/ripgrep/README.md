# Ripgrep Configuration

Fast line-oriented search tool that recursively searches directories for regex patterns. Respects gitignore rules by default.

## Features

- **Blazing Fast**: Written in Rust, faster than grep, ag, ack
- **Smart Defaults**: Respects .gitignore, skips hidden files and binary files
- **Powerful Regex**: Full regex support with PCRE2 mode available
- **Color Output**: Beautiful colored output with context

## Shell Integration

The `ripgrep.sh` file provides convenient aliases:

### Basic Aliases
- `rgi` - Case-insensitive search
- `rga` - Search all files (including ignored/hidden)
- `rgf` - List files that would be searched
- `rgl` - List only filenames with matches
- `rgc` - Count matches per file

### Context Aliases
- `rg3` - Search with 3 lines of context
- `rg5` - Search with 5 lines of context

### File Type Aliases
- `rgjs` - Search JavaScript files only
- `rgpy` - Search Python files only
- `rgmd` - Search Markdown files only
- `rgsh` - Search shell scripts only

### Advanced Functions
- `rgfzf` - Interactive ripgrep with fzf preview (requires fzf and bat)

## Usage Examples

```bash
# Basic search
rg "TODO"

# Case-insensitive search
rgi "fixme"

# Search with context
rg3 "function"

# Search specific file types
rgpy "import"

# Search all files including ignored
rga "secret"

# Interactive search with preview
rgfzf "pattern"
```

## Common Flags

- `-i` - Case-insensitive
- `-v` - Invert match
- `-w` - Match whole words
- `-c` - Count matches
- `-l` - Files with matches
- `-A N` - Show N lines after
- `-B N` - Show N lines before
- `-C N` - Show N lines context
- `--hidden` - Search hidden files
- `--no-ignore` - Don't respect gitignore

## Documentation

- [Ripgrep GitHub](https://github.com/BurntSushi/ripgrep)
- [User Guide](https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md)
