---
name: todo
description: Manage TODO tasks — create, track, execute, and archive tasks using file-per-task system
user-invocable: true
disable-model-invocation: false
arguments: $ARGUMENTS
---

# /todo — Task Management Skill

You manage the TODO tracking system at `.agents/TODO/`. Each task is a markdown file with YAML frontmatter. `.agents/TODO/INDEX.md` is an auto-generated dashboard.

---

## Frontmatter Schema

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `slug` | string | Yes | Kebab-case identifier. Must match filename (without `.md`). |
| `title` | string | Yes | Human-readable task title. |
| `priority` | enum | Yes | `P0`-`P5` (see Priority Levels below) |
| `status` | enum | Yes | `pending`, `in-progress`, `blocked`, `done`, `backlog` |
| `created` | date | Yes | ISO date (YYYY-MM-DD) when task was created. |
| `updated` | date | Yes | ISO date (YYYY-MM-DD) of last modification. |
| `depends-on` | list | Yes | Slugs of tasks that must be done before this one. Empty list `[]` if none. |
| `tags` | list | Yes | Free-form labels. Empty list `[]` if none. |

## Priority Levels

| Level | Name | Use When |
|-------|------|----------|
| P0 | Critical | Blocking other work, production down, must fix now |
| P1 | High | Important, should be next |
| P2 | Normal | Default priority for standard work |
| P3 | Low | Nice to have, do when time permits |
| P4 | Someday | Ideas worth tracking, no timeline |
| P5 | Wishlist | Aspirational, may never happen |

## Status Values

| Status | Meaning |
|--------|---------|
| `pending` | Not started, waiting to be picked up |
| `in-progress` | Currently being worked on |
| `blocked` | Cannot proceed — `depends-on` tasks not done yet |
| `done` | Completed, ready for archival |
| `backlog` | Not yet actionable — idea, research needed, or deferred. Completely excluded from work loop. Promote to `pending` when ready. |

**Backlog vs priority:** `status: backlog` is orthogonal to priority. Backlog tasks have priorities too (P0-P5) but are explicitly excluded from the work loop. A P1 backlog task is important but not yet actionable. Promote to `pending` when ready. The work loop only picks `status: pending` tasks.

## File Naming

- Filename: `{slug}.md` (kebab-case, no numeric prefix)
- Active tasks: `.agents/TODO/{slug}.md`
- Done tasks: `.agents/TODO/done/{slug}.md`
- Archived tasks: `.agents/TODO/archive/done/YYYY-MM-DD/{slug}.md`

## Task Template

```markdown
---
slug: SLUG
title: TITLE
priority: P2
status: pending
created: DATE
updated: DATE
depends-on: []
tags: []
---

# TITLE

## Context
Why this task exists, background info for an agent to understand the problem.

## Key Files
- `path/to/file.ts` - What's relevant about it

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
```

## .work-state File

`.agents/TODO/.work-state` tracks work-in-progress across context resets. YAML format:

```yaml
mode: loop          # single, loop, P0, P1, P2, P3, P4, P5
task: task-slug     # current task being worked on
phase: planning     # planning, executing, verify, complete
started: 2026-02-06T21:50:00Z
pid: 12345          # Claude Code process PID ($PPID) for instance scoping
```

| Field | Description |
|-------|-------------|
| `mode` | Work mode: `single` (one task), `loop` (all tasks), or priority level (`P0`-`P5`) |
| `task` | Slug of the current task being worked on |
| `phase` | Current phase: `planning`, `executing`, `verify`, or `complete` |
| `started` | ISO timestamp when work began |
| `pid` | PID of the Claude Code process that owns this work state (`$PPID`). Used by the stop hook for instance scoping and crash detection. |

The file is:
- Created when `/todo work` begins a task
- Updated when phase changes
- Deleted when work completes (single mode) or no more eligible tasks (loop/priority modes)
- Checked on any `/todo` invocation to resume interrupted work

## Work Report Section

When a task is completed, a `## Work Report` section is appended. Format:

```markdown
## Work Report

**Date:** YYYY-MM-DD

### What was done
- Summary of changes made

### How it was done
- Technical approach taken

### Decisions made
- Key choices and their rationale

### Files changed
- `path/to/file.ts` — Description of changes

### Follow-up
- Any discovered work that became new tasks
```

