---
slug: lazy-llm-holding-window-resilience
title: "Make holding window pattern more resilient"
priority: P3
status: pending
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

The `llm-add` script checks if the holding window exists by grepping window names (line 66), but doesn't handle cases where the window exists but its panes are stale.

## Key Files
- `external/lazy-llm/llm-add-bin/.local/bin/llm-add` — holding window creation (lines 65-73)
- `external/lazy-llm/llm-remove-bin/.local/bin/llm-remove` — holding window cleanup (lines 137-141)
- `external/lazy-llm/llm-cycle-bin/.local/bin/llm-cycle` — stale pane pruning (lines 46-76)

## Acceptance Criteria
- [ ] Holding window existence is validated before use (not just by name, but by checking pane health)
- [ ] If holding window is missing but pane list has entries, recreate the holding window
- [ ] Stale panes in the holding window are pruned automatically (extend cycle's logic)
- [ ] Consider tagging holding windows with a tmux option for reliable identification (not just name-based)
