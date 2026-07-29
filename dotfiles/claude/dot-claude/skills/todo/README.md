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
├── REVIEW-QUEUE.md              # The user's single review surface (committed)
├── CONTINUATION.md              # Continuation ledger — the deal + narrative (committed)
├── .work-state                  # Active work session (gitignored)
├── .focus                       # Current focus task (gitignored)
├── {slug}.md                    # Active tasks
├── backlog/
│   └── {slug}.md                # Backlog tasks (not yet actionable)
├── done/
│   └── {slug}.md                # Recently completed
└── archive/done/
    └── YYYY-MM-DD/
        └── {slug}.md            # Archived completions
```

## The Work Protocol (orchestrated)

`/todo work` runs an **orchestrator → subagents** model: the session that
invokes it briefs, dispatches, adjudicates, and completes — implementation and
verification run in fresh subagents, each on the model tier the work warrants.
The strict state machine:

```
briefing → executing → verifying → complete
```

### Phase 1: Brief (orchestrator)

- Judges the task file dispatch-ready: a zero-context executor must be able to
  run from it alone (exact paths, resolved decisions, scope fences,
  verification recipe)
- Enriches the task file itself where thin; unresolved judgment flips the task
  to `model: inline`

### Phase 2: Execute (executor subagent — `model:` from frontmatter)

- A dispatched executor (see `execute-agent.md`) implements the brief:
  `opus` for implementation work, `sonnet` for mechanical sweeps, `inline`
  when the orchestrator executes itself (interactive plan approval applies
  only inline)
- Commits after each logical unit (code-only, never `.agents/TODO/`), records
  hashes, checks criteria off, appends the Work Report
- Returns `COMPLETED`, `BLOCKED` (with the precise question — never builds past
  a fork), or `FAILED` (with diagnosis)

### Phase 3: Verify (fresh verifier subagent)

- A separate-context verifier (see `verify-agent.md`) derives its own verify
  plan from the diff and acceptance criteria, executes every check (tests,
  typecheck, Playwright for UI, curl for APIs), and appends plan + report
- Failures loop back: the orchestrator re-dispatches the executor with the
  findings; bounded at two rework rounds, then escalate
- A conditional validation subagent appends a `## Human Validation` checklist
  for what only a person can judge

### Phase 4: Complete (orchestrator)

- The orchestrator spot-checks the reports against the running system, marks
  the task `done`, runs lint, updates `REVIEW-QUEUE.md` (the user's single
  review surface), and commits tracking changes with `[todo]` prefix

### Continuity (no restart machinery)

The `.work-state` file tracks the current task and phase; `CONTINUATION.md` —
the **continuation ledger** — carries the standing agreements, disciplines in
force, and loop narrative that a bare resume pointer cannot. Every durable fact
lives in committed files. If a session ends mid-work — or stops deliberately
because the orchestrator's context is near capacity — the next `/todo`
invocation resumes exactly where it left off: read the ledger first for *the
deal*, then `.work-state` for *the place*. The old auto-clear restart hack
is retired.

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
| `/todo work loop` | Execute all pending tasks continuously, batch by batch in ascending batch order |
| `/todo work loop --batches 8,11,12` | Run batch 8, then 11, then 12 (in order), ignore the rest |
| `/todo work P0` | Execute all P0 tasks across all batches, then stop |
| `/todo work picker` | Show top 5 eligible tasks, user picks one |
| `... --inline` | Orchestrator executes tasks itself (interactive plan approval) instead of dispatching executors |

Pick logic: filters to `status: pending` tasks whose dependencies are all done, then sorts by **batch** (the leading number in the slug; `--batches` order or ascending), then in-batch slug sequence, then priority, then creation date. Batch is the primary execution axis; priority is an in-batch tiebreak (plus the `work P0`-`P5` cross-batch sweep). See SKILL.md → Batch ordering model.

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
