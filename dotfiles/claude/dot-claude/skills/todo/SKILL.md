---
name: todo
description: Manage TODO tasks — create, track, execute, archive, and validate tasks using file-per-task system
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
| `commits` | list | No | Git commit hashes (short form) for code changes made during this task. Empty list `[]` or omitted for new/unstarted tasks. Populated by the executor during the execute phase. |

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
commits: []
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
auto-clear: true    # optional — restart Claude between tasks for fresh context
clear-pending: true # optional — one-shot sentinel for the auto-clear hook
filter: tags:assessment  # optional — restrict pick logic to matching tasks
```

| Field | Description |
|-------|-------------|
| `mode` | Work mode: `single` (one task), `loop` (all tasks), or priority level (`P0`-`P5`) |
| `task` | Slug of the current task being worked on |
| `phase` | Current phase: `planning`, `executing`, `verify`, or `complete` |
| `started` | ISO timestamp when work began |
| `pid` | PID of the Claude Code process that owns this work state (`$PPID`). Used by the stop hook for instance scoping and crash detection. |
| `auto-clear` | Optional. When `true`, Claude will be restarted between tasks for a fresh context window. Set by `--auto-clear` flag on `/todo work`. |
| `clear-pending` | Optional. One-shot sentinel written during task transition. The PostToolUse hook detects this, removes it, and triggers the Claude restart. Never set manually. |
| `filter` | Optional. Restricts pick logic to matching tasks. Format: `tags:{tag}` (tasks must have the tag). Persists across context clears so the loop stays scoped. Set by `--filter` flag. |

The file is:
- Created when `/todo work` begins a task
- Updated when phase changes
- Deleted when work completes (single mode) or no more eligible tasks (loop/priority modes)
- Checked on any `/todo` invocation to resume interrupted work

## Task File Section Order

Completed task files have these sections in order:
1. `## Context` — why the task exists
2. `## Key Files` — relevant source files
3. `## Acceptance Criteria` — checkbox items
4. `## Verify Plan` — verification checklist (generated by fresh subagent, Phase 3a)
5. `## Work Report` — executor's completion summary (Phase 3b)
6. `## Verify Report` — executor's verification results (Phase 3c)
7. `## Human Validation` — human-facing checklist (generated by fresh subagent, Phase 3d)

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

### Commits
- `abc1234` — Description of what the commit does
(Should match the `commits` list in frontmatter)

### Files changed
- `path/to/file.ts` — Description of changes

### Sources Consulted
- `~/.claude/coding-standards/languages/typescript.md` (if applicable)
- `~/.claude/coding-standards/frameworks/hono.md` (if applicable)

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
   - If `phase: verify` → check which verify sub-phases (3a–3d) are done by looking for existing sections (`## Verify Plan`, `## Work Report`, `## Verify Report`, `## Human Validation`), then resume from the first missing one
   - If `phase: complete` → mark done, lint, commit
6. Do NOT start fresh or re-pick a task — resume the exact task from the state file

This ensures work survives context compaction while preventing accidental takeover of another instance's work.

## Routing

Parse the first word of `$ARGUMENTS` to route:

| First word | Sub-command |
|------------|-------------|
| `lint` | **lint** — Validate + regenerate INDEX.md |
| `work` | **work** — Pick and execute a task |
| `archive` | **archive** — Move done tasks to archive |
| *(anything else)* | **create** — Parse context, create/update task files |

For anything not listed (checking status, marking done, updating fields, etc.) — the agent handles it directly from natural language by reading/writing task files. No dedicated route needed.

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

## Sub-command: work

Handles `work`, `work picker`, `work loop`, and `work <priority>`.

Parse remaining arguments after `work`:

- *(nothing)* → Pick and execute one task
- `picker` → Show top 5, user picks, then execute
- `loop` → Execute tasks continuously (all priorities)
- `P0`-`P5` → Execute all tasks of that priority until done
- `--auto-clear` → Flag (combinable with `loop` or priority modes). Restarts Claude between tasks for a fresh context window. When set, write `auto-clear: true` to `.work-state`. Example: `work loop --auto-clear`, `work P1 --auto-clear`.
- `--filter tags:{tag}` → Restrict the work loop to tasks matching the filter. Only tasks whose `tags` array includes `{tag}` are eligible for picking. Persisted in `.work-state` so the filter survives context clears. Example: `work loop --filter tags:assessment`.

### Pick logic

