---
slug: lazy-llm-add-stale-pane-validation
title: "Add stale pane validation to all scripts"
priority: P1
status: done
created: 2026-03-06
updated: 2026-03-06
depends-on: [lazy-llm-unify-pane-resolution]
tags: [lazy-llm, robustness, phase-1]
---

# Add stale pane validation to all scripts

## Context
`llm-cycle` has stale pane validation (lines 46-76) that checks if pane IDs still exist and prunes dead entries. However, `llm-remove`, `llm-send`, `llm-pull`, and `llm-append` do NOT validate panes before using them. If a pane dies (user closes it, AI tool crashes), these scripts fail silently or send to wrong targets.

The validation logic in `llm-cycle` should be extracted into the shared library (depends on `lazy-llm-unify-pane-resolution`) and called from all scripts.

## Key Files
- `external/lazy-llm/llm-cycle-bin/.local/bin/llm-cycle` — lines 46-76 (existing validation)
- `external/lazy-llm/llm-send-bin/.local/bin/llm-send` — no validation
- `external/lazy-llm/llm-send-bin/.local/bin/llm-pull` — no validation
- `external/lazy-llm/llm-send-bin/.local/bin/llm-append` — no validation
- `external/lazy-llm/llm-remove-bin/.local/bin/llm-remove` — no validation

## Acceptance Criteria
- [x] Shared `validate_pane_alive()` function exists in the shared library
- [x] `llm-send` validates the AI pane exists before sending (with useful error message)
- [x] `llm-pull` validates the AI pane exists before capturing
- [x] `llm-append` validates the prompt pane exists before appending
- [x] `llm-remove` validates pane state before attempting removal
- [x] Stale pane pruning (from `llm-cycle`) is available as a shared function

## Work Report

**Date:** 2026-03-06

### What was done
- Added `lazy_llm_validate_pane()` and `lazy_llm_prune_stale_panes()` to the shared library
- llm-send, llm-pull, llm-append now validate target pane liveness before operating
- llm-cycle's 30-line inline validation replaced with single library call
- llm-remove prunes stale panes before removal logic

### How it was done
- `lazy_llm_validate_pane()`: thin wrapper around `tmux display-message -t` liveness check
- `lazy_llm_prune_stale_panes()`: extracted from llm-cycle, iterates AI_PANES, removes dead entries, updates tmux window options and globals
- Single-target scripts (send/pull/append) use validate_pane for early exit with error message
- Multi-pane scripts (cycle/remove) use prune_stale_panes for list cleanup

### Decisions made
- validate_pane returns shell exit codes (0=alive, 1=dead) — idiomatic for `if` checks
- prune_stale_panes always returns 0 (callers inspect state after call rather than return code)
- Kept separate validate_pane vs prune_stale_panes since they serve different use cases

### Files changed
- `llm-send-bin/.local/bin/lazy-llm-lib.sh` — Added 2 functions (~45 lines)
- `llm-send-bin/.local/bin/llm-send` — Added pane validation
- `llm-send-bin/.local/bin/llm-pull` — Added pane validation
- `llm-send-bin/.local/bin/llm-append` — Added pane validation
- `llm-cycle-bin/.local/bin/llm-cycle` — Replaced inline validation with library call (-25 lines)
- `llm-remove-bin/.local/bin/llm-remove` — Added prune call
