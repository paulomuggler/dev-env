---
slug: lazy-llm-conditional-nvim-keymaps
title: "Make nvim keymaps conditional on tmux/lazy-llm context"
priority: P2
status: pending
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
- [ ] Plugin keymaps only activate when inside a tmux session (check `$TMUX` env var)
- [ ] Ideally, keymaps only activate when in a lazy-llm workspace window (check for `@AI_PANE_ID` window option)
- [ ] The `@` insert-mode keymap does not interfere with normal nvim usage outside lazy-llm
- [ ] Graceful degradation: commands show a helpful message if invoked outside a lazy-llm context
