---
slug: lazy-llm-tui-pane-manager
title: "Build TUI pane manager popup for multi-AI management"
priority: P1
status: pending
created: 2026-03-06
updated: 2026-03-06
depends-on: [lazy-llm-unify-pane-resolution, lazy-llm-add-stale-pane-validation]
tags: [lazy-llm, feature, ux, phase-2]
---

# Build TUI pane manager popup for multi-AI management

## Context
All multi-AI pane management is currently through keyboard shortcuts with no visual interface. Users can't see which AI panes exist, which is active, or what state each is in. Inspired by [claude-tmux](https://github.com/nielsgroen/claude-tmux), which uses `tmux display-popup -E` to launch a full TUI overlay.

Currently the only visual feedback is the `llm-status` script output in the tmux status bar (e.g., `[claude] gemini`), which is minimal.

## Key Files
- `external/lazy-llm/llm-status-bin/.local/bin/llm-status` — existing status output
- `external/lazy-llm/llm-add-bin/.local/bin/llm-add`
- `external/lazy-llm/llm-remove-bin/.local/bin/llm-remove`
- `external/lazy-llm/llm-cycle-bin/.local/bin/llm-cycle`

## Acceptance Criteria
- [ ] A new `llm-panes` (or similar) script that can be launched via `tmux display-popup -E`
- [ ] Shows a list of all AI panes with: index, tool name, active indicator, and status (idle/working/waiting if detectable)
- [ ] Allows switching to any pane (Enter/number key)
- [ ] Allows adding a new pane (with tool selection)
- [ ] Allows removing a pane (with confirmation)
- [ ] Register a tmux keybinding (e.g., `Prefix+L`) to open the popup
- [ ] Can use `fzf`, `gum`, or plain bash TUI — keep dependencies minimal
- [ ] Status detection: read last few lines of pane content to detect if AI is idle (prompt visible), working (processing indicator), or waiting for input (`[y/n]`)
