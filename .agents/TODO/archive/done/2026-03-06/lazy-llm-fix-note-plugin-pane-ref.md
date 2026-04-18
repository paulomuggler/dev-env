---
slug: lazy-llm-fix-note-plugin-pane-ref
title: "Fix note plugin to use stable pane IDs"
priority: P1
status: done
created: 2026-03-06
updated: 2026-03-06
depends-on: []
tags: [lazy-llm, bugfix, phase-1]
---

# Fix note plugin to use stable pane IDs

## Context
`note.lua` line 42 reads `@PROMPT_PANE` (legacy index-based reference) rather than `@PROMPT_PANE_ID` (stable pane ID). The rest of the codebase has migrated to pane IDs. If panes are reordered, notes will be sent to the wrong pane.

Also, `is_prompt_pane()` compares `TMUX_PANE` against the legacy `@PROMPT_PANE` value (an index like `session:0.2`) instead of the pane ID format (`%N`). This comparison will never match correctly since `TMUX_PANE` is always a pane ID.

## Key Files
- `external/lazy-llm/nvim-note-plugin/.config/nvim/lua/plugins/note.lua` — `is_prompt_pane()` (line 28-46), `send_notes_to_prompt()` (lines 210-232)

## Acceptance Criteria
- [x] `is_prompt_pane()` uses `@PROMPT_PANE_ID` for comparison
- [x] `send_notes_to_prompt()` uses `@PROMPT_PANE_ID` to target the prompt pane
- [x] Both functions fall back gracefully if `@PROMPT_PANE_ID` is not set
- [x] Cross-pane note collection (prompt pane → editor pane) works correctly

## Work Report

**Date:** 2026-03-06

### What was done
- Fixed `is_prompt_pane()` to read `@PROMPT_PANE_ID` (pane ID format `%N`) for comparison with `TMUX_PANE`, with fallback to legacy `@PROMPT_PANE`
- Fixed `send_notes_to_prompt()` inline bash to prefer `@PROMPT_PANE_ID` with fallback chain: `@PROMPT_PANE_ID` → `@PROMPT_PANE` → `:.2`

### How it was done
- Matched the pattern used by `llm-send`, `llm-pull`, `llm-append`: prefer stable pane ID, fall back to legacy index

### Decisions made
- Kept the legacy fallback for backward compatibility with sessions created before the pane ID migration

### Files changed
- `external/lazy-llm/nvim-note-plugin/.config/nvim/lua/plugins/note.lua` — Updated `is_prompt_pane()` and `send_notes_to_prompt()`

### Follow-up
- None
