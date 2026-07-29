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
| `status` | enum | Yes | `pending`, `in-progress`, `blocked`, `done`, `closed`, `backlog` |
| `created` | timestamp | Yes | `YYYY-MM-DD_HH:mm` (local time, 24h) when task was created. Set once and never changed. |
| `updated` | timestamp | Yes | `YYYY-MM-DD_HH:mm` (local time, 24h) of last modification. Bumped to *now* every time the task file is edited. |
| `depends-on` | list | Yes | Slugs of tasks that must be done before this one. Empty list `[]` if none. |
| `tags` | list | Yes | Free-form labels. Empty list `[]` if none. |
| `commits` | list | No | Git commit hashes (short form) for code changes made during this task. Empty list `[]` or omitted for new/unstarted tasks. Populated by the executor during the execute phase. |
| `model` | enum | No | Which model executes this task: `opus` (default — implementation work), `sonnet` (mechanical sweeps: renames, migrations, scaffolding), or `inline` (the orchestrating session executes it itself — judgment-dense work: diagnosis, design adjudication, task breakdown). The orchestrator may override with a noted reason. |
| `human-validation` | enum | No | `pending` once a `## Human Validation` section is appended and awaits the user; `done` after the user's pass; omitted when validation was skipped as not warranted. Drives `REVIEW-QUEUE.md`. |

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
| `closed` | Resolved without implementation — obsolete, superseded, or won't-do. Include a one-line reason in the task body. |
| `backlog` | Not yet actionable — idea, research needed, or deferred. Completely excluded from work loop. Promote to `pending` when ready. |

**Backlog vs priority:** `status: backlog` is orthogonal to priority. Backlog tasks have priorities too (P0-P5) but are explicitly excluded from the work loop. A P1 backlog task is important but not yet actionable. Promote to `pending` when ready. The work loop only picks `status: pending` tasks.

## File Naming

- Filename: `{slug}.md` (kebab-case, no numeric prefix)
- Active tasks: `.agents/TODO/{slug}.md`
- Backlog tasks: `.agents/TODO/backlog/{slug}.md`
- Done tasks: `.agents/TODO/done/{slug}.md`
- Closed tasks: `.agents/TODO/closed/{slug}.md`
- Archived done: `.agents/TODO/archive/done/YYYY-MM-DD/{slug}.md`
- Archived closed: `.agents/TODO/archive/closed/YYYY-MM-DD/{slug}.md`

## Task Template

```markdown
---
slug: SLUG
title: TITLE
priority: P2
status: pending
created: TIMESTAMP   # YYYY-MM-DD_HH:mm (local time, 24h)
updated: TIMESTAMP   # YYYY-MM-DD_HH:mm (local time, 24h)
depends-on: []
tags: []
commits: []
---

# TITLE

## Context
Why this task exists, background info for an agent to understand the problem.

## Key Files
- `path/to/file.ts` - What's relevant about it

## Read first
- `path/to/file` — why
- https://... — why
- commit `abc1234` — why

## Constraints
Scope fences and invariants (optional, but strongly recommended for dispatched
tasks): what NOT to touch, known gotchas, decisions already made that the
executor must not relitigate.

## Verification recipe
How to prove it works against the running system (optional; concrete commands,
URLs, expected outputs). The verifier derives its plan from this plus the diff.

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
```

**The task file is the entire context transfer.** A dispatched executor starts
with zero conversation history — it knows only what the file says plus what the
files it's told to read say. Write briefs accordingly: exact paths and line
ranges, resolved judgment calls, explicit scope fences. A task that still
needs decisions is not dispatch-ready; either resolve them at creation time or
mark it `model: inline`.

## .work-state File

`.agents/TODO/.work-state` tracks work-in-progress across context resets. YAML format:

```yaml
mode: loop          # single, loop, P0, P1, P2, P3, P4, P5
task: task-slug     # current task being worked on
phase: briefing     # briefing, executing, verifying, complete
started: 2026-02-06T21:50:00Z
pid: 12345          # Claude Code process PID ($PPID) for instance scoping
inline: true        # optional — orchestrator executes tasks itself (--inline)
filter: tags:assessment  # optional — restrict pick logic to matching tasks
batches: [8, 11, 12]     # optional — ordered batch sequence for the loop (from --batches)
branch-acknowledged: eval/foo  # optional — user confirmed work on this non-main branch
ledger: CONTINUATION.md  # optional — pointer to the continuation ledger; READ IT FIRST on resume
```

