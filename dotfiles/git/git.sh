# git.sh - Git configuration and aliases
# This file is symlinked to shell.d/ and sourced by .bashrc

# Quick git status
alias stt='git status'

# Get current git branch name
# Returns empty string if not in a git repository
git_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
}