---

## Resume Check (ALWAYS DO THIS FIRST)

Before routing, check if `.agents/TODO/.work-state` exists. If it does:

1. Read the file to get the current work state
2. **Check PID ownership:** Read `pid:` from the file and compare with current `$PPID`:
   - **PID matches** (same instance, e.g. after context compaction): proceed directly to step 4 — this is our own work.
   - **PID missing or owner process dead** (crashed/restarted instance): use `AskUserQuestion` to prompt the user: "Found orphaned work state for {task} ({phase} phase). The Claude instance that owned it (PID {pid}) is no longer running — it appears to have crashed or been force-stopped." Options: "Resume" (claim ownership and continue the work loop) / "Ignore" (leave `.work-state` as-is and continue with the user's original requests in this conversation) / "Abort" (delete `.work-state` and proceed normally).
   - **PID differs and owner process alive** (different active instance): do NOT resume. Use `AskUserQuestion` to let the user know: "Another Claude instance (PID {pid}) is actively working on {task} ({phase} phase). What should this instance do?" Options: "Take over" (update PID and resume) / "Leave it" (proceed with normal routing). If user chooses "Leave it", proceed with normal routing. If "Take over", continue to step 3.
3. **Update PID:** If resuming, overwrite the `pid:` field with the current `$PPID` to claim ownership.
4. Inform the user: "Resuming work on {task} ({phase} phase, {mode} mode)"
5. Continue from the saved phase:
   - If `phase: planning` → continue with plan mode exploration
   - If `phase: executing` → re-read the plan file and continue execution
   - If `phase: verify` → read the task file's `## Verify Plan` section and continue checking off items
   - If `phase: complete` → write the work report, mark done, lint, commit
6. Do NOT start fresh or re-pick a task — resume the exact task from the state file

This ensures work survives context compaction while preventing accidental takeover of another instance's work.

## Routing

Parse the first word of `$ARGUMENTS` to route:

| First word | Sub-command |
|------------|-------------|
| *(empty)* | **show** — Pretty-print INDEX.md |
| `lint` | **lint** — Validate + regenerate INDEX.md |
| `work` | **work** — Pick and execute a task |
| `done` | **done** — Mark a task as done |
| `status` | **status** — Kanban-style view |
| `archive` | **archive** — Move done tasks to `done/` |
| `focus` | **focus** — Set/show current focus task |
| `update` | **update** — Modify task frontmatter |
| `verify` | **verify** — Verify a completed task |
| *(anything else)* | **create** — Parse context, create/update task files |

---

## Sub-command: show (no args)

1. Read `.agents/TODO/INDEX.md`
2. Read `.agents/TODO/.focus` if it exists
3. Pretty-print the index to the user, highlighting the focus task if set

---

## Sub-command: lint

Validate all task files, regenerate INDEX.md, and auto-archive old done tasks.

**Always runs as a haiku subagent.** Spawn a `general-purpose` subagent with `model: "haiku"`:

```
Read ~/.claude/skills/todo/lint-agent.md and execute the lint procedure on .agents/TODO/
```

The full procedure and INDEX.md format live in `lint-agent.md` (single source of truth).

---

## Sub-command: create (free-form text)

The user provides free-form context describing work to be done. Parse it and create task files.

### Procedure

1. Read the free-form text from `$ARGUMENTS`
2. **Read `.agents/TODO/INDEX.md`** to understand what tasks already exist. If any listed tasks look related to the user's input, read those specific task files for full context.
3. **Reconcile against existing tasks** before creating anything new. For each piece of work implied by the user's input, determine the best action:
   - **Skip**: An existing task already covers this exact work
   - **Update**: An existing task covers related work but needs its scope, priority, acceptance criteria, or context updated to reflect the new input
   - **Split**: An existing task is too broad and should be broken into multiple focused tasks (archive or delete the original)
   - **Merge**: Multiple existing tasks overlap significantly and should be consolidated into one
   - **Deprecate**: The new input supersedes or invalidates an existing task — mark it `done` with a note that it was superseded, or delete it if it was never started
   - **Create**: No existing task covers this work — create a new one
4. For each task to create or update:
   a. Generate a kebab-case slug (new tasks) or reuse existing slug (updates)
   b. Write a descriptive title
   c. Assign priority (default P2 unless context suggests otherwise)
   d. Set status to `pending` (new) or preserve existing status (updates)
   e. Set `created` (new tasks: today) and `updated` (always: today)
   f. Identify dependencies between tasks (new and existing) if any
   g. Write the task file to `.agents/TODO/{slug}.md` using the task template
   h. Fill in Context, Key Files (if identifiable), and Acceptance Criteria sections
5. Run the **lint** procedure to validate and regenerate INDEX.md
6. Report a summary of all changes: created, updated, merged, split, deprecated, and skipped tasks

---

## Sub-command: done \<slug\>

1. Parse the slug from `$ARGUMENTS` (second word)
2. Read `.agents/TODO/{slug}.md`
3. Update frontmatter: set `status: done`, update `updated` to today's date
4. Write the file back
5. Run the **lint** procedure

---

## Sub-command: work

Handles `work`, `work picker`, `work loop`, and `work <priority>`.

Parse remaining arguments after `work`:

- *(nothing)* → Pick and execute one task
- `picker` → Show top 5, user picks, then execute
- `loop` → Execute tasks continuously (all priorities)
- `P0`-`P5` → Execute all tasks of that priority until done

### Pick logic

1. Read all active task files from `.agents/TODO/*.md` (exclude INDEX.md)
2. Filter to `status: pending` where ALL `depends-on` slugs have `status: done` (check both active and `done/` directory). Tasks with `status: backlog` are never picked.
3. If priority filter is set (e.g., `work P0`), additionally filter to only tasks matching that priority
4. Sort by: priority (P0 first → P5 last), then `created` date (oldest first)
5. Select the first task (or present top 5 for picker mode)

### Priority loop mode

When invoked as `work P0` (or P1, P2, etc.):

1. Apply pick logic with priority filter
2. If no eligible tasks at that priority, report "No eligible P{n} tasks" and stop
3. Execute the picked task (plan → execute → verify → complete)
4. After completion, repeat from step 1 until no eligible tasks remain at that priority
5. Report summary: how many tasks were completed

### State file management

The work state file (`.agents/TODO/.work-state`) tracks progress across context resets.

**Lifecycle:**
- **Created** when work begins on a task
- **Updated** when phase changes (planning → executing → verify → complete)
- **Cleared** when task completes (delete file if mode is single, otherwise update task to next)
- **Read** on any `/todo` invocation to check for resume

### Execute logic — 4-Phase State Machine

Every task goes through **plan → execute → verify → complete**. No exceptions.

```
planning → executing → verify → complete → (pick next or done)
```

| Phase | Purpose | On Resume |
|-------|---------|-----------|
| `planning` | Explore codebase, write plan, ExitPlanMode | Continue exploring/planning |
| `executing` | Implement the plan | Re-read plan, continue implementing |
| `verify` | Run verify checks, fix failures | Read Verify Plan, continue checking |
| `complete` | Work report, mark done, lint, commit | Write missing report, finish completion |

Each phase transition: update `.work-state` **before** starting the new phase.

#### Phase 1: Plan

1. **Write state file:** Create `.agents/TODO/.work-state` with mode, task slug, `phase: planning`, timestamp, and `pid: $PPID` (the Claude Code process PID, for instance scoping)
2. Update task `status: in-progress`, `updated` to today
3. Read the full task file body — it IS the agent prompt
4. Use `EnterPlanMode` to enter plan mode
5. Explore the codebase to understand the relevant code, architecture, and constraints
6. Write an implementation plan addressing each item in the Acceptance Criteria
   **IMPORTANT:** Start the plan file with `# Plan: {task-slug}` as the H1 heading (e.g., `# Plan: mastra-foundation`). This enables the auto-approve hook to validate the plan matches the current task.
7. Use `ExitPlanMode` to present the plan for user approval

#### Phase 2: Execute

8. **Update state file:** Set `phase: executing`
9. After the user approves, re-read the plan file to have a clean reference (exploration context will have been summarized)
10. Execute the plan, following the Acceptance Criteria as your checklist
11. **Code commit discipline:** Commit after each logical unit of work — a completed function, a fixed bug, a batch of related changes. Never leave uncommitted code work.
    - **Code commits only contain project source files.** Never mix in `.agents/TODO/` files.

#### Phase 3: Verify

12. **Update state file:** Set `phase: verify`
13. **Task tracking commit:** Commit the task file status change to in-progress (`.agents/TODO/` files only, prefix message with `[todo]`)
14. Run the verify procedure (see Sub-command: verify) for the current task
15. Reset retry counter (`.claude/todo-loop-retries`) on successful verification
16. If any items fail → fix the issue, commit the fix (code-only commit), re-verify failed items only

#### Phase 4: Complete

17. **Update state file:** Set `phase: complete`
18. **Work report:** Append a `## Work Report` section to the task file documenting:
    - **What was done:** Summary of changes made
    - **How it was done:** Technical approach, tools/patterns used
    - **Decisions made:** Any non-obvious choices and their reasoning
    - **Files changed:** List of key files created/modified
    - **Follow-up:** Any discovered work that should become new tasks (create them)
19. Set `status: done`, `updated` to today in the task file frontmatter
20. **Notify completion:** Send OS notification via Bash:
    ```bash
    notify-send -u normal "TODO Task Completed" "Finished: {task-slug}" -t 5000
    ```
    (On macOS use `osascript -e 'display notification "Finished: {task-slug}" with title "TODO Task Completed"'`)
21. Run the **lint** procedure to sync INDEX.md
22. **Task tracking commit:** Commit all `.agents/TODO/` changes (work report, status, INDEX.md) with `[todo]` prefix
23. **Update state file:**
    - If mode is `single`: delete `.agents/TODO/.work-state`
    - If mode is `loop` or priority (`P0`, `P1`, etc.): clear task field, pick next eligible task
    - If no more eligible tasks: delete state file and report summary
24. In loop/priority modes: repeat pick → plan → execute → verify → complete until no eligible tasks remain (respecting priority filter if set), then report summary

### Git Commit Discipline

Two separate commit streams throughout the work lifecycle:

**Code commits:** Only project source files. Concise messages explaining *why*. Stage specific files.
**Task tracking commits:** Only `.agents/TODO/` files. Prefix with `[todo]`. Status changes, work reports, verify reports, INDEX.md.

**Phase transitions:**
- **Enter executing:** Code commit any prior work. Task tracking commit: task status → in-progress.
- **Enter verify:** Code commit all implementation work. Task tracking commit: verify plan appended.
- **Enter complete:** Code commit any verify-phase fixes. Task tracking commit: verify report, work report, status → done, INDEX.md regenerated.

### Picker mode

1. Run pick logic, take top 5
2. Use AskUserQuestion to present the tasks with their titles and priorities
3. User selects one
4. Execute that task

---

## Sub-command: status

Kanban-style display grouped by status.

### Procedure

1. Read all active task files
2. Group by status
3. Display as columns:

```
┌─────────────┬─────────────┬─────────────┬─────────────┐
│   PENDING   │ IN PROGRESS │   BLOCKED   │    DONE     │
├─────────────┼─────────────┼─────────────┼─────────────┤
│ P0: slug    │ slug        │ slug        │ slug        │
│ P1: slug    │             │  ↳ dep1     │ slug        │
│ P2: slug    │             │  ↳ dep2     │             │
└─────────────┴─────────────┴─────────────┴─────────────┘
```

Use simple text formatting. Show priority prefix for pending tasks. Show blockers for blocked tasks.

---

## Sub-command: archive

Trigger immediate full archive (same logic as lint auto-archive, but no thresholds — archive ALL done tasks).

1. Glob `.agents/TODO/done/*.md` for all tasks
2. For each task, read the `updated` date from frontmatter
3. Move to `.agents/TODO/archive/done/YYYY-MM-DD/` using the task's `updated` date for the folder name
4. Run the **lint** procedure
5. Report how many tasks were archived

---

## Sub-command: focus \<slug\>

- If slug provided: write it to `.agents/TODO/.focus`, confirm to user
- If no slug provided: read and display current focus, or say none is set
- Validate that the slug references an existing active task

---

## Sub-command: update \<slug\> \<changes\>

1. Parse slug (second word) and changes (remaining text) from `$ARGUMENTS`
2. Read `.agents/TODO/{slug}.md`
3. Parse the changes — support natural language like:
   - `priority P1` or `pri P0`
   - `depends-on foo-bar` or `dep foo-bar`
   - `tag backend` or `tags backend,frontend`
   - `title New Title Here`
   - `status blocked`
4. Update the frontmatter fields accordingly
5. Set `updated` to today's date
6. Write the file back
7. Run the **lint** procedure

---

## Sub-command: verify \[slug\]

Verify that a task's changes work correctly. Can be used standalone or as part of the work loop.

### Standalone usage
- `/todo verify <slug>` — Verify a specific completed task
- `/todo verify recent` — Verify all tasks marked done today
- `/todo verify` (during work loop) — Verify the current task

### Procedure

1. Identify the task to verify:
   - If slug provided → read that task file
   - If in work loop → use current task from `.work-state`
   - If `recent` → glob done tasks with today's `updated` date

2. **Read acceptance criteria** from the task file — collect all `- [ ]` and `- [x]` checkbox items

3. **Analyze changed files:** Run `git log --oneline --name-only` for commits related to this task (use commit messages or date range). Collect the set of changed files.

4. **Generate verify plan** combining:

   a. **Acceptance criteria mapping** — For each acceptance criterion, determine a concrete verification method:
      - UI criteria → Playwright navigation + snapshot
      - API criteria → curl/fetch endpoint, check response
      - Logic criteria → run tests or manual verification
      - Data criteria → query DB or check file output

   b. **File-type checks** based on changed files. These are **mandatory**, not suggestions:
      | Pattern | Action |
      |---------|--------|
      | `apps/taskmill-ui/**` (not tests) | **MUST** use Playwright: `browser_navigate` to the feature (via `https://taskmill.localhost`), `browser_snapshot` to verify elements, **interact** with the feature (click, fill, trigger), `browser_take_screenshot` for visual proof. A task touching UI code is **never done** without a Playwright screenshot. |
      | `apps/api/src/routes/**` | **MUST** hit endpoint with curl, verify response shape and status code |
      | `packages/core/src/db/migrations/**` | Verify migration syntax is valid |
      | `*.test.*` or `*.spec.*` | **MUST** run the test files |
      | Any code with nearby test files | Run related tests |

   c. **Static checks** — always run if TS/JS files changed:
      - `pnpm lint` (Biome) — catches lint and format issues
      - `tsc --noEmit` — catches type errors
      Both must pass. Run them in parallel if possible.

5. **Append `## Verify Plan`** to the task file with checkboxes:
   ```markdown
   ## Verify Plan
   - [ ] AC: Can drag-drop nodes → Playwright: navigate to /workflows/editor, verify palette renders
   - [ ] AC: Saves to valid YAML → Load editor, save, verify YAML output
   - [ ] Biome lint passes
   - [ ] TypeScript compiles cleanly
   - [ ] Related tests pass: pnpm test --filter taskmill-ui
   ```

6. **Execute each item**, checking them off as they pass. For Playwright verification:
   - Use `browser_navigate` to open the relevant page (always use `https://taskmill.localhost` via Traefik, not `localhost:3035`)
   - Use `browser_snapshot` to capture the accessibility tree
   - **Actually interact with the feature** — click the buttons, fill the forms, trigger the behavior you built
   - Verify expected elements are present and functional
   - Use `browser_take_screenshot` for visual evidence — this is **required**, not optional
   - Check `browser_console_messages` for errors and `browser_network_requests` for failed API calls

7. **Append `## Verify Report`** documenting results:
   ```markdown
   ## Verify Report
   - [x] AC: Can drag-drop nodes — Verified: palette renders 7 node types, drag creates node on canvas
   - [x] AC: Saves to valid YAML — Verified: save produces valid YAML with all step types
   - [x] Biome lint passes — `pnpm lint` exit code 0
   - [x] TypeScript compiles cleanly — `tsc --noEmit` exit code 0
   - [x] Tests pass — 42/42 passing
   ```

8. If any items fail → fix the issue, re-commit, re-verify failed items only
9. Once all items pass → continue (in work loop: proceed to complete phase)
