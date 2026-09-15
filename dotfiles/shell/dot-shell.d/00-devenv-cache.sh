# 00-devenv-cache.sh - shell-init caching helpers
#
# Sourced first (the 00- prefix orders it ahead of the tool configs). Provides:
#
#   devenv_cache_eval <name> <command> [args...]
#       Run <command> once, cache its stdout, and source the cache on every
#       later shell. Re-generates when the command's binary changes.
#
#   devenv_cache_clear
#       Throw the cache away; the next shell regenerates it.
#
# WHY: a login shell that runs `starship init`, `mise activate`, `gh completion`,
# `glab completion`, `opencode completion`, `pyenv init` and `rbenv init` pays
# for seven process launches before it shows a prompt. Most of those emit the
# same bytes every time. `opencode completion` alone costs ~1.2s, and `gh` under
# a mise shim can cost seconds when mise decides to re-resolve the tool.
#
# The cache key is the resolved binary's path, size and mtime, so upgrading a
# tool invalidates it. A tool that changes its completion output without the
# binary changing (a mise shim whose underlying version moved, say) needs an
# explicit `devenv_cache_clear`.

DEVENV_CACHE_DIR="${XDG_CACHE_HOME:-${HOME}/.cache}/devenv/shell-init"

devenv_cache_eval() {
  local name="$1"
  shift

  local bin_path stamp cache stamp_file
  bin_path="$(command -v "$1" 2>/dev/null)" || return 1
  [[ -n "${bin_path}" ]] || return 1

  cache="${DEVENV_CACHE_DIR}/${name}.bash"
  stamp_file="${DEVENV_CACHE_DIR}/${name}.stamp"

  # GNU stat first, BSD/macOS stat second. -L so a shim symlink is followed.
  stamp="$(stat -Lc '%n %s %Y' "${bin_path}" 2>/dev/null \
    || stat -Lf '%N %z %m' "${bin_path}" 2>/dev/null)"

  if [[ -r "${cache}" ]] && [[ "${stamp}" == "$(<"${stamp_file}")" ]] 2>/dev/null; then
    source "${cache}"
    return 0
  fi

  mkdir -p "${DEVENV_CACHE_DIR}" || return 1

  if "$@" >"${cache}.tmp" 2>/dev/null && [[ -s "${cache}.tmp" ]]; then
    mv -f "${cache}.tmp" "${cache}"
    printf '%s\n' "${stamp}" >"${stamp_file}"
    source "${cache}"
    return 0
  fi

  # Generation failed: leave no half-written cache behind and do nothing. The
  # next shell tries again; a tool that cannot emit its own init is not worth
  # blocking a prompt for.
  rm -f "${cache}.tmp"
  return 1
}

devenv_cache_clear() {
  rm -rf "${DEVENV_CACHE_DIR}"
  echo "dev-env shell-init cache cleared (${DEVENV_CACHE_DIR})"
}

# True when Omarchy's own bash rc has already initialised a tool, so the
# dev-env config for it can skip a duplicate init. Omarchy 4's
# $OMARCHY_PATH/default/bash/init runs mise, starship, zoxide and fzf.
devenv_omarchy_bash_defaults() {
  [[ -n "${OMARCHY_PATH:-}" ]] && [[ -r "${OMARCHY_PATH}/default/bash/init" ]]
}
