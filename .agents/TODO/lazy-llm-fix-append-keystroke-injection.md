---
slug: lazy-llm-fix-append-keystroke-injection
title: "Replace llm-append keystroke injection with reliable method"
priority: P2
status: pending
created: 2026-03-06
updated: 2026-03-06
depends-on: []
tags: [lazy-llm, bugfix, robustness, phase-2]
---

# Replace llm-append keystroke injection with reliable method

## Context
`llm-append` injects keystrokes into the prompt pane nvim instance: `Escape`, `A`, `Enter`, then the text content. This is fragile — if nvim is in the wrong state (command mode, a dialog open, visual mode, etc.), the keystrokes do unexpected things.

Compare with `llm-send` which uses `tmux load-buffer` + `tmux paste-buffer` — a much more reliable data channel that doesn't depend on editor state.

The note plugin's `send_notes_to_prompt()` also uses this keystroke injection pattern (lines 210-232).

## Key Files
- `external/lazy-llm/llm-send-bin/.local/bin/llm-append` — entire file
- `external/lazy-llm/nvim-note-plugin/.config/nvim/lua/plugins/note.lua` — `send_notes_to_prompt()` lines 199-232

## Acceptance Criteria
- [ ] `llm-append` uses a reliable method (e.g., `tmux load-buffer` + paste, or nvim remote API, or temp file handoff) instead of keystroke injection
- [ ] Raw mode (inline insertion) and wrapped mode (with newlines) both work reliably
- [ ] The note plugin's `send_notes_to_prompt()` uses the same reliable method
- [ ] Content is appended correctly regardless of nvim's current mode/state
