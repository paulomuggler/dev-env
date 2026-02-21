# Shell Review Guide

## Metadata
- **Type:** language
- **Extensions:** .sh, .bash, .zsh
- **Updated:** 2026-02-21

## Categories

### Security

- **Quote all variable expansions** — unquoted variables undergo word splitting and glob expansion. This is the #1 source of shell bugs and injection vulnerabilities.
  ```bash
  # Bad — breaks on spaces, globs interpreted
  rm $file
  cp $source $dest
  if [ $var = "value" ]; then

  # Good
  rm "$file"
  cp "$source" "$dest"
  if [ "$var" = "value" ]; then
  ```

- **No `eval` with user-controlled input** — same as any language. `eval` executes arbitrary code.
  ```bash
  # Bad
  eval "$user_input"

  # Good — use arrays for dynamic commands
  cmd=("docker" "exec" "$container" "$command")
  "${cmd[@]}"
  ```

- **Validate and sanitize inputs** — script arguments and environment variables are untrusted. Check they match expected patterns before use in commands, paths, or SQL.
  ```bash
  # Bad — argument used directly in path
  cat "/data/$1/config"

  # Good — validate first
  [[ "$1" =~ ^[a-zA-Z0-9_-]+$ ]] || { echo "Invalid name"; exit 1; }
  cat "/data/$1/config"
  ```

- **Don't store secrets in scripts** — no hardcoded passwords, tokens, or API keys. Source from environment, files, or secret managers.

- **`curl | bash` is dangerous** — downloading and piping directly to shell execution. If you must, verify checksums or use locked package managers instead.

- **Careful with `rm -rf`** — always use a variable with a guard. An empty variable in `rm -rf "$dir/"` becomes `rm -rf /`.
  ```bash
  # Bad — if WORKDIR is empty, this deletes /
  rm -rf "$WORKDIR/"

  # Good — guard against empty
  [[ -n "$WORKDIR" ]] || { echo "WORKDIR not set"; exit 1; }
  rm -rf "$WORKDIR/"
  ```

### Correctness

- **Start with `set -euo pipefail`** — the essential safety net for bash scripts.
  - `set -e` — exit on any command failure
  - `set -u` — error on undefined variables
  - `set -o pipefail` — pipeline fails if any command in the pipe fails (not just the last)
  ```bash
  #!/usr/bin/env bash
  set -euo pipefail
  ```

- **Shebang line** — use `#!/usr/bin/env bash` for portability, not `#!/bin/bash` (which may not exist on NixOS, Alpine, etc.). Use `#!/bin/sh` only if the script is POSIX-compatible (no bashisms).

- **Exit codes** — check return codes of commands, especially `docker`, `git`, `curl`. Under `set -e`, unchecked failures abort the script, which is usually what you want. But commands in conditionals (`if cmd; then`) don't trigger `set -e` — handle their failure explicitly.

- **Array vs string for multi-word values** — strings break on spaces. Use arrays for command arguments, file lists, or any multi-word data.
  ```bash
  # Bad — breaks on spaces in filenames
  files="file one.txt file two.txt"
  for f in $files; do echo "$f"; done

  # Good
  files=("file one.txt" "file two.txt")
  for f in "${files[@]}"; do echo "$f"; done
  ```

- **`[[ ]]` vs `[ ]`** — use `[[ ]]` in bash scripts. It handles empty strings, pattern matching, and regex without the quoting pitfalls of `[ ]`.
  ```bash
  # Bad — fails if $var is empty
  [ $var = "value" ]

  # Good
  [[ "$var" = "value" ]]
  ```

- **Subshell variable scope** — variables set inside a pipeline subshell are invisible to the parent. This is a common gotcha with `while read` loops.
  ```bash
  # Bad — count is always 0 after the loop
  count=0
  cat file | while read -r line; do
    ((count++))
  done
  echo "$count"  # still 0!

  # Good — redirect instead of pipe
  count=0
  while read -r line; do
    ((count++))
  done < file
  echo "$count"
  ```

