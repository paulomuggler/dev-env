---
slug: lazy-llm-pane-remove-confirmation
title: "Add confirmation before removing AI panes"
priority: P2
status: pending
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
- `external/lazy-llm/nvim-llm-send-plugin/.config/nvim/lua/plugins/llm-send.lua` — `<leader>llmx` keymap (line 372-380)

## Acceptance Criteria
- [ ] The nvim `<leader>llmx` keymap uses `vim.ui.select` or `vim.fn.confirm` before calling `llm-remove`
- [ ] The tmux `Prefix+C-x` binding shows which AI tool will be removed (tool name, index)
- [ ] A `--force` flag on `llm-remove` allows skipping confirmation for scripting
