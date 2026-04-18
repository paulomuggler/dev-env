---
slug: lazy-llm-holding-window-resilience
title: "Make holding window pattern more resilient"
priority: P3
status: done
created: 2026-03-06
updated: 2026-03-06
depends-on: [lazy-llm-unify-pane-resolution]
tags: [lazy-llm, robustness, phase-4]
---

# Make holding window pattern more resilient

## Context
Inactive AI panes live in a hidden `_hold_N` tmux window. This pattern is functional but fragile:
- If the holding window is accidentally closed/renamed, the pane list becomes orphaned
- If tmux-resurrect restores stale sessions, holding windows may reference dead panes
- There's no self-healing mechanism

## Key Files
- `external/lazy-llm/llm-send-bin/.local/bin/lazy-llm-lib.sh` — shared library
- `external/lazy-llm/llm-add-bin/.local/bin/llm-add` — holding window creation
- `external/lazy-llm/llm-cycle-bin/.local/bin/llm-cycle` — pane cycling

## Acceptance Criteria
- [x] Holding window existence is validated before use (not just by name, but by checking pane health)
- [x] If holding window is missing but pane list has entries, recreate the holding window
- [x] Stale panes in the holding window are pruned automatically (extend cycle's logic)
- [x] Consider tagging holding windows with a tmux option for reliable identification (not just name-based)

## Work Report

**Date:** 2026-03-06

### What was done
- Added `lazy_llm_validate_hold_win()` to shared library that validates and auto-recreates missing holding windows
- Changed holding window reference from name-based (`session:window_name`) to ID-based (`@N` window ID) for stability
- Extended `lazy_llm_prune_stale_panes()` to auto-clean empty holding windows when pane count drops to 1
- Added validation calls in `llm-add` and `llm-cycle`

### How it was done
- `lazy_llm_validate_hold_win()` uses `tmux display-message -t "$AI_HOLD_WIN"` to check if the window exists. If it's gone, recreates it with the same naming convention and captures the stable window ID.
- `llm-add` now stores `#{window_id}` (e.g., `@5`) instead of `session:window_name` in `@AI_HOLD_WIN`
- `lazy_llm_prune_stale_panes()` now checks if `total <= 1` after pruning and kills the holding window if so

### Decisions made
- **Window ID over name**: Window IDs (`@N`) are stable across renames. The previous approach used `session:_hold_N` which broke if windows were renamed.
- **Auto-cleanup on prune**: When stale pane pruning reduces the list to 1 or fewer panes, the holding window is no longer needed. Cleaning it up automatically prevents orphaned windows.
- **Tagging with `@lazy_llm_hold`**: Already implemented in prior work — holding windows are tagged with `@lazy_llm_hold "1"` for reliable identification.

### Files changed
- `llm-send-bin/.local/bin/lazy-llm-lib.sh` — added `lazy_llm_validate_hold_win()`, extended `lazy_llm_prune_stale_panes()`
- `llm-add-bin/.local/bin/llm-add` — store window ID, call validation
- `llm-cycle-bin/.local/bin/llm-cycle` — call validation after prune

### Follow-up
- None
