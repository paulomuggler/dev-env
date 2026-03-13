---
slug: lazy-llm-tui-pane-manager
title: "Build TUI pane manager popup for multi-AI management"
priority: P1
status: done
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
- [x] A new `llm-panes` (or similar) script that can be launched via `tmux display-popup -E`
- [x] Shows a list of all AI panes with: index, tool name, active indicator, and status (idle/working/waiting if detectable)
- [x] Allows switching to any pane (Enter/number key)
- [x] Allows adding a new pane (with tool selection)
- [x] Allows removing a pane (with confirmation)
- [x] Register a tmux keybinding (e.g., `Prefix+L`) to open the popup
- [x] Can use `fzf`, `gum`, or plain bash TUI — keep dependencies minimal
- [x] Status detection: read last few lines of pane content to detect if AI is idle (prompt visible), working (processing indicator), or waiting for input (`[y/n]`)

## Work Report

**Date:** 2026-03-06

### What was done
- Created `llm-panes` fzf-based TUI for AI pane management
- Implements status detection via pane content heuristics
- Supports switch (Enter), add (ctrl-a with tool picker), and remove (ctrl-d)
- Registered `prefix+L` keybinding to open the popup

### How it was done
- Sources shared library for pane resolution and state management
- `detect_pane_status()` captures last 5 lines of pane content, strips ANSI codes, matches prompt patterns for idle/waiting/working
- fzf `--expect` captures ctrl-a/ctrl-d key presses for add/remove actions
- Tool selection for add uses nested fzf with claude/gemini/codex/grok/aider options
- Graceful degradation: shows plain text list if fzf unavailable

### Decisions made
- `prefix+L` for "List panes" (doesn't conflict with `prefix+S` for sessions)
- Status detection uses simple last-line heuristics — accurate enough for common AI tools
- Removal guard: prevents removing the last pane (matches llm-remove behavior)
- Popup size 60%x50% — smaller than session manager since less content

### Files changed
- `lazy-llm-bin/.local/bin/llm-panes` — New script (138 lines)
- `lazy-llm-bin/.local/bin/lazy-llm` — Added `prefix+L` keybinding
