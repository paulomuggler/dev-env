# /todo — Task Management Skill

File-per-task tracking system for agent work. Each task is a markdown file with YAML frontmatter in `.agents/TODO/`. An auto-generated `INDEX.md` serves as the dashboard.

## Quick Reference

```
/todo                           Show the task index
/todo <free-form text>          Create tasks from description
/todo work                      Pick and execute the next pending task
/todo work loop                 Execute tasks continuously until none remain
/todo work picker               Choose from top 5 eligible tasks
/todo work P1                   Execute all P1 tasks until done
/todo done <slug>               Mark a task as done
/todo status                    Kanban-style board view
/todo lint                      Validate tasks + regenerate INDEX.md
/todo focus <slug>              Set the current focus task
/todo update <slug> <changes>   Modify task frontmatter
/todo verify <slug>             Verify a completed task
/todo verify recent             Verify all tasks completed today
/todo archive                   Archive all done tasks
```

## Core Concepts

### Task Files

Each task lives at `.agents/TODO/{slug}.md` with YAML frontmatter:

```yaml
---
slug: fix-auth-redirect
title: Fix auth redirect loop on expired tokens
priority: P2
status: pending
created: 2026-02-20
updated: 2026-02-20
depends-on: []
tags: [auth, bugfix]
---
```

The body contains `## Context`, `## Key Files`, and `## Acceptance Criteria` sections. These are the agent's prompt — they describe the work to do, where to look, and what "done" means.

### Priority Levels

| Level | Name | When to Use |
|-------|------|-------------|
| P0 | Critical | Blocking other work, production down |
| P1 | High | Important, should be next |
| P2 | Normal | Default for standard work |
| P3 | Low | Nice to have, do when time permits |
| P4 | Someday | Worth tracking, no timeline |
| P5 | Wishlist | Aspirational, may never happen |

### Status Values

| Status | Meaning |
|--------|---------|
| `pending` | Ready to be picked up by the work loop |
| `in-progress` | Currently being worked on |
| `blocked` | Waiting on `depends-on` tasks to complete |
| `done` | Completed, will be auto-archived |
| `backlog` | Not yet actionable — excluded from the work loop entirely |

**Backlog** is orthogonal to priority. A P1 backlog task is important but not yet ready to work on. Promote to `pending` when it becomes actionable.

### File Organization

```
.agents/TODO/
├── INDEX.md                     # Auto-generated dashboard
├── .work-state                  # Active work session (gitignored)
├── .focus                       # Current focus task (gitignored)
├── {slug}.md                    # Active tasks
├── done/
│   └── {slug}.md                # Recently completed
└── archive/done/
    └── YYYY-MM-DD/
        └── {slug}.md            # Archived completions
```

## The Work Protocol

`/todo work` executes tasks through a strict 4-phase state machine:

```
planning → executing → verify → complete
```

### Phase 1: Plan

- Enters plan mode, explores the codebase
- Writes an implementation plan addressing each acceptance criterion
- Presents the plan for user approval before proceeding

### Phase 2: Execute

- Implements the approved plan
- Commits after each logical unit of work
- Code commits contain only project source files (never `.agents/TODO/`)

### Phase 3: Verify

- Generates a verify plan based on acceptance criteria and changed file types
- Executes each verification check (tests, type checks, Playwright for UI, curl for APIs)
- Fixes any failures and re-verifies

### Phase 4: Complete

- Appends a Work Report section documenting what was done, how, and why
- Marks the task `done`
- Runs lint to sync INDEX.md
- Commits all task tracking changes with `[todo]` prefix

### Resume Across Context Resets

The `.work-state` file tracks the current task and phase. If a session ends mid-work (context compaction, timeout), the next `/todo` invocation detects and resumes from exactly where it left off.

## Creating Tasks

### From free-form text

```
/todo Add rate limiting to the API endpoints. Also need to fix the
     memory leak in the WebSocket handler — that's more urgent.
```

This creates two task files, reconciling against existing tasks to avoid duplicates. The agent assigns priorities based on context ("more urgent" → higher priority).

### Reconciliation

Before creating tasks, the agent reads INDEX.md and checks for:
- **Skip** — existing task already covers this
- **Update** — existing task needs scope/priority changes
- **Split** — existing task is too broad
- **Merge** — multiple tasks overlap
- **Deprecate** — new input supersedes existing task

## Work Modes

| Command | Behavior |
|---------|----------|
| `/todo work` | Pick one task, execute it, stop |
| `/todo work loop` | Execute all pending tasks continuously |
| `/todo work P0` | Execute all P0 tasks, then stop |
| `/todo work picker` | Show top 5 eligible tasks, user picks one |

Pick logic: filters to `status: pending` tasks whose dependencies are all done, sorts by priority then creation date.

## Git Discipline

Two separate commit streams:

- **Code commits**: Project source files only. Concise messages explaining *why*.
- **Task tracking commits**: `.agents/TODO/` files only. Prefixed with `[todo]`.

These are never mixed. Phase transitions trigger commits in both streams at appropriate points.

## Updates and Metadata

```
/todo update fix-auth-redirect priority P1
/todo update fix-auth-redirect status blocked
/todo update fix-auth-redirect depends-on setup-token-refresh
/todo update fix-auth-redirect tags auth,security
/todo update fix-auth-redirect title Fix auth redirect on token expiry
```

Natural language shortcuts work: `pri P0`, `dep some-task`, `tag backend`.

## Verification

`/todo verify` maps acceptance criteria to concrete checks:

| File Pattern | Required Verification |
|--------------|-----------------------|
| `apps/taskmill-ui/**` | Playwright: navigate, snapshot, interact, screenshot |
| `apps/api/src/routes/**` | curl endpoint, check response shape |
| `*.test.*` / `*.spec.*` | Run the tests |
| Any `.ts` files | `tsc --noEmit` |

UI tasks are **never** marked done without a Playwright screenshot proving the feature works.

## Archival

Done tasks are auto-archived during `/todo lint`:
- Tasks with `updated` date >24h ago move to `archive/done/YYYY-MM-DD/`
- If >30 tasks in `done/`, oldest are archived until count is ≤30

`/todo archive` immediately archives all done tasks regardless of age.
