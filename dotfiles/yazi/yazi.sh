# yazi.sh - Yazi (terminal file manager) configuration
# This file is symlinked to shell.d/ and sourced by .bashrc

# Yazi wrapper function with shell integration
# Changes working directory when exiting yazi
function yy() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# Aliases for convenience
alias y='yazi'           # Quick launch
alias yy='yy'            # Launch with directory change on exit
alias ranger='yazi'      # For those used to ranger
