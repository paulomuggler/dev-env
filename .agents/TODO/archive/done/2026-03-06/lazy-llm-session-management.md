---
slug: lazy-llm-session-management
title: "Add session listing, management, and TUI session manager"
priority: P1
status: done
created: 2026-03-06
updated: 2026-03-06
depends-on: [lazy-llm-deduplicate-main-script]
tags: [lazy-llm, feature, ux, phase-3]
---

# Add session listing, management, and TUI session manager

## Context
lazy-llm can create sessions/windows but has no way to:
- List running lazy-llm workspaces
- Show their status (directory, AI tools, pane count)
- Switch between them
- Kill/clean up sessions
- Distinguish lazy-llm sessions from regular tmux sessions

Users must use `tmux ls` and guess. This is the single biggest UX gap, and the area where claude-tmux excels — it provides a full TUI overlay for session lifecycle management.

Additionally, session naming can conflict: running `lazy-llm` twice from the same directory with the same tool generates the same name (`dev-dirname-claude`), and the script just attaches to the existing session rather than creating a new workspace.

## Key Files
- `external/lazy-llm/lazy-llm-bin/.local/bin/lazy-llm` — session creation logic

## Acceptance Criteria
- [x] `lazy-llm list` (or `lazy-llm --list`) shows all lazy-llm sessions with: name, directory, AI tools, pane count, whether attached
- [x] `lazy-llm kill <session>` cleanly shuts down a session (kills panes, cleans holding windows, removes state)
- [x] Session naming handles conflicts — append counter suffix if name already exists (e.g., `dev-myproject-claude-2`)
- [x] A TUI session manager (launched via `tmux display-popup -E lazy-llm-sessions` or similar) that:
  - Lists all lazy-llm sessions with status indicators
  - Allows switching to any session (Enter)
  - Allows creating new sessions
  - Allows killing sessions (with confirmation)
  - Fuzzy filter by name/path
- [x] lazy-llm sessions are identifiable (e.g., via a tmux session option `@lazy_llm=1`)
- [x] Register a tmux keybinding to open the session manager popup

## Work Report

**Date:** 2026-03-06

### What was done
- Added `@lazy_llm 1` session option for identifying lazy-llm sessions
- Auto-generated session names now get counter suffix on conflict (`-2`, `-3`, etc.)
- Created `llm-sessions` script with 3 modes: `--list` (table), `--kill` (cleanup), interactive (fzf)
- Added subcommand dispatch to main script: `lazy-llm list|kill|sessions`
- Registered `prefix+S` keybinding to open fzf session picker in tmux popup

### How it was done
- Session marker is set at session level via `tmux set-option -t "$session" @lazy_llm 1`
- `gather_sessions()` iterates all tmux sessions, filters by `@lazy_llm`, extracts metadata
- `cmd_interactive()` pipes session data through fzf with custom key bindings (enter/ctrl-d/ctrl-n)
- Naming conflict uses a simple while loop: try base name, then base-2, base-3, etc.
- Only auto-generated names get conflict resolution; explicit `-s` names preserve attach behavior

### Decisions made
- Session management lives in a separate `llm-sessions` script, not inline in the main script
- fzf chosen for TUI since it's already installed and configured in the dev-env
- `prefix+S` chosen as keybinding (uppercase S for "Sessions", doesn't conflict with common tmux binds)
- Kill command cleans up holding windows before killing the session

### Files changed
- `lazy-llm-bin/.local/bin/lazy-llm` — Subcommand dispatch, session marker, naming conflicts
- `lazy-llm-bin/.local/bin/llm-sessions` — New script (175 lines)
