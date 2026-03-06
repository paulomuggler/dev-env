---
slug: lazy-llm-scope-tmux-keybindings
title: "Scope tmux keybindings to avoid conflicts"
priority: P2
status: pending
created: 2026-03-06
updated: 2026-03-06
depends-on: []
tags: [lazy-llm, ux, phase-1]
---

# Scope tmux keybindings to avoid conflicts

## Context
`lazy-llm` registers global tmux keybindings:
- `Prefix+C-n` (conflicts with tmux default `next-window`)
- `Prefix+C-p` (conflicts with tmux default `previous-window`)
- `Prefix+C-x` (may conflict with user bindings)
- `Prefix+A` (add AI pane, hardcoded to claude)

These are set via `tmux bind-key -T prefix` which is global — they persist even after the lazy-llm window is closed and override user's existing bindings.

## Key Files
- `external/lazy-llm/lazy-llm-bin/.local/bin/lazy-llm` — lines 175-178, 351-354

## Acceptance Criteria
- [ ] Document the keybinding conflicts in README
- [ ] Consider alternative default bindings that don't clash (or make them configurable)
- [ ] `Prefix+A` should respect current context (prompt for tool name rather than hardcoding claude)
- [ ] Investigate whether conditional `bind-key` with `if-shell` can detect lazy-llm windows
