---
slug: lazy-llm-error-feedback
title: "Surface errors from async commands to the user"
priority: P2
status: done
created: 2026-03-06
updated: 2026-03-06
depends-on: []
tags: [lazy-llm, ux, phase-4]
---

# Surface errors from async commands to the user

## Context
The nvim plugin uses `vim.fn.jobstart` with `detach = true` for many operations (cycle, add, remove panes). Errors are silently swallowed. The `vim.defer_fn` notifications fire unconditionally — e.g., "Cycled to next AI pane" appears even if the cycle command failed.

Similarly, tmux `run-shell` commands that fail show output in a brief flash that's easy to miss.

## Key Files
- `external/lazy-llm/nvim-llm-send-plugin/.config/nvim/lua/plugins/llm-send.lua` — all `jobstart` calls with `detach = true`

## Acceptance Criteria
- [x] `jobstart` calls use `on_exit` callback to check exit code before showing success notification
- [x] Failed commands show an error notification (`vim.log.levels.ERROR`) with the failure reason
- [x] Consider using `detach = false` for commands where we need the result (add, remove, cycle)
- [x] tmux `run-shell` errors are surfaced (e.g., via `display-message` on failure)

## Work Report

**Date:** 2026-03-06

### What was done
- Added `on_exit` callbacks to 10 `jobstart` calls in llm-send.lua
- Replaced 4 `detach=true` + `vim.defer_fn` patterns with tracked jobs that check exit codes
- Moved temp file cleanup from shell (`; rm -f`) to Lua (`vim.fn.delete` in `on_exit`) so cleanup always runs and errors aren't masked
- Failed commands now show `vim.log.levels.ERROR` notifications

### How it was done
Changed `detach=true` to tracked jobs (no `detach` option) with `on_exit` callbacks. The callback checks the exit code: code 0 shows INFO success notification, non-zero shows ERROR notification. `vim.schedule()` wraps notifications since `on_exit` runs in a callback context.

For temp file cleanup: removed `; rm -f` from the shell command (which masked llm-send errors) and used `vim.fn.delete(tmp)` in the `on_exit` callback instead — runs regardless of exit code.

### Decisions made
- **Keep 2 `detach=true` calls:** The slash command (line 328) and keypress forward (line 357) are true fire-and-forget — they don't show notifications and error feedback would add complexity without UX benefit.
- **tmux run-shell errors:** Already adequately handled by the `if-shell` scoping from the previous task. Scripts print errors to stderr which `run-shell` displays briefly.

### Files changed
- `nvim-llm-send-plugin/.config/nvim/lua/plugins/llm-send.lua` — added `on_exit` callbacks to 10 jobstart calls, removed shell-based temp file cleanup

### Follow-up
- None
