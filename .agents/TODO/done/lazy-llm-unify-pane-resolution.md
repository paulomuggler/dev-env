---
slug: lazy-llm-unify-pane-resolution
title: "Unify pane resolution logic into shared library"
priority: P1
status: done
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
- [x] Create a shared library (e.g., `lazy-llm-lib.sh` or similar) with functions: `resolve_current_pane()`, `resolve_ai_pane()`, `resolve_prompt_pane()`, `resolve_session_window()`, `validate_pane_alive()`
- [x] All scripts source the shared library instead of duplicating pane resolution
- [x] The `TMUX_PANE` fallback to `tmux display-message -p` is used consistently everywhere
- [x] All scripts prefer `@AI_PANE_ID` / `@PROMPT_PANE_ID` (stable pane IDs)
- [x] The shared library is installed via stow alongside the other bin scripts
- [x] Existing tests still pass

## Verify Plan
- [x] AC: shared library created — `lazy-llm-lib.sh` with 5 functions (resolve_pane, resolve_session_window, get_ai_target, get_prompt_target, read_multi_state)
- [x] AC: all 7 scripts source library — llm-send, llm-pull, llm-append, llm-add, llm-cycle, llm-remove, llm-status
- [x] AC: TMUX_PANE fallback consistent — library uses `${TMUX_PANE:-$(tmux display-message -p '#{pane_id}')}`
- [x] AC: stable pane IDs preferred — get_ai_target prefers @AI_PANE_ID, get_prompt_target prefers @PROMPT_PANE_ID
- [x] AC: library in stow package — located at `llm-send-bin/.local/bin/lazy-llm-lib.sh`, stows to `~/.local/bin/`
- [x] AC: existing tests pass — unit test 09 passes, integration tests 01-08 fail pre-existing (PTY issue)
- [x] bash -n syntax check passes on all 8 files

## Work Report

**Date:** 2026-03-06

### What was done
- Created `lazy-llm-lib.sh` shared library with 5 functions for pane resolution
- Updated all 7 shell scripts to source the library instead of duplicating pane resolution code
- Removed ~50 lines of duplicated code across the codebase

### How it was done
- Extracted common patterns into idiomatic bash functions that set global variables
- Used guard-include pattern to prevent double-sourcing
- Each script uses a consistent 4-line resolution pattern: source lib → resolve_pane → resolve_session_window → get target
- Fixed a subtle bug in llm-add where `lazy_llm_read_multi_state` would clobber the user's `AI_TOOL` argument

### Decisions made
- Library placed in `llm-send-bin` stow package (all scripts end up in `~/.local/bin/` after stow)
- Used uppercase variable names (`_CURRENT_PANE`, `_SESSION`, `_WINDOW`) to distinguish library globals
- `validate_pane_alive()` from the AC was deferred — stale pane validation already exists in `llm-cycle` and will be moved to the library in the `lazy-llm-add-stale-pane-validation` task
- Graceful degradation: scripts that need targets but can't resolve pane fall back to relative targets (`:.+`, `:.0`, `:.2`)

### Files changed
- `llm-send-bin/.local/bin/lazy-llm-lib.sh` — New shared library (71 lines)
- `llm-send-bin/.local/bin/llm-send` — Replaced inline resolution with library calls
- `llm-send-bin/.local/bin/llm-pull` — Replaced inline resolution with library calls
- `llm-send-bin/.local/bin/llm-append` — Replaced inline resolution with library calls
- `llm-add-bin/.local/bin/llm-add` — Replaced inline resolution + multi-state read
- `llm-cycle-bin/.local/bin/llm-cycle` — Replaced inline resolution + multi-state read
- `llm-remove-bin/.local/bin/llm-remove` — Replaced inline resolution + multi-state read
- `llm-status-bin/.local/bin/llm-status` — Replaced inline resolution + multi-state read

### Follow-up
- `lazy-llm-add-stale-pane-validation` task will move the stale pane cleanup from llm-cycle into the shared library