1. Glob `.agents/TODO/*.md` (exclude INDEX.md) and read **frontmatter only** from each file
2. Filter to `status: pending` where ALL `depends-on` slugs have `status: done` (check both active and `done/` directory). Tasks with `status: backlog` are never picked.
3. If priority filter is set (e.g., `work P0`), additionally filter to matching priority
4. If `--filter` is set (or `filter` in `.work-state` during resume), apply it:
   - `tags:{tag}` — keep only tasks whose `tags` array includes `{tag}`
5. Sort by: priority (P0 first → P5 last), then `created` date (oldest first)
6. Select the first task (or present top 5 for picker mode)

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
| `complete` | Mark done, lint, commit | Finish completion |

Each phase transition: update `.work-state` **before** starting the new phase.

#### Phase 1: Plan

1. **Write state file:** Create `.agents/TODO/.work-state` with mode, task slug, `phase: planning`, timestamp, `pid: $PPID` (the Claude Code process PID, for instance scoping), `auto-clear: true` if `--auto-clear` was passed, and `filter: {value}` if `--filter` was passed
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
10. Execute the plan, following the Acceptance Criteria as your checklist. **As you complete each criterion, update the task file to check it off** (`- [ ]` → `- [x]`).
11. **Code commit discipline:** Commit after each logical unit of work — a completed function, a fixed bug, a batch of related changes. Never leave uncommitted code work.
    - **Code commits only contain project source files.** Never mix in `.agents/TODO/` files.
    - **Record each code commit hash** in the task file's `commits` frontmatter field (short hash, e.g. `abc1234`). Update the list after each commit.

#### Execution Quality Principles

These principles guide HOW you execute, not just WHAT you execute:

- **Fidelity:** The implementation should accurately represent what it does. Interfaces match their semantics (reads are GETs, mutations are POSTs). Uncertainty is displayed, not hidden (tooltips on computed metrics, error bars on averaged quantities). When two approaches have comparable effort, prefer the more correct one.
- **Completeness:** When implementing a pattern or fix, apply it everywhere it's relevant — not just the first location. A change that works in the compare view but not the run detail view is incomplete. Before transitioning to verify, scan the codebase for other locations where the same treatment should apply. Either include them or explicitly justify their exclusion in the work report.
- **Parsimony:** Implement exactly what's needed. No speculative features, no backwards-compatibility shims for pre-prototype code, no abstractions without concrete consumers. But also no half-measures that technically satisfy a criterion without solving the actual problem — if the useful thing is X and you can only deliver X/2, flag it for discussion rather than shipping something useless.

#### Phase 3a: Verify Plan (fresh subagent)

