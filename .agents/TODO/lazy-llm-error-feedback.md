---
slug: lazy-llm-error-feedback
title: "Surface errors from async commands to the user"
priority: P2
status: pending
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
- [ ] `jobstart` calls use `on_exit` callback to check exit code before showing success notification
- [ ] Failed commands show an error notification (`vim.log.levels.ERROR`) with the failure reason
- [ ] Consider using `detach = false` for commands where we need the result (add, remove, cycle)
- [ ] tmux `run-shell` errors are surfaced (e.g., via `display-message` on failure)
