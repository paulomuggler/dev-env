---
slug: lazy-llm-scope-tmux-keybindings
title: "Scope tmux keybindings to avoid conflicts"
priority: P2
status: done
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
- `external/lazy-llm/lazy-llm-bin/.local/bin/lazy-llm` — lines 187-214

## Acceptance Criteria
- [x] Document the keybinding conflicts in README
- [x] Consider alternative default bindings that don't clash (or make them configurable)
- [x] `Prefix+A` should respect current context (prompt for tool name rather than hardcoding claude)
- [x] Investigate whether conditional `bind-key` with `if-shell` can detect lazy-llm windows

## Work Report

**Date:** 2026-03-06

### What was done
- Wrapped all 6 tmux keybindings with `if-shell` to check for `@AI_PANES` window option
- `C-n`/`C-p` now fall back to tmux default `next-window`/`previous-window` in non-lazy-llm windows
- `C-x`, `S`, `L` are no-ops in non-lazy-llm windows
- `Prefix+A` now shows a `display-menu` tool picker (claude, gemini, codex, grok, aider) instead of hardcoding claude
- Updated README to document all 6 keybindings including previously undocumented `S` and `L`, and noted the scoping behavior

### How it was done
Used `tmux if-shell "tmux show-option -wqv @AI_PANES" <command> [fallback]`. The `-q` flag suppresses errors, `-w` checks window-scope, `-v` returns only the value. If the option exists (non-empty), the command runs; otherwise the fallback runs (for C-n/C-p) or nothing happens.

### Decisions made
- **`if-shell` over custom key table:** `if-shell` is simpler and doesn't require managing custom tmux key tables. The overhead (~1ms per keypress) is negligible.
- **`display-menu` for tool picker:** Chose tmux's built-in `display-menu` over a fzf popup for tool selection — it's lighter weight and doesn't spawn a subprocess.
- **Keep same key bindings:** Rather than changing to different keys, kept `C-n`/`C-p` with graceful fallback to tmux defaults, maintaining muscle memory for lazy-llm users.

### Files changed
- `lazy-llm-bin/.local/bin/lazy-llm` — replaced 6 unconditional `bind-key` calls with `if-shell`-wrapped versions
- `README.md` — updated keybinding documentation table and added scoping note

### Follow-up
- None