Generate the verify plan using a **fresh subagent** (separate reasoning context — avoids the executor's blind spots about what to test).

12. **Update state file:** Set `phase: verify`
13. **Task tracking commit:** Commit the task file status change to in-progress (`.agents/TODO/` files only, prefix message with `[todo]`)
14. **Spawn a `general-purpose` subagent** with `model: "opus"`:
    ```
    Read ~/.claude/skills/todo/verify-agent.md and generate the verify plan
    for the task file at: .agents/TODO/{slug}.md
    ```
    The subagent reads the task file (acceptance criteria, changed files, code) and appends a `## Verify Plan` section with concrete, actionable check items.

#### Phase 3b: Work Report (executor)

Write the work report while execution context is still fresh, before verification begins.

15. **Work report:** Append a `## Work Report` section to the task file documenting:
    - **What was done:** Summary of changes made
    - **How it was done:** Technical approach, tools/patterns used
    - **Decisions made:** Any non-obvious choices and their reasoning
    - **Files changed:** List of key files created/modified
    - **Sources Consulted:** Which coding standards files from `~/.claude/coding-standards/` were read (if any)
    - **Follow-up:** Any discovered work that should become new tasks (create them)

#### Phase 3c: Verify Execute (executor)

The executor runs the checks from the verify plan and fixes any failures.

16. Read the `## Verify Plan` section from the task file
17. **Execute each item**, checking them off as they pass. For Playwright verification:
    - Determine the dev server URL from `package.json` scripts (e.g., `--port 3040` → `http://localhost:3040`)
    - Use `browser_navigate` to open the relevant page — **always attempt this before marking any Playwright check as skipped**
    - Use `browser_snapshot` to capture the accessibility tree
    - **Actually interact with the feature** — click buttons, fill forms, trigger the behavior
    - Use `browser_take_screenshot` for visual evidence
    - Check `browser_console_messages` for errors and `browser_network_requests` for failed API calls
18. **Append `## Verify Report`** documenting results (checked items with evidence)
19. If any items fail → fix the issue, commit the fix (code-only commit), re-verify failed items only
20. Reset retry counter (`.claude/todo-loop-retries`) on successful verification

#### Phase 3d: Human Validation (fresh subagent, conditional)

After agent verification passes, generate a human validation checklist — **only if the task warrants it.** Many purely technical tasks (refactors, bug fixes, backend logic) are fully agent-verifiable and should skip human validation.

21. **Spawn a `general-purpose` subagent** with `model: "opus"`:
    ```
    Read ~/.claude/skills/todo/validate-agent.md and generate the human validation section
    for the task file at: .agents/TODO/{slug}.md
    ```
    The subagent decides whether human validation adds value. If all verification is agent-automatable, it appends a brief skip notice. Otherwise it appends 1-3 focused checks (up to 5 for complex tasks) targeting only things agents cannot assess: subjective UX judgment, production-environment behavior, business logic decisions, or design tradeoffs.

#### Phase 4: Complete

22. **Update state file:** Set `phase: complete`
23. Set `status: done`, `updated` to today in the task file frontmatter
24. **Notify completion:** Send OS notification via Bash:
    ```bash
    notify-send -u normal "TODO Task Completed" "Finished: {task-slug}" -t 5000
    ```
    (On macOS use `osascript -e 'display notification "Finished: {task-slug}" with title "TODO Task Completed"'`)
25. Run the **lint** procedure to sync INDEX.md
26. **Task tracking commit:** Commit all `.agents/TODO/` changes (work report, human validation, verify plan/report, status, INDEX.md) with `[todo]` prefix
27. **Update state file:**
    - If mode is `single`: delete `.agents/TODO/.work-state`
    - If mode is `loop` or priority (`P0`, `P1`, etc.) **without `auto-clear`**: clear task field, pick next eligible task (respecting `filter` if set), continue to step 28
    - If mode is `loop` or priority **with `auto-clear: true`** AND there are more eligible tasks:
      1. Pick next eligible task (respecting `filter` if set)
      2. Write `.agents/TODO/.work-state` with: the new task slug, `phase: planning`, updated `pid: $PPID`, `auto-clear: true`, `filter: {value}` (preserved from current state if set), and `clear-pending: true`
      3. **STOP IMMEDIATELY.** Do not begin planning. Do not read any files. Do not output anything further. The PostToolUse hook will detect `clear-pending: true`, kill this Claude process, and relaunch with fresh context. The new instance will pick up the next task via the auto-start SessionStart hook.
    - If no more eligible tasks (any mode): delete state file and report summary (no restart)
28. In loop/priority modes (without `auto-clear`): repeat pick → plan → execute → verify → complete until no eligible tasks remain (respecting priority and tag filters if set), then report summary

### Git Commit Discipline

Two separate commit streams throughout the work lifecycle:

**Code commits:** Only project source files. Concise messages explaining *why*. Stage specific files.
**Task tracking commits:** Only `.agents/TODO/` files. Prefix with `[todo]`. Status changes, work reports, verify reports, INDEX.md.

**Phase transitions:**
- **Enter executing:** Code commit any prior work. Task tracking commit: task status → in-progress.
- **Enter verify:** Code commit all implementation work. Task tracking commit: verify plan appended.
- **Enter complete:** Code commit any verify-phase fixes. Task tracking commit: work report, verify report, human validation, status → done, INDEX.md regenerated.

### Pre-commit Verification

Before every code commit, run **all three checks** on your changed files:

1. **Format** — apply the project's autoformatter (e.g., `biome format --write`, `prettier --write`,
   `black`, `gofmt`). Format first so lint/typecheck run on canonical style.
2. **Lint** — run all configured linters (e.g., `biome lint`, `eslint`, `ruff`). Fix any new issues
   you introduced. Do not commit code with lint errors you caused.
3. **Typecheck / compile** — run the type checker or compiler (e.g., `tsc --noEmit`, `mypy`,
   `go build`). Do not commit code that breaks the build.

The specific tools depend on the project. Check the project's `package.json`, `Makefile`,
`pyproject.toml`, or equivalent for available commands. If the project has no formatter or
linter configured and you're doing substantial work, propose setting them up with the user.

### Picker mode

1. Run pick logic, take top 5
2. Use AskUserQuestion to present the tasks with their titles and priorities
3. User selects one
4. Execute that task

---

## Sub-command: archive

Trigger immediate full archive (same logic as lint auto-archive, but no thresholds — archive ALL done tasks).

1. Glob `.agents/TODO/done/*.md` for all tasks
2. For each task, read the `updated` date from frontmatter
3. Move to `.agents/TODO/archive/done/YYYY-MM-DD/` using the task's `updated` date for the folder name
4. Run the **lint** procedure
5. Report how many tasks were archived