- **`local` variables in functions** — without `local`, variables leak to the calling scope. Always declare function-scoped variables with `local`.

- **Temporary files** — use `mktemp` instead of hardcoded paths. Clean up in a trap.
  ```bash
  tmpfile=$(mktemp)
  trap 'rm -f "$tmpfile"' EXIT
  ```

### Error Handling

- **Trap for cleanup** — register cleanup functions with `trap` on EXIT, ERR, or INT to ensure temporary files, background processes, and locks are cleaned up.
  ```bash
  cleanup() {
    rm -f "$tmpfile"
    kill "$bg_pid" 2>/dev/null || true
  }
  trap cleanup EXIT
  ```

- **Meaningful error messages** — when exiting on failure, print what went wrong and what to do about it.
  ```bash
  # Bad
  command || exit 1

  # Good
  command || { echo "Error: failed to connect to database. Is it running?" >&2; exit 1; }
  ```

- **Redirect errors to stderr** — user-facing error messages go to stderr (`>&2`), not stdout. This preserves stdout for pipeable data.

- **Check command existence** — before using external commands, verify they're available.
  ```bash
  command -v docker >/dev/null 2>&1 || { echo "docker is required but not installed" >&2; exit 1; }
  ```

### Performance

- **Avoid unnecessary subshells** — `$(cat file)` can often be replaced with `< file`. Backticks and `$()` fork a subshell.

- **Don't parse `ls` output** — use globs or `find` instead. `ls` output is locale-dependent and breaks on special characters.
  ```bash
  # Bad
  for f in $(ls *.txt); do

  # Good
  for f in *.txt; do
  ```

- **Prefer built-in string manipulation** — bash has `${var#pattern}`, `${var%pattern}`, `${var/search/replace}`. No need to fork `sed` or `awk` for simple transformations.

- **Avoid loops for bulk operations** — if you're looping over files to `grep`, `sed`, or `awk` each one, the tool likely supports multiple files or `find -exec` directly.

### Code Quality

- **Consistent indentation** — 2 or 4 spaces, not tabs. Be consistent within the file.

- **Functions for reusable logic** — if a block of code appears more than once, extract to a function. Functions also make the main script flow readable.

- **Descriptive variable names** — `$d` is not a variable name. Use `$database_name`, `$container_id`, etc.

- **Readonly for constants** — use `readonly` or `declare -r` for values that shouldn't change.
  ```bash
  readonly PROJECT_DIR="/home/user/project"
  readonly DB_CONTAINER="taskmill-dolt"
  ```

- **Script documentation** — a comment at the top explaining what the script does, expected arguments, and environment variables.

### Comment Hygiene

- **Stale environment variable references** — comments mentioning env vars that have been renamed or removed.
- **Commented-out commands** — delete them, git has history.
- **TODO/FIXME** — either do the fix or track it. Don't leave indefinite TODOs in operational scripts.

## Anti-Patterns

| Pattern | Severity | Fix |
|---------|----------|-----|
| Unquoted variable expansion | Critical | Always quote: `"$var"` |
| `eval` with external input | Critical | Use arrays for dynamic commands |
| `rm -rf` with unchecked variable | Critical | Guard against empty var |
| Missing `set -euo pipefail` | Warning | Add to script header |
| No shebang / wrong shebang | Warning | `#!/usr/bin/env bash` |
| Variables in pipelines (subshell scope) | Warning | Use redirect instead of pipe |
| Missing cleanup trap | Warning | `trap cleanup EXIT` |
| Parsing `ls` output | Warning | Use globs or find |
| Hardcoded temp file paths | Warning | Use `mktemp` |
| `[ ]` instead of `[[ ]]` in bash | Suggestion | Use `[[ ]]` |
| Missing `local` in functions | Suggestion | Declare with `local` |
| Cryptic variable names | Nit | Use descriptive names |
