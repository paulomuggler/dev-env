# fd.sh - fd (fast find) configuration
# This file is symlinked to shell.d/ and sourced by .bashrc

# fd is available as 'fd' command (user-friendly find alternative)

# Useful fd aliases
alias fda='fd --no-ignore --hidden'               # Search all files including ignored
alias fdd='fd --type d'                           # Find directories only
alias fdf='fd --type f'                           # Find files only
alias fdx='fd --type x'                           # Find executables only
alias fdl='fd --type l'                           # Find symlinks only

# Case-sensitive search
alias fdcas='fd --case-sensitive'

# Search with full path
alias fdfull='fd --full-path'

# Find with extension
alias fdext='fd --extension'

# Useful functions

# Find and execute command on results
function fdexec() {
  if [ -z "$1" ]; then
    echo "Usage: fdexec <pattern> <command>"
    echo "Example: fdexec '.js$' cat"
    return 1
  fi

  local pattern="$1"
  shift
  fd "$pattern" --exec "$@"
}

# Find files modified in last N days
function fdrecent() {
  local days="${1:-7}"
  fd --type f --changed-within "${days}d"
}

# Find large files (size in MB)
function fdlarge() {
  local size="${1:-100}"
  fd --type f --size "+${size}m"
}

# fd with fzf integration (if fzf is installed)
if command -v fzf &> /dev/null; then
  # Interactive file finder with preview
  function fdfzf() {
    fd --type f --hidden --follow --exclude .git "${@:-.}" |
      fzf --preview 'bat --color=always --style=numbers --line-range=:500 {}' \
          --preview-window 'right:60%'
  }

  # Interactive directory finder
  function fddir() {
    local dir
    dir=$(fd --type d --hidden --follow --exclude .git "${@:-.}" |
          fzf --preview 'ls -la {}' --preview-window 'right:60%')
    [ -n "$dir" ] && cd "$dir"
  }
fi
