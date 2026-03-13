---
slug: lazy-llm-fix-append-keystroke-injection
title: "Replace llm-append keystroke injection with reliable method"
priority: P2
status: done
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
- `external/lazy-llm/nvim-note-plugin/.config/nvim/lua/plugins/note.lua` — `send_notes_to_prompt()`

## Acceptance Criteria
- [x] `llm-append` uses a reliable method (e.g., `tmux load-buffer` + paste, or nvim remote API, or temp file handoff) instead of keystroke injection
- [x] Raw mode (inline insertion) and wrapped mode (with newlines) both work reliably
- [x] The note plugin's `send_notes_to_prompt()` uses the same reliable method
- [x] Content is appended correctly regardless of nvim's current mode/state

## Work Report

**Date:** 2026-03-06

### What was done
- Rewrote `llm-append` to use `tmux load-buffer` + `paste-buffer` for content delivery
- Added stdin support (`echo "text" | llm-append`) alongside argument mode
- Simplified the note plugin's `send_notes_to_prompt()` from 20-line inline bash script to a single `llm-append` call
- Added `on_exit` error feedback to the note plugin's jobstart call

### How it was done
Replaced `tmux send-keys "$1"` (keystroke injection) with `printf '%s' "$CONTENT" | tmux load-buffer -` + `tmux paste-buffer -t "$TARGET"`. Kept keystroke positioning (Escape, A, Enter) since those are needed to move the cursor within nvim. The split means positioning uses keystrokes (unavoidable) but content delivery uses the atomic load-buffer approach.

For stdin support: detect `! -t 0` (stdin is not a terminal) and read via `cat`.

### Decisions made
- **Keep keystroke positioning**: Escape, A, Enter keystrokes are needed to position the cursor in nvim. These are short, reliable sequences. Only the content delivery (the actual text) needed to move to load-buffer.
- **Simplified `"" Enter` to just `Enter`**: The empty string argument before Enter was a no-op; removed for clarity.
- **Note plugin delegates to llm-append**: Instead of maintaining duplicate pane resolution and paste logic, the note plugin now writes to a temp file and pipes to `llm-append`. This eliminates 15 lines of inline bash and ensures consistency.

### Files changed
- `llm-send-bin/.local/bin/llm-append` — rewrote content delivery and added stdin support
- `nvim-note-plugin/.config/nvim/lua/plugins/note.lua` — replaced inline bash script with `llm-append` call

### Follow-up
- None
