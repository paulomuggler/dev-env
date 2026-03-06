---
slug: lazy-llm-deduplicate-main-script
title: "Deduplicate lazy-llm main script (standalone vs window path)"
priority: P1
status: done
created: 2026-03-06
updated: 2026-03-06
depends-on: []
tags: [lazy-llm, refactor, phase-1]
---

# Deduplicate lazy-llm main script (standalone vs window path)

## Context
The `lazy-llm` main script previously had two nearly identical code paths: `create_workspace_window()` and the standalone session creation. They duplicated pane splitting, AI tool case statement, nvim launch, pane titles, state initialization, and keybinding registration.

## Key Files
- `external/lazy-llm/lazy-llm-bin/.local/bin/lazy-llm` — the main script

## Acceptance Criteria
- [x] All shared logic lives in `create_workspace_window()` only — no duplication
- [x] The standalone session path creates the session, calls the shared function, then attaches
- [x] `mouse on` is set in both paths (line 175, inside shared function)
- [x] The AI tool case statement exists exactly once (lines 120-140)
- [x] Both paths produce identical workspace layouts and state
- [x] Existing tests still pass (unit test 09 passes 19/19; integration tests 01-08 fail pre-existing — require live tmux)

## Verification
The script was already refactored prior to this verification pass. The standalone path (lines 262-271) creates a session, calls `create_workspace_window()`, and attaches — no duplication remains. `mouse on` was moved into the shared function. All acceptance criteria confirmed met.
