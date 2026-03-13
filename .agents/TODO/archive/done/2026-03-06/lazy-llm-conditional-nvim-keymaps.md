---
slug: lazy-llm-conditional-nvim-keymaps
title: "Make nvim keymaps conditional on tmux/lazy-llm context"
priority: P2
status: done
created: 2026-03-06
updated: 2026-03-06
depends-on: []
tags: [lazy-llm, ux, phase-4]
---

# Make nvim keymaps conditional on tmux/lazy-llm context

## Context
The nvim plugin attaches all keymaps via the `keys` table of the `LazyVim/LazyVim` plugin spec. This is unconventional — keymaps are globally active even when not in a lazy-llm tmux session (e.g., standalone nvim). The `@` insert-mode keymap is particularly problematic since it intercepts `@` globally.

A proper approach would use a `cond` function or lazy-load based on detecting a tmux environment with lazy-llm window options.

## Key Files
- `external/lazy-llm/nvim-llm-send-plugin/.config/nvim/lua/plugins/llm-send.lua` — entire plugin spec
- `external/lazy-llm/nvim-note-plugin/.config/nvim/lua/plugins/note.lua` — entire plugin spec

## Acceptance Criteria
- [x] Plugin keymaps only activate when inside a tmux session (check `$TMUX` env var)
- [x] Ideally, keymaps only activate when in a lazy-llm workspace window (check for `@AI_PANE_ID` window option)
- [x] The `@` insert-mode keymap does not interfere with normal nvim usage outside lazy-llm
- [x] Graceful degradation: commands show a helpful message if invoked outside a lazy-llm context

## Work Report

**Date:** 2026-03-06

### What was done
- Gated all keymaps in both nvim plugins on `vim.env.TMUX` check
- Gated the `init` function (InsertCharPre autocmd for `@` completion) in llm-send.lua
- Gated the `BufEnter` autocmd in note.lua for cross-pane buffer tracking

### How it was done
Used Lua's short-circuit evaluation: `vim.env.TMUX and { ... } or {}` for keys tables, `vim.env.TMUX and function() ... end or nil` for init. These evaluate at plugin load time — if `$TMUX` is unset, keymaps are never registered.

Could not use `cond` on the plugin spec because both plugins attach to `LazyVim/LazyVim` — disabling the spec would disable all of LazyVim. Gating the `keys` table itself is the correct approach.

### Decisions made
- **TMUX check over AI_PANE_ID check:** `vim.env.TMUX` is sufficient because (a) keymaps only make sense in tmux anyway, and (b) if no AI pane exists, the underlying commands fail gracefully with tmux error messages. A deeper `@AI_PANE_ID` check would require runtime tmux queries that are expensive at plugin load.
- **BufEnter autocmd gated:** The note plugin's buffer tracking autocmd is only useful inside tmux, so it's also gated to avoid unnecessary overhead in standalone nvim.

### Files changed
- `nvim-llm-send-plugin/.config/nvim/lua/plugins/llm-send.lua` — gated `keys` and `init` on `vim.env.TMUX`
- `nvim-note-plugin/.config/nvim/lua/plugins/note.lua` — gated `keys` and `BufEnter` autocmd on `vim.env.TMUX`

### Follow-up
- None
