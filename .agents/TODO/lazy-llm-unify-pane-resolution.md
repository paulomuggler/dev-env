---
slug: lazy-llm-unify-pane-resolution
title: "Unify pane resolution logic into shared library"
priority: P1
status: pending
created: 2026-03-06
updated: 2026-03-06
depends-on: []
tags: [lazy-llm, refactor, phase-1]
---

# Unify pane resolution logic into shared library

## Context
Pane resolution (finding the AI pane and prompt pane from tmux window options) is implemented differently in every script:

- `llm-add`, `llm-cycle`, `llm-remove`: use `TMUX_PANE` with fallback to `tmux display-message -p`
- `llm-send`, `llm-pull`, `llm-append`: only check `TMUX_PANE`, no fallback (breaks in `run-shell` context)
- `note.lua`: has its own inline bash script for pane resolution
- nvim `llmk` keypress handler: yet another inline bash approach

This should be a single shared shell library that all scripts source.

## Key Files
- `external/lazy-llm/llm-send-bin/.local/bin/llm-send` — lines 4-24
- `external/lazy-llm/llm-send-bin/.local/bin/llm-pull` — lines 7-21
- `external/lazy-llm/llm-send-bin/.local/bin/llm-append` — lines 15-29
- `external/lazy-llm/llm-add-bin/.local/bin/llm-add` — lines 36-57
- `external/lazy-llm/llm-cycle-bin/.local/bin/llm-cycle` — lines 12-28
- `external/lazy-llm/llm-remove-bin/.local/bin/llm-remove` — lines 16-33

## Acceptance Criteria
- [ ] Create a shared library (e.g., `lazy-llm-lib.sh` or similar) with functions: `resolve_current_pane()`, `resolve_ai_pane()`, `resolve_prompt_pane()`, `resolve_session_window()`, `validate_pane_alive()`
- [ ] All scripts source the shared library instead of duplicating pane resolution
- [ ] The `TMUX_PANE` fallback to `tmux display-message -p` is used consistently everywhere
- [ ] All scripts prefer `@AI_PANE_ID` / `@PROMPT_PANE_ID` (stable pane IDs)
- [ ] The shared library is installed via stow alongside the other bin scripts
- [ ] Existing tests still pass
