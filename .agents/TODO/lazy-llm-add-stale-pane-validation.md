---
slug: lazy-llm-add-stale-pane-validation
title: "Add stale pane validation to all scripts"
priority: P1
status: pending
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
- [ ] Shared `validate_pane_alive()` function exists in the shared library
- [ ] `llm-send` validates the AI pane exists before sending (with useful error message)
- [ ] `llm-pull` validates the AI pane exists before capturing
- [ ] `llm-append` validates the prompt pane exists before appending
- [ ] `llm-remove` validates pane state before attempting removal
- [ ] Stale pane pruning (from `llm-cycle`) is available as a shared function
