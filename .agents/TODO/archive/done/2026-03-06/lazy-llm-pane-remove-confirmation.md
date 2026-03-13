---
slug: lazy-llm-pane-remove-confirmation
title: "Add confirmation before removing AI panes"
priority: P2
status: done
created: 2026-03-06
updated: 2026-03-06
depends-on: []
tags: [lazy-llm, ux, phase-2]
---

# Add confirmation before removing AI panes

## Context
`llm-remove` kills the AI pane immediately without any confirmation. This destroys the running AI process (Claude conversation, etc.) with no way to recover. The nvim keymap (`<leader>llmx`) also fires without asking.

While `llm-remove` correctly guards against removing the *last* pane, removing any pane with an active conversation is destructive and should warn the user.

## Key Files
- `external/lazy-llm/llm-remove-bin/.local/bin/llm-remove` — no confirmation logic
- `external/lazy-llm/nvim-llm-send-plugin/.config/nvim/lua/plugins/llm-send.lua` — `<leader>llmx` keymap
- `external/lazy-llm/lazy-llm-bin/.local/bin/lazy-llm` — `Prefix+C-x` binding

## Acceptance Criteria
- [x] The nvim `<leader>llmx` keymap uses `vim.ui.select` or `vim.fn.confirm` before calling `llm-remove`
- [x] The tmux `Prefix+C-x` binding shows which AI tool will be removed (tool name, index)
- [x] A `--force` flag on `llm-remove` allows skipping confirmation for scripting

## Work Report

**Date:** 2026-03-06

### What was done
- Added `vim.fn.confirm("Remove current AI pane?", "&Yes\n&No", 2)` to the nvim `<leader>llmx` keymap
- Wrapped the tmux `Prefix+C-x` binding with `confirm-before -p 'Remove current AI pane? (y/n)'`
- Added `--force`/`-f` flag parsing to `llm-remove` for scripted use

### How it was done
- nvim: Wrapped the existing jobstart call in a `vim.fn.confirm()` check (choice == 1 means Yes)
- tmux: Used tmux's built-in `confirm-before` command which shows a y/n prompt in the status line
- llm-remove: Added a flag parsing loop before TARGET_ARG to accept `-f`/`--force`

### Decisions made
- **Confirmation in callers, not in llm-remove itself**: The confirmation UI is different for nvim (vim dialog) vs tmux (status line prompt). Keeping llm-remove simple and adding `--force` for scripted callers is cleaner than embedding terminal-interactive prompts in the script.
- **vim.fn.confirm over vim.ui.select**: `confirm()` is simpler for a yes/no question — it shows a native dialog without needing a floating window or picker.

### Files changed
- `llm-remove-bin/.local/bin/llm-remove` — added `--force`/`-f` flag parsing
- `nvim-llm-send-plugin/.config/nvim/lua/plugins/llm-send.lua` — wrapped `<leader>llmx` with confirmation
- `lazy-llm-bin/.local/bin/lazy-llm` — wrapped `Prefix+C-x` with `confirm-before`

### Follow-up
- None
