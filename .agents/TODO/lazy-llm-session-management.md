---
slug: lazy-llm-session-management
title: "Add session listing, management, and TUI session manager"
priority: P1
status: pending
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
- [ ] `lazy-llm list` (or `lazy-llm --list`) shows all lazy-llm sessions with: name, directory, AI tools, pane count, whether attached
- [ ] `lazy-llm kill <session>` cleanly shuts down a session (kills panes, cleans holding windows, removes state)
- [ ] Session naming handles conflicts — append counter suffix if name already exists (e.g., `dev-myproject-claude-2`)
- [ ] A TUI session manager (launched via `tmux display-popup -E lazy-llm-sessions` or similar) that:
  - Lists all lazy-llm sessions with status indicators
  - Allows switching to any session (Enter)
  - Allows creating new sessions
  - Allows killing sessions (with confirmation)
  - Fuzzy filter by name/path
- [ ] lazy-llm sessions are identifiable (e.g., via a tmux session option `@lazy_llm=1`)
- [ ] Register a tmux keybinding to open the session manager popup
