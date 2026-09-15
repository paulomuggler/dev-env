# starship.sh - Starship prompt configuration
# This file is symlinked to shell.d/ and sourced by .bashrc

# Omarchy 4's own bash init already runs `starship init bash`; initialising it
# twice stacks a second DEBUG trap and PROMPT_COMMAND entry.
if declare -F starship_precmd >/dev/null 2>&1; then
  :
elif command -v starship &>/dev/null; then
  # --print-full-init is the actual payload; plain `starship init bash` is only
  # a wrapper that shells out to it, so caching that would save nothing.
  devenv_cache_eval starship starship init bash --print-full-init
fi
