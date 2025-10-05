# ripgrep.sh - ripgrep (rg) configuration
# This file is symlinked to shell.d/ and sourced by .bashrc

# Ripgrep is available as 'rg' command

# Useful ripgrep aliases
alias rgi='rg --ignore-case'                      # Case-insensitive search
alias rga='rg --no-ignore --hidden'               # Search all files including ignored
alias rgf='rg --files'                            # List files that would be searched
alias rgl='rg --files-with-matches'               # List only filenames with matches
alias rgc='rg --count'                            # Count matches per file

# Search with context
alias rg3='rg -C 3'                               # 3 lines of context
alias rg5='rg -C 5'                               # 5 lines of context

# Search specific file types
alias rgjs='rg --type js'                         # JavaScript files
alias rgpy='rg --type py'                         # Python files
alias rgmd='rg --type md'                         # Markdown files
alias rgsh='rg --type sh'                         # Shell scripts

# Ripgrep with fzf integration (if fzf is installed)
if command -v fzf &> /dev/null; then
  # Interactive ripgrep search
  function rgfzf() {
    rg --color=always --line-number --no-heading --smart-case "${*:-}" |
      fzf --ansi \
          --color "hl:-1:underline,hl+:-1:underline:reverse" \
          --delimiter : \
          --preview 'bat --color=always {1} --highlight-line {2}' \
          --preview-window 'up,60%,border-bottom,+{2}+3/3,~3'
  }
fi
