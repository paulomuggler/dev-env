---
slug: lazy-llm-deduplicate-main-script
title: "Deduplicate lazy-llm main script (standalone vs window path)"
priority: P1
status: pending
created: 2026-03-06
updated: 2026-03-06
depends-on: []
tags: [lazy-llm, refactor, phase-1]
---

# Deduplicate lazy-llm main script (standalone vs window path)

## Context
The `lazy-llm` main script has two nearly identical code paths: `create_workspace_window()` (lines 97-182) and the standalone session creation (lines 274-360). They duplicate:
- Pane splitting logic
- AI tool `case` statement (5 tools + wildcard)
- Nvim launch command for prompt pane
- Pane title setting
- Pane ID capture and state initialization
- Keybinding registration

The standalone path also sets `mouse on` (line 330) which the window-add path does not. This divergence causes behavioral differences.

## Key Files
- `external/lazy-llm/lazy-llm-bin/.local/bin/lazy-llm` — the main script

## Acceptance Criteria
- [ ] All shared logic lives in `create_workspace_window()` only — no duplication
- [ ] The standalone session path creates the session, calls the shared function, then attaches
- [ ] `mouse on` is set in both paths (or made configurable)
- [ ] The AI tool case statement exists exactly once
- [ ] Both paths produce identical workspace layouts and state
- [ ] Existing tests still pass