| Field | Description |
|-------|-------------|
| `mode` | Work mode: `single` (one task), `loop` (all tasks, batch-ordered), or priority level (`P0`-`P5`) |
| `task` | Slug of the current task being worked on |
| `phase` | Current phase: `briefing`, `executing`, `verifying`, or `complete` |
| `started` | ISO timestamp when work began |
| `pid` | PID of the Claude Code process that owns this work state (`$PPID`). Used by the stop hook for instance scoping and crash detection. |
| `inline` | Optional. When `true`, the orchestrating session executes tasks itself instead of dispatching executor subagents. Set by `--inline` on `/todo work`. |
| `filter` | Optional. Restricts pick logic to matching tasks. Format: `tags:{tag}` (tasks must have the tag). Persists across context clears so the loop stays scoped. Set by `--filter` flag. |
| `batches` | Optional. Ordered list of batch numbers scoping + sequencing the loop (e.g. `[8, 11, 12]`). Persists across session boundaries so batch order survives a stop-and-resume. Set by `--batches` flag. |
| `branch-acknowledged` | Optional. Branch name the user confirmed working on after a Branch Sanity Check warning. Suppresses re-prompts within the same `.work-state` lifetime. Cleared when work-state is deleted or `git checkout` switches branches. |
| `ledger` | Optional. Path (relative to `.agents/TODO/`) of the [Continuation Ledger](#continuation-ledger). Its presence is a reminder to read the ledger **before** this file — `.work-state` is the resume *pointer*, the ledger is the resume *context*. |

(`auto-clear` / `clear-pending` are retired: continuity across context limits is
carried by this file plus the task files themselves — see **Session continuity**
under the work sub-command. A fresh session resumes from `.work-state`; no
restart machinery.)

The file is:
- Created when `/todo work` begins a task
- Updated when phase changes
- Deleted when work completes (single mode) or no more eligible tasks (loop/priority modes)
- Checked on any `/todo` invocation to resume interrupted work

## Task File Section Order

Completed task files have these sections in order:
1. `## Context` — why the task exists
2. `## Key Files` — relevant source files
3. `## Constraints` / `## Verification recipe` — optional brief sections (see template)
4. `## Acceptance Criteria` — checkbox items
5. `## Work Report` — executor's completion summary (Phase 2)
6. `## Verify Plan` — verification checklist (fresh verifier subagent, Phase 3)
7. `## Verify Report` — the verifier's results (Phase 3)
8. `## Human Validation` — human-facing checklist (fresh subagent, Phase 3b)

## Work Report Section

When a task is completed, a `## Work Report` section is appended. Format:

```markdown
## Work Report

**Date:** YYYY-MM-DD_HH:mm

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

**Step 0 — read the continuation ledger.** If a ledger exists, read it **before**
`.work-state` — at `.agents/TODO/CONTINUATION.md`, or at whatever path `.work-state`'s
`ledger:` field names if it is set and differs. `.work-state` tells you *where* you are; the ledger tells you *the
deal* — standing agreements, disciplines in force, routed decisions, and the loop narrative
(see [Continuation Ledger](#continuation-ledger)). Reading it first is what stops a cold
context from re-litigating a settled agreement or blowing past a banked scope note.

Then, check if `.agents/TODO/.work-state` exists. If it does:

1. Read the file to get the current work state
2. **Check PID ownership:** Read `pid:` from the file and compare with current `$PPID`:
   - **PID matches** (same instance, e.g. after context compaction): proceed directly to step 4 — this is our own work.
   - **PID missing or owner process dead** (crashed/restarted instance): use `AskUserQuestion` to prompt the user: "Found orphaned work state for {task} ({phase} phase). The Claude instance that owned it (PID {pid}) is no longer running — it appears to have crashed or been force-stopped." Options: "Resume" (claim ownership and continue the work loop) / "Ignore" (leave `.work-state` as-is and continue with the user's original requests in this conversation) / "Abort" (delete `.work-state` and proceed normally).
   - **PID differs and owner process alive** (different active instance): do NOT resume. Use `AskUserQuestion` to let the user know: "Another Claude instance (PID {pid}) is actively working on {task} ({phase} phase). What should this instance do?" Options: "Take over" (update PID and resume) / "Leave it" (proceed with normal routing). If user chooses "Leave it", proceed with normal routing. If "Take over", continue to step 3.
3. **Update PID:** If resuming, overwrite the `pid:` field with the current `$PPID` to claim ownership.
4. Inform the user: "Resuming work on {task} ({phase} phase, {mode} mode)"
5. Continue from the saved phase:
   - If `phase: briefing` → continue the brief-readiness pass (Phase 1)
   - If `phase: executing` → the executor subagent is gone with the session; check the task file and `git log` for partial work (committed work survives), then re-dispatch a fresh executor with the brief plus a note of what already landed. In `--inline` mode: re-read the plan/brief and continue implementing.
   - If `phase: verifying` → check which sections exist (`## Work Report`, `## Verify Plan`, `## Verify Report`, `## Human Validation`), then resume from the first missing step (re-dispatch the verifier or validation subagent as needed)
   - If `phase: complete` → mark done, lint, commit, update REVIEW-QUEUE.md
6. Do NOT start fresh or re-pick a task — resume the exact task from the state file

This ensures work survives context compaction while preventing accidental takeover of another instance's work.

## Branch Sanity Check (DO AFTER RESUME, BEFORE ROUTING)

Before starting or resuming work, surface any current-branch state that suggests work is silently diverging from `main`. Goal: catch this within the first invocations, not after hundreds of commits.

Quick procedure (cheap; run on every `/todo work` invocation):

1. Get current branch: `git branch --show-current`. Skip the check if it returns `main` or `master`.
2. Get ahead/behind vs the integration trunk: `git rev-list --left-right --count main...HEAD` (fall back to `master` if `main` doesn't exist).
3. Check upstream tracking: `git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null` — empty means no remote tracking branch (never pushed).

**Trigger a warning when any of these holds:**
- Branch name matches `^(eval|scratch|spike|wip|tmp|exp)/` — these conventionally suggest experimental scratch
- Ahead-count ≥ 20 AND no upstream tracking — silent divergence
- Ahead-count ≥ 100 (any state) — substantial divergence, even with upstream

**On warning:** use `AskUserQuestion` once per `.work-state` lifetime with options like:
- "Continue on this branch" — write `branch-acknowledged: <branchname>` to `.work-state` so you don't re-prompt within the same work session
- "Switch to main first" — pause and let the user run `git checkout main` (or whatever) before resuming
- "Stop and plan integration" — work-state is cleared; user files an integration task

After the user acknowledges via either path, don't re-prompt unless the branch changes. The acknowledgement persists with the work-state.

**Skip the check entirely when:**
- `.work-state` already has a matching `branch-acknowledged` entry for the current branch — user already confirmed this session
- Branch is `main`/`master` — no divergence question

Don't block on the first commit-into-the-branch; just surface it once. The point is to catch the situation when it's still cheap to redirect, not to interrupt every operation.

## External Information Discipline

This is a default behavior across every /todo sub-command — both `create` (enrichment) and `work` (planning, execution, verify).

**The rule.** Before declaring any external thing missing, broken, unknown, or "doesn't exist" — packages, third-party APIs, vendor products, GitHub repos, papers, frameworks, concepts — do a cursory authoritative check. Don't argue from absence-in-this-monorepo or from training-cutoff intuition.

**When to fire.** Any of these triggers the rule:
- A package name is mentioned that isn't in `pnpm-lock.yaml` / `package.json` / equivalent.
- A third-party product or company is mentioned (Mastra, Dolt, Kiln, Traefik, Tiptap, Hono, NATS, OpenAI, Anthropic SDK, etc.).
- A GitHub repo is referenced (`org/repo`, a URL, or a verbal mention).
- A paper, framework, technique, or concept comes up that isn't obviously already in scope (e.g. "react-flow", "differential dataflow", "structured outputs", "MCP").

**What to do.**

1. Identify the authoritative source — vendor docs URL, npm registry entry, GitHub README.
2. Fetch it:
   - npm packages: `pnpm view <pkg> homepage` (and `pnpm view <pkg>` for the registry record).
   - Vendor APIs / products: `WebSearch '<thing> docs site'` → pick the vendor URL → `WebFetch` it.
   - GitHub repos: fetch the README and (when relevant) the docs subdirectory.
3. Base the plan on the page contents, not on `node_modules/.../dist/*.d.ts` guesses, lockfile absence, or "I think the API looks like…" intuition.
4. Reserve "missing / not installed / doesn't exist" language for things genuinely absent from the public ecosystem, not "absent from this monorepo's lockfile."

**Worked example.**

> Task references `react-flow` and asks for a YAML schema describing nodes and edges. Before planning, run `pnpm view react-flow homepage` → `https://reactflow.dev`. Then `WebFetch https://reactflow.dev/api-reference/types/node` to read the documented `Node` shape. The plan now describes the YAML schema against the documented `Node`/`Edge` types — not against guesses. If `WebFetch` had returned a 404 for that page, the next step would be `WebSearch 'react-flow Node type api reference'` to find the current docs path, not "the API surface is unclear, skipping."

**Where this applies.**

- **`/todo create` enrichment pass** — automated via `enrich-agent.md` section D (Package + vendor docs). The create-time flow surfaces vendor docs URLs as `## Read first` suggestions before the task file is written. See [`enrich-agent.md`](./enrich-agent.md).
- **`/todo work` planning phase** — when the task body or `## Read first` references something external that wasn't enriched at create time (or when the planning agent uncovers a new external reference while exploring), the planning agent does the lookup itself before writing the plan. See Phase 1 step 6 below.
- **`/todo work` execute phase** — if implementation reveals a new external dependency mid-execution, apply the rule before assuming API shape; don't ship code based on training-cutoff guesses about an SDK surface.

**Failure modes the rule is meant to prevent.**

- "Package X isn't installed → I'll skip that approach" (when X exists on npm and a `pnpm view` would have confirmed it).
- "The vendor's docs are stale / I can't find them → I'll guess the API" (when a 30-second WebSearch would have surfaced the current docs).
- "I don't know what Y is, so I'll mark this task as blocked" (when a single WebSearch would have provided enough context to plan).

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

**Runs as a deterministic script** (changed 2026-07-30 — the agent tier is retired):

```bash
node ~/.claude/skills/todo/lint.mjs            # execute (moves, archive, INDEX regen, self-check)
node ~/.claude/skills/todo/lint.mjs --dry-run  # report what would change, touch nothing
```

The script implements the full `lint-agent.md` procedure — status-directory
moves via atomic `git mv`, the guarded archive sweep (never archives anything
with an open REVIEW-QUEUE line, including directory links, or
`human-validation: pending`), INDEX.md regeneration keyed on actual frontmatter
status with counts derived from emitted rows, REVIEW-QUEUE link rewriting for
moved files, and a self-check (link resolution, status enum, clean renames).
It exits non-zero with an error list if any self-check fails, and it does NOT
commit — review its report, then commit with the anchored pathspec it prints:

```bash
git add -A ':(top).agents/TODO' && git commit -m "[todo] Lint: ..."
git status --short   # confirm clean afterwards
```

**Why a script, not a model** (history: haiku produced four distinct
bookkeeping corruptions in one session; sonnet was reliable but cost ~100k
tokens and 3-10 minutes per run, plus a mandatory orchestrator verification
pass — for work that is a pure function of frontmatter + file layout).
`lint-agent.md` remains as the procedure's specification and the fallback for
repair scenarios the script refuses (its error list names what needs judgment
— fix by hand or dispatch a subagent with `lint-agent.md` for that case only).

After a run, spot-check remains cheap and still worthwhile after ANY tooling
change: INDEX links resolve + an in-flight task still reads `in-progress`.

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
   - **Close**: The new input supersedes or invalidates an existing task — set `status: closed` with a one-line reason (e.g., "Superseded by force compare toggle"), or delete it if it was never started
   - **Create**: No existing task covers this work — create a new one
4. **Enrichment pass.** For each task to be created or substantively updated (skip for plain status flips, closes, or merges that don't change scope), run the procedure in `~/.claude/skills/todo/enrich-agent.md`. The procedure produces a per-task list of discovered references (memory hits, doc grep matches, recent commits, vendor docs). Present the list to the user via `AskUserQuestion` (multiSelect) so they can accept or reject each reference before it lands in the task file.
5. For each task to create or update:
   a. Generate a kebab-case slug (new tasks) or reuse existing slug (updates)
   b. Write a descriptive title
   c. Assign priority (default P2 unless context suggests otherwise)
   d. Set status to `pending` (new) or preserve existing status (updates)
   e. Set `created` (new tasks: current timestamp `YYYY-MM-DD_HH:mm`, e.g. via `date +%Y-%m-%d_%H:%M`) and `updated` (always: current timestamp)
   f. Identify dependencies between tasks (new and existing) if any
   g. Write the task file to `.agents/TODO/{slug}.md` using the task template
   h. Fill in Context, Key Files (if identifiable), and Acceptance Criteria sections
   i. Pre-populate the `## Read first` section with the references the user accepted in step 4 (absolute file paths, full URLs, or `commit <short-hash> — <subject>` lines). If the user rejected everything or nothing was discovered, omit the section entirely — don't leave an empty heading.
6. Run the **lint** procedure to validate and regenerate INDEX.md
7. Report a summary of all changes: created, updated, merged, split, deprecated, and skipped tasks. Include a one-line note per created task indicating how many `## Read first` references were attached.

---

## Sub-command: work

Handles `work`, `work picker`, `work loop`, and `work <priority>`.

Parse remaining arguments after `work`:

- *(nothing)* → Pick and execute one task (the single highest-ranked eligible task — see Batch ordering model)
- `picker` → Show top 5, user picks, then execute
- `loop` → Execute tasks continuously, **batch by batch in ascending batch order** (see Batch ordering model). Batch is the primary execution axis: the loop exhausts the lowest-numbered batch's eligible tasks before moving to the next.
- `P0`-`P5` → Execute all tasks of that priority until done, **across all batches** (priority mode ignores batch ordering — use it for cross-batch urgency sweeps)
- `--batches {list}` → Ordered, comma-separated batch numbers scoping + sequencing the loop. Example: `work loop --batches 8,11,12` runs all of batch 8, then 11, then 12 (each in-batch order), and ignores every other batch. Persisted in `.work-state` as `batches:` so the order survives session boundaries. Without this flag, `loop` uses ascending batch order over all batches.
- `--inline` → Flag (combinable with any mode). The orchestrating session executes tasks itself instead of dispatching executor subagents — for interactive work, debugging sessions, or judgment-dense tasks. Inline execution uses plan mode (`EnterPlanMode`/`ExitPlanMode`) for user plan approval; dispatched execution does not (picking the batch IS the approval — the brief was written to be executed).
- `--filter tags:{tag}` → Further restrict the work loop to tasks matching the filter (orthogonal to `--batches`; both can combine). Persisted in `.work-state` so the filter survives context clears. Supports inclusion and exclusion:
  - `tags:{tag}` — include only tasks whose `tags` array includes `{tag}`. Example: `work loop --filter tags:assessment`.
  - `tags:!{tag}` — exclude tasks whose `tags` array includes `{tag}`. Example: `work loop --filter tags:!meta-design`.

### Batch ordering model

Work is organized into **batches** (a related feature/effort), executed sequentially. Within a batch, tasks are sequenced by dependency, then slug order, with priority as a tiebreak. This is the primary ordering the loop uses — global priority is **not** the top-level sort axis (it is an in-batch tiebreak, plus the explicit `work P0`-`P5` sweep mode).

**Deriving a task's batch and in-batch position from its slug** (no extra frontmatter needed — the convention is already in the slug prefix):

- **Batch** = the leading numeric segment of the slug. `06-05-adversarial-...` → batch `6`; `08-trigger-webhook-ingress` → batch `8`; `08-03b-preview-...` → batch `8`. A slug with no leading number (e.g. `auth-api`, `change-thread-diff-endpoint`) is **unbatched** and sorts *after* all numbered batches.
- **In-batch position** = natural sort of the full slug (numeric-aware), so `06-05` < `06-06` < `06-10`, and `08-03` < `08-03b`. Because the batch prefix is equal within a batch, this reduces to ordering by the step suffix.

**The three in-batch axes, in precedence** (only **eligible** tasks compete — a task is eligible once all its `depends-on` are `done`):

1. **`depends-on`** — the eligibility gate. An unmet dependency removes a task from contention until its blocker completes, so true ordering constraints always win.
2. **slug sequence** — natural-sort step order, as above.
3. **`priority` (P0-P5)** — tiebreak when multiple eligible tasks occupy the *same* batch step (e.g. a deliberate `06-05a` / `06-05b` fan-out). Models flowchart fan-out/fan-in; the basis for future parallel execution of same-step tasks.
4. **`created`** — final tiebreak (oldest first).

### Pick logic

1. Glob `.agents/TODO/*.md` (exclude the non-task files: `INDEX.md`, `REVIEW-QUEUE.md`, `CONTINUATION.md`) and read **frontmatter only** from each file
2. Filter to `status: pending` where ALL `depends-on` slugs have `status: done` (check active, `done/`, and `backlog/` directories). Tasks with `status: backlog` are never picked.
3. If priority mode is set (e.g., `work P0`), additionally filter to matching priority. **Priority mode bypasses batch ordering** — it sweeps the matching priority across all batches (sort by `created`, oldest first) and skips to step 7.
4. If `--batches {list}` is set (or `batches:` in `.work-state` during resume), keep only tasks whose derived batch (see Batch ordering model) is in the list.
5. If `--filter` is set (or `filter` in `.work-state` during resume), apply it:
   - `tags:{tag}` — keep only tasks whose `tags` array includes `{tag}`
   - `tags:!{tag}` — exclude tasks whose `tags` array includes `{tag}`
6. **Sort the eligible tasks** by, in order:
   1. **Batch rank** — if `--batches {list}` is set, the batch's position in that list; otherwise ascending batch number. Unbatched tasks (no leading number in slug) rank after all numbered batches.
   2. **Slug sequence** — natural sort of the slug (numeric-aware), so `06-05` < `06-06` < `06-10`, `08-03` < `08-03b`.
   3. **Priority** — P0 first → P5 last (tiebreak for same-step fan-out tasks).
   4. **`created`** — oldest first. Lexicographic string compare works for both `YYYY-MM-DD` (legacy) and `YYYY-MM-DD_HH:mm` (current) — a same-day task without a time sorts before a same-day task with one.
7. Select the first task (or present top 5 for picker mode). Because batch rank dominates, the loop naturally drains one batch before starting the next.

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

### Execute logic — Orchestrated State Machine

The session running `/todo work` is the **orchestrator**: it briefs, dispatches,
validates, and completes — it does not implement (unless `--inline`).
Implementation runs in **executor subagents** (fresh context, model chosen per
task), verification in a **fresh verifier subagent**. This keeps the
orchestrator's context at orchestration altitude across many tasks, puts the
token-heavy work on the model tier the task warrants, and preserves the
fresh-eyes property for verification.

Every task goes through **brief → execute → verify → complete**. No exceptions.

```
briefing → executing → verifying → complete → (pick next or done)
```

| Phase | Purpose | Runs in |
|-------|---------|---------|
| `briefing` | Confirm the task file is executor-ready; enrich if thin | orchestrator |
| `executing` | Implement the brief, commit, work report | executor subagent (task's `model`) — or the orchestrator itself with `--inline` |
| `verifying` | Fresh-eyes verify plan + execution + report; rework loop; human-validation section | verifier subagent + validation subagent, orchestrator adjudicates |
| `complete` | Independent spot-check, mark done, lint, commit, REVIEW-QUEUE | orchestrator |

Each phase transition: update `.work-state` **before** starting the new phase.

**Sequential, in place.** One executor at a time, working the live tree — the
project's running deployment is the standing invariant, and it only means
something if there is one tree it runs from. Parallel dispatch is allowed only
for provably disjoint tasks with the user's explicit go-ahead, via worktrees.

#### Phase 1: Brief

1. **Write state file:** Create `.agents/TODO/.work-state` with mode, task slug, `phase: briefing`, timestamp, `pid: $PPID` (the Claude Code process PID, for instance scoping), `inline: true` if `--inline` was passed, and `filter: {value}` if `--filter` was passed
2. Update task `status: in-progress`, `updated` to the current timestamp (`date +%Y-%m-%d_%H:%M`)
3. Read the full task file body — it IS the executor's prompt. Judge dispatch-readiness: does it carry everything a zero-context agent needs (exact paths, resolved decisions, scope fences, a verification recipe)? If not, run the discovery below and **enrich the task file itself** (not a separate plan file) until it does; unresolved judgment calls either get resolved here by the orchestrator or the task flips to `model: inline`.
4. *(--inline only)* Use `EnterPlanMode` to enter plan mode; the inline flow keeps interactive plan approval.
5. **Scope-vs-context check (self-discovery nudge).** Skim the task body and `## Read first` together and ask: *does the surfaced context match the implied scope?* If the task body mentions multiple files / multiple components / integration with another system / a refactor across a layer, but `## Read first` is empty or lists only 1–2 references, do additional discovery **before** dispatching:
   - `grep`/Glob for the symbols, file patterns, or component names the task names.
   - Read sibling/parent tasks (`depends-on`, related slugs in the body) — they often carry context the current task assumes.
   - Search `~/.claude/projects/<project-slug>/memory/` for relevant patterns or feedback memories.
   - For any external thing referenced but not yet enriched, apply [External Information Discipline](#external-information-discipline) (step 6 below).

   **Heuristic — lean toward more discovery when:**
   - The task names ≥ 2 files / components / surfaces and `## Read first` has < 2 entries pointing at them.
   - The body mentions "across", "all", "every", "wired up", "integration", "refactor", "rename", "deprecation".
   - You can't yet name (a) where the change lands, (b) who calls it, (c) what breaks if it's wrong. If any of the three is unclear, do more discovery.

   The cost of an extra grep is low. The cost of a plan that misses a caller is a re-do. Lean toward discovery.

   **Worked example.** Task says "rename `dispatch` to `activation` everywhere and update the workflow runner to use the new name." `## Read first` lists only `packages/core/src/runner.ts`. Before planning: `grep -rn "dispatch" packages/ apps/` to find every reference; read the workflow YAML schema files; read the runner's call sites. Now the plan can enumerate the rename surface accurately. Without the nudge, the plan would scope to `runner.ts`, miss the YAML schema + UI labels + DB column, and produce a half-done rename.
6. Explore as needed to judge the brief, and land what discovery finds **into the task file's sections** (`## Read first`, `## Constraints`, `## Verification recipe`). **If the task references any external thing (package, vendor product, GitHub repo, paper, framework, concept) whose authoritative source isn't already in `## Read first`, fetch the vendor docs before dispatching — see [External Information Discipline](#external-information-discipline) above. Do not dispatch a brief containing "I don't know what this is" or "it's probably missing"; resolve it first.**
7. *(--inline only)* Write an implementation plan addressing each item in the Acceptance Criteria.
   **IMPORTANT:** Start the plan file with `# Plan: {task-slug}` as the H1 heading, where `{task-slug}` is the **exact value** of the `task:` field in `.agents/TODO/.work-state` (which matches the task filename without `.md`). The auto-approve hook does a literal match against this value, so any mismatch will force a manual approval prompt.
8. *(--inline only)* Use `ExitPlanMode` to present the plan for user approval. (Dispatched tasks skip plan approval: the batch pick is the approval, and the enriched brief is the plan.)

#### Phase 2: Execute (dispatched — or inline)

9. **Update state file:** Set `phase: executing`
10. **Task tracking commit:** Commit the task file's status flip and any brief enrichment (`.agents/TODO/` files only, `[todo]` prefix) — the brief must be durable before dispatch.
11. **Dispatch the executor.** Spawn a `general-purpose` subagent with the task's `model` (default `opus`):
    ```
    Read ~/.claude/skills/todo/execute-agent.md and execute the task file at:
    .agents/TODO/{slug}.md
    ```
    The executor implements the brief, commits incrementally (code-only commits, hashes recorded in the task's `commits` frontmatter), checks acceptance criteria off as they land, and appends the `## Work Report`. It returns one of: **completed** (with a summary), **blocked** (with the named question — nothing speculative built), or **failed** (with diagnosis). Executors never mark tasks done, never touch other tasks, never push.
12. **On return:**
    - *completed* → proceed to Phase 3.
    - *blocked* → resolve the question if it's within the orchestrator's remit (update the brief, re-dispatch); escalate to the user if it's genuinely theirs. Record the resolution in the task file.
    - *failed* → read the diagnosis; either fix the brief and re-dispatch fresh, or take the task over `--inline` if it needs orchestrator-grade judgment. Two failed dispatches on one task = stop and escalate; don't burn a third.

    *(--inline instead: after the user approves the plan, the orchestrator executes it itself — same commit discipline, same criteria check-off, same Work Report.)*

#### Execution Quality Principles

These principles bind whoever executes — a dispatched executor (they are
restated in `execute-agent.md`) or the orchestrator inline:

- **Fidelity:** The implementation should accurately represent what it does. Interfaces match their semantics (reads are GETs, mutations are POSTs). Uncertainty is displayed, not hidden (tooltips on computed metrics, error bars on averaged quantities). When two approaches have comparable effort, prefer the more correct one.
- **Completeness:** When implementing a pattern or fix, apply it everywhere it's relevant — not just the first location. A change that works in the compare view but not the run detail view is incomplete. Before transitioning to verify, scan the codebase for other locations where the same treatment should apply. Either include them or explicitly justify their exclusion in the work report.
- **Parsimony:** Implement exactly what's needed. No speculative features, no backwards-compatibility shims for pre-prototype code, no abstractions without concrete consumers. But also no half-measures that technically satisfy a criterion without solving the actual problem — if the useful thing is X and you can only deliver X/2, flag it for discussion rather than shipping something useless.

#### Phase 3: Verify (fresh verifier subagent, rework loop)

Verification runs in a **fresh subagent** — separate reasoning context, so the
executor's blind spots about what to test don't carry into what gets tested.
One subagent both writes the verify plan and executes it (freshness lives in
the separate context, not in splitting plan from execution).

13. **Update state file:** Set `phase: verifying`
14. **Spawn a `general-purpose` verifier subagent** with `model: "opus"` (`sonnet` for mechanical tasks):
    ```
    Read ~/.claude/skills/todo/verify-agent.md and verify the task at:
    .agents/TODO/{slug}.md
    ```
    The verifier reads the task file (acceptance criteria, verification recipe, work report), inspects the actual diff (`git show` on the recorded commits), appends a `## Verify Plan`, executes every item — including live checks:
    - Determine the dev server URL from `package.json` scripts or project config
    - Use `browser_navigate` to open the relevant page — **always attempt this before marking any Playwright check as skipped**
    - Use `browser_snapshot` to capture the accessibility tree
    - **Actually interact with the feature** — click buttons, fill forms, trigger the behavior
    - Use `browser_take_screenshot` for visual evidence
    - Check `browser_console_messages` for errors and `browser_network_requests` for failed API calls
    — and appends a `## Verify Report` (checked items with evidence, failures with precise repro).
15. **Rework loop (orchestrator adjudicates):** on failures, re-dispatch the executor with the failure items appended to the brief; then re-verify the failed items (fresh verifier or the same one resumed). Bound: two rework rounds, then stop and escalate to the user with both reports.
16. Reset retry counter (`.claude/todo-loop-retries`) on successful verification

#### Phase 3b: Human Validation (fresh subagent, conditional)

After agent verification passes, generate a human validation checklist — **only if the task warrants it.** Many purely technical tasks (refactors, bug fixes, backend logic) are fully agent-verifiable and should skip human validation.

17. **Spawn a `general-purpose` subagent** with `model: "opus"`:
    ```
    Read ~/.claude/skills/todo/validate-agent.md and generate the human validation section
    for the task file at: .agents/TODO/{slug}.md
    ```
    The subagent decides whether human validation adds value. If all verification is agent-automatable, it appends a brief skip notice. Otherwise it appends 1-3 focused checks (up to 5 for complex tasks) targeting only things agents cannot assess: subjective UX judgment, production-environment behavior, business logic decisions, or design tradeoffs. When checks are appended, set `human-validation: pending` in the task frontmatter.

#### Phase 4: Complete (orchestrator)

18. **Orchestrator acceptance.** Read the Work Report and Verify Report and the diff stat; independently spot-check one or two load-bearing claims against the running system (a curl, a page load — cheap, not a re-verification). The orchestrator is the last set of eyes before the task flips done; a report that doesn't hold up goes back through the rework loop, not into `done`.
19. **Update state file:** Set `phase: complete`
20. Set `status: done`, `updated` to the current timestamp (`date +%Y-%m-%d_%H:%M`) in the task file frontmatter
21. **Notify completion:** Send OS notification via Bash:
    ```bash
    notify-send -u normal "TODO Task Completed" "Finished: {task-slug}" -t 5000
    ```
    (On macOS use `osascript -e 'display notification "Finished: {task-slug}" with title "TODO Task Completed"'`)
22. **Update `REVIEW-QUEUE.md`:** if the task carries `human-validation: pending`, add a line to `.agents/TODO/REVIEW-QUEUE.md` — `- [ ] [{slug}]({path}) — {one-line what-to-look-at}`. This file is the user's single review surface; they check items off (or tell the orchestrator, which flips `human-validation: done` and removes the line).
23. **Update the [Continuation Ledger](#continuation-ledger)** (`.agents/TODO/CONTINUATION.md`) if present: move the finished task into *Session progress*, set the resume point + next picks in *Current loop state*, add any discipline this task taught to *Disciplines in force*, record anything routed to review, and refresh the `**Last updated:**` line. This is the transition where the ledger earns its keep — skipping it here is what makes a ledger lag and lie.
24. Run the **lint** procedure to sync INDEX.md
25. **Task tracking commit:** Commit all `.agents/TODO/` changes (work report, verify plan/report, human validation, status, INDEX.md, REVIEW-QUEUE.md, CONTINUATION.md) with `[todo]` prefix
26. **Update state file:**
    - If mode is `single`: delete `.agents/TODO/.work-state`
    - If mode is `loop` or priority (`P0`, `P1`, etc.): clear task field, pick next eligible task (respecting `batches` order and `filter` if set), and repeat brief → execute → verify → complete until no eligible tasks remain; then delete the state file and report a summary (tasks completed, review-queue additions, anything escalated)

### Session continuity (no auto-clear)

The orchestrator's context grows slowly (briefs, reports, adjudication — not
implementation), but it does grow. **At roughly 85% context usage, finish the
task in flight, then stop cleanly**: leave `.work-state` pointing at the next
picked task in `phase: briefing`, report the stopping point, and tell the user
to start a fresh session with `/todo work` — the Resume Check picks it up with
nothing lost, because every piece of durable state lives in the task files,
`.work-state`, INDEX.md, REVIEW-QUEUE.md, and `CONTINUATION.md`, all committed.
There is no restart machinery and no context-clear hook; continuity is a
property of the files.

**Check the actual number before stopping.** Stopping "because context feels
long" wastes a usable session — run `/context` (or whatever the harness exposes)
and stop on the measurement, not the feeling.

The four continuity artifacts divide as follows — each answers a different
question, and none substitutes for another:

| Artifact | Answers | Lifetime |
|----------|---------|----------|
| `.work-state` | *Where am I?* — task + phase + owning pid. Mechanical only. | Deleted when the loop ends |
| `CONTINUATION.md` | *What's the deal?* — standing agreements, disciplines, routed decisions, narrative | Durable, committed |
| `INDEX.md` | *What's left?* | Regenerated by lint |
| `REVIEW-QUEUE.md` | *What's waiting on the user?* | Durable, committed |

### Continuation Ledger

`.agents/TODO/CONTINUATION.md` is the loop's durable memory. `.work-state` is a
bare resume pointer: it cannot tell a fresh context that the user deferred all
review to the end of the queue, that a task was routed rather than skipped, or
that a discipline was learned the hard way three tasks ago. The ledger carries
exactly that.

**Committed, not gitignored** (unlike `.work-state`). It is the session's
durable memory and belongs in history, in the `[todo]` commit stream.

**Schema** — keep these sections, in this order:

```markdown
# Continuation Ledger
> Read this FIRST after a /clear or in a fresh session, before .work-state.

## How to resume            — the ordered steps for a cold context
## Standing agreements      — the deal with the user; do NOT re-litigate
## Disciplines in force     — lessons learned this run, stated as rules
## Current loop state       — mode, resume point, routed/blocked items, next picks
## Session progress         — rolling: completed / closed / backlogged / filed
## Open threads             — what's waiting on the user
**Last updated:** <timestamp> — <one line on where things stand>
```

**Maintenance cadence.** Update the ledger at **every task transition and every
summary** — the same cadence as `.work-state` phase bumps. A ledger that lags
is worse than none: it will be trusted and be wrong.

**What goes in each section — and the distinction that matters most:**

- **Standing agreements** are *decisions the user made*. They are durable and a
  fresh context must not reopen them.
- **Disciplines in force** are *rules learned this run*. Also durable.
- **Banked technical claims** — "the transport doesn't exist", "this premise is
  wrong", "scope corrected" — are **facts, and facts rot**. Record them, but
  never mark them beyond question.

> **The ledger's failure mode, learned in its own trial run:** a prior
> orchestrator banked a scope correction marked *"do not relitigate"*. A later
> session read it, trusted it, and nearly dispatched on it — both of its
> load-bearing premises turned out to be false, and a settled spec already
> answered the question it was re-deriving. **"Do not relitigate" protects
> decisions, not facts.** Spot-check the load-bearing facts of any banked note
> before acting on it, however authoritative it sounds. Write banked findings
> so a later reader knows which kind they are.

**Don't duplicate.** The ledger points at task files and REVIEW-QUEUE entries;
it does not restate their content. Its job is orientation, not storage.

### Git Commit Discipline

Two separate commit streams throughout the work lifecycle:

**Code commits:** Only project source files. Concise messages explaining *why*. Stage specific files. Made by whoever executes (the dispatched executor, or the orchestrator inline).
**Task tracking commits:** Only `.agents/TODO/` files. Prefix with `[todo]`. Status changes, work reports, verify reports, INDEX.md, REVIEW-QUEUE.md, CONTINUATION.md. Made by the orchestrator (the executor appends its sections to the task file; the orchestrator commits them).

**Phase transitions:**
- **Enter executing (dispatch):** Task tracking commit: status → in-progress + brief enrichment.
- **Enter verifying:** All implementation work is code-committed by the executor before it returns. Task tracking commit: work report appended.
- **Enter complete:** Code commit any rework fixes (executor). Task tracking commit: verify plan/report, human validation, status → done, INDEX.md, REVIEW-QUEUE.md, CONTINUATION.md.

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
2. For each task, read the `updated` timestamp from frontmatter
3. Move to `.agents/TODO/archive/done/YYYY-MM-DD/` using only the **date portion** of the task's `updated` timestamp (truncate the `_HH:mm` suffix) for the folder name. Folder grouping is per-day; the per-task timestamp lives inside the file's frontmatter.
4. Run the **lint** procedure
5. Report how many tasks were archived


