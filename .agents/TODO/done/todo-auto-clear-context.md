---
slug: todo-auto-clear-context
title: Add auto-clear context feature to TODO work loop
priority: P1
status: done
created: 2026-03-13
updated: 2026-03-13
depends-on: []
tags: [todo-skill, hooks, automation]
---

# Add auto-clear context feature to TODO work loop

## Context
The TODO skill's work loop (`/todo work loop`) currently runs all tasks in a single Claude session, accumulating context across tasks. This degrades quality as context fills up with irrelevant information from prior tasks. The solution is to automatically restart Claude between tasks — killing the process after one task completes and relaunching with a fresh context, using hooks to inject the "pick up next task" prompt.

Design was agreed with the user in this conversation. Key decisions:
- Toggle via `--auto-clear` parameter on `/todo work loop`
- Writes `auto-clear: true` to `.work-state` so hooks know to act
- Agent writes `clear-pending: true` to `.work-state` as the very last step (after setting up next task), then STOPS immediately
- PostToolUse hook detects `clear-pending: true`, removes it, writes auto-prompt transport file, kills Claude via `kill $PPID`, then uses `tmux send-keys` to type `claude` into the pane
- SessionStart hook (no matcher — fires on fresh start) reads the auto-prompt transport file, injects it as a message, deletes the file
- New Claude instance picks up from `.work-state` via normal resume flow

## Key Files
- `~/.claude/skills/todo/SKILL.md` — Skill protocol (step 23 task transition, work subcommand args)
- `~/.claude/hooks/todo-work-loop-stop.sh` — Existing stop hook (pattern reference)
- `~/.claude/hooks/todo-resume.sh` — Existing SessionStart hook (pattern reference)
- `dotfiles/claude/dot-claude/settings.json` — Hook registration
- `dotfiles/claude/dot-claude/hooks/` — Hook scripts directory

## Acceptance Criteria
- [ ] `/todo work loop --auto-clear` writes `auto-clear: true` to `.work-state`
- [ ] SKILL.md step 23 handles auto-clear mode: writes `clear-pending: true` and instructs agent to STOP immediately
- [ ] PostToolUse hook (`todo-auto-clear.sh`) detects `clear-pending: true` in `.work-state`, removes it, writes `.auto-prompt`, kills Claude, uses tmux send-keys to restart
- [ ] SessionStart hook (`todo-auto-start.sh`) reads `.auto-prompt` transport file, injects as message, deletes the file
- [ ] Both hooks are registered in `settings.json`
- [ ] Hook scripts follow existing patterns (PID scoping, error handling, JSON escaping)
- [ ] When no more eligible tasks remain, auto-clear mode is NOT triggered (work-state is deleted, not updated)

## Work Report

**Date:** 2026-03-13

### What was done
- Created PostToolUse hook (`todo-auto-clear.sh`) that detects `clear-pending: true` in `.work-state`, removes it, writes `.auto-prompt` transport file, kills Claude, and relaunches via `tmux send-keys`
- Created SessionStart hook (`todo-auto-start.sh`) that reads `.auto-prompt`, injects it as a session message, and deletes the file
- Registered both hooks in `settings.json` (PostToolUse with Write|Edit matcher, SessionStart without matcher)
- Updated SKILL.md: `--auto-clear` flag parsing, step 23 auto-clear task transition behavior, `.work-state` schema docs
- Re-stowed claude dotfiles so hooks are deployed to `~/.claude/hooks/`

### How it was done
- Leveraged tmux `send-keys` to spawn Claude as a shell child (clean env inheritance) rather than `nohup`/`exec` from the hook
- Used `clear-pending: true` as a one-shot sentinel to avoid false triggers during normal planning phase writes
- PID scoping prevents cross-instance interference (same pattern as existing stop hook)
- Python3 JSON escaping for transport file content (same pattern as existing hooks)

### Decisions made
- Hook kills Claude then types `claude` into the tmux pane — new process is a proper shell child with full env
- `clear-pending` is removed by the hook, not the agent — cleaner, no dependency on agent behavior
- Agent must STOP after writing the transitional `.work-state` — the hook handles everything else
- Requires tmux — hook is a no-op without it (logged, not an error)

### Files changed
- `dotfiles/claude/dot-claude/hooks/todo-auto-clear.sh` — New PostToolUse hook
- `dotfiles/claude/dot-claude/hooks/todo-auto-start.sh` — New SessionStart hook
- `dotfiles/claude/dot-claude/settings.json` — Hook registration
- `~/.claude/skills/todo/SKILL.md` — Argument parsing, step 23, schema docs

### Follow-up
- Full integration test needed: create 2+ pending tasks and run `/todo work loop --auto-clear` to verify end-to-end restart cycle
