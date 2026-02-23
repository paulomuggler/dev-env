---
name: code-review
description: Code review — analyze files for issues, create refactoring tasks, execute fixes
user-invocable: true
disable-model-invocation: false
arguments: $ARGUMENTS
---

# /code-review — Code Review Skill

Single-file-scope code review. Stage 1: read-only analysis. Stage 2: refactor via 4-phase work protocol. Cross-file concerns escalate to `/architecture-review`.

## Execution Rules

1. **Never use worktree isolation** — NEVER pass `isolation: "worktree"` to the Task tool. All subagents work in the main repo. Each task targets a unique file — no conflicts.
2. **Subagent type: `"general-purpose"`** — NEVER use `"Explore"` or other types.
3. **Pass the `model` parameter** — every `Task` call MUST include `model: "{model}"` from `--model` flag (default: `sonnet`).
4. **Subagents are autonomous** — analysis subagents create analyze tasks and write findings. Validation subagents verify findings and create refactor tasks. Parent only orchestrates.
5. **Parent validates, never redoes** — spot-check output after subagents return. Never re-analyze files.
6. **Resolve `~` before spawning subagents** — subagents cannot reliably expand `~`. Before constructing any subagent prompt, resolve `~` to the absolute home directory path (e.g., `/home/user/.claude/...`). Apply this to all skill file paths and guide paths in prompts.

## Flags

| Flag | Default | Effect |
|------|---------|--------|
| `--serial` | off | Sequential subagent execution instead of parallel |
| `--model` | `sonnet` | Model for subagent `Task` calls (`haiku`, `sonnet`, `opus`) |
| `--partition` | *(auto)* | Override the auto-derived partition slug for the batch |

## Resume Check

If `.agents/TODO/.review-state` exists: read it, inform user "Resuming review of {path} (stage {stage}, batch {batch})", resume from saved stage. Do NOT start fresh.

## Routing

| First token | Route |
|-------------|-------|
| `analyze` | Stage 1 only (remaining args = path/glob) |
| `refactor` | Stage 2 only (picks up pending refactor tasks from active batch) |
| `changed` | Review files changed in git history |
| `guide` | Guide management (see below) |
| `status` | Show active/done batches with stats |
| path/glob | Both stages sequentially |
| *(empty)* | Usage: `/code-review <path>`, `/code-review analyze <path>`, `/code-review refactor`, `/code-review changed` |

## Route: changed-files

| Pattern | Git command |
|---------|-------------|
| *(empty)* | Base from `.agents/TODO/.review-last-commit`, default `HEAD~1` |
| Digits (`5`) | `git diff --name-only --diff-filter=ACMR HEAD~{N}..HEAD` |
| Hex hash | `git diff --name-only --diff-filter=ACMR {hash}..HEAD` |
| `--since <date>` | `git log --since="{date}" --name-only --pretty=format: --diff-filter=ACMR \| sort -u` |

Record HEAD at start. Run resolved files through Stage 1 (+ Stage 2 unless `--analyze`). Write `.review-last-commit`, delete `.review-state`, report.

## Route: full

1. Create `.review-state` → 2. Stage 1 → 3. Update state to `stage: 2` → 4. Stage 2 → 5. Delete state, report.

---

## Review Batches

Each review run creates a timestamped batch directory under `.agents/TODO/reviews/`. All artifacts for a review round live in its batch directory.

### Directory Structure

```
.agents/TODO/reviews/
├── 2026-02-23-1430-db/              # Active batch
│   ├── analyze-{file-slug}.md
│   ├── refactor-{file-slug}.md
│   ├── findings.md                  # Manifest from fingerprint agent
│   ├── stage1-report.md             # Generated after Stage 1
│   └── stage2-report.md             # Generated after Stage 2
├── done/
│   └── 2026-02-22-1030-db/          # Completed batch
└── archive/
    └── 2026-02-15-0900-db/          # Old batch
```

### Batch Naming

Format: `YYYY-MM-DD-HHmm-{partition}` (e.g., `2026-02-23-1430-db`)

### Partition Naming

Derive a short, human-readable slug from the source path. Use judgment — the goal is a name that's recognizable and grep-friendly, not a mechanical transformation:

- Aim for 1-2 words that identify the scope: `db`, `workflows`, `ui-components`, `api-routes`
- Drop boilerplate path segments (`packages`, `core`, `src`, `apps`, `lib`) — focus on what distinguishes the code
- When files span multiple directories (e.g., `/code-review changed`), use a descriptive slug like `changed` or `mixed`
- Check collision with existing active batches; if collision, make the slug more specific

Override with `--partition <name>`.

Examples: `packages/core/src/db/` → `db`, `packages/core/src/db/repositories/` → `db-repos`, `apps/taskmill-ui/src/components/` → `ui-components`

### Batch Lifecycle

| Transition | Trigger |
|------------|---------|
| → active | Review starts, batch dir created |
| active → done | Stage 1 completes (analyze-only) or Stage 2 completes (full) |
| done → archive | Auto: batches >7 days old, or >5 in done/ |

**Invariant:** At most one active batch per partition. If a new review starts for a partition with an active batch, warn the user.

Done/archive transitions are automatic. Delegated to a haiku subagent (`git mv` + commit) to preserve parent context.

---

## Stage 1: Analysis (Read-Only)

Zero code modifications. Subagents create task files and write findings.

### Parent Procedure

1. **Resolve files** — expand path/glob. Filter out non-code files, generated dirs (`node_modules/`, `dist/`, `.git/`), files under 5 lines. If more than 30 files remain, warn the user with the count but proceed — do NOT silently truncate.

2. **Create batch** — derive partition (or use `--partition`), generate timestamp, create `reviews/{ts}-{partition}/`. Check for existing active batch with same partition — if found, warn user. Auto-archive: spawn a haiku subagent to move done/ batches older than 7 days (or if >5 in done/) to archive/ via `git mv` + commit. Write `.review-state`:
   ```yaml
   stage: 1
   source: path
   path: {source path}
   partition: {partition}
   batch: .agents/TODO/reviews/{ts}-{partition}
   mode: parallel
   started: {ISO timestamp}
   analyze-total: {N}
   analyze-done: 0
   refactor-total: 0
   refactor-done: 0
   ```

3. **Deduplicate** — glob `{batch}/analyze-*.md` and `{batch}/refactor-*.md` filenames. Skip files whose slug already exists. Do NOT read INDEX.md.

4. **Detect standards** — check file extensions and dependency manifests. Build guide paths from `~/.claude/coding-standards/`:
   - Language guides: `~/.claude/coding-standards/languages/{lang}.md` (e.g., typescript, shell)
   - Framework guides: `~/.claude/coding-standards/frameworks/{framework}.md` (e.g., hono, react)
   - Review overlays: `~/.claude/coding-standards/review/{name}.md` (severity prescriptions)

   If the project has `.claude/standards.yaml`, use it to scope which guides are relevant. If a needed guide doesn't exist, ask user to create or skip. Each batch should need at most 2-3 language/framework guides; split by affinity if more.

5. **Batch and spawn analysis subagents** — group files by size and guide affinity:

   | File size | Files per subagent |
   |-----------|-------------------|
   | <200 lines | 3-5 |
   | 200-500 lines | 2-3 |
   | 500+ lines | 1 |

   Each subagent `Task` call uses `subagent_type: "general-purpose"`, the `model` parameter, and this prompt:

   ```
   Read `~/.claude/skills/code-review/analyze-agent.md` — those are your complete instructions.

   Batch directory: {batch}

   Files to analyze:
   - {path1}
   - {path2}

   Coding standards (read before analyzing matching files):
   - ~/.claude/coding-standards/languages/{lang}.md
   - ~/.claude/coding-standards/frameworks/{framework}.md

   Review severity overlays (read for severity/category prescriptions):
   - ~/.claude/coding-standards/review/{name}.md
   ```

   Subagents create analyze-*.md files in the batch directory, write findings, commit, and return one-line summaries. They do NOT create refactor tasks.

6. **Coverage check** — after ALL analysis subagents return, glob `{batch}/analyze-*.md` and verify every input file has a corresponding analyze task. For any missing files, log a warning and re-spawn a single subagent to analyze only the missing files. This catches cases where a subagent silently dropped files from its batch.

7. **Validate and create refactor tasks** — wait for ALL analysis subagents to complete. Spawn validation subagents (using the `model` parameter, NOT haiku):

   ```
   Read `~/.claude/skills/code-review/validate-agent.md` — those are your complete instructions.

   Batch directory: {batch}

   Analysis tasks to validate:
   - {batch}/analyze-{slug1}.md
   - {batch}/analyze-{slug2}.md
   ```

   Validation subagents verify findings against source code, delete fabricated findings, and create refactor tasks in the batch directory for validated Critical/Warning findings. Parent handles any flagged issues from the validation summary.

8. **Fingerprint** — after all validation subagents complete, spawn a **haiku** subagent to extract a findings manifest:

   ```
   Read `~/.claude/skills/code-review/fingerprint-agent.md` — those are your complete instructions.

   Batch directory: {batch}

   Source path: {path}

   Analysis tasks to extract from:
   - {batch}/analyze-{slug1}.md
   - {batch}/analyze-{slug2}.md
   ```

   Uses `subagent_type: "general-purpose"`, `model: "haiku"`. Pass all analyze-*.md paths from step 6's glob. The agent writes `{batch}/findings.md`.

9. **Report** — spawn a **sonnet** subagent to generate the stage 1 report. Sonnet is required here — convergence matching needs the reasoning quality to handle category drift, line jitter, and consolidation detection reliably.

   ```
   Read `~/.claude/skills/code-review/report-agent.md` — those are your complete instructions.

   Batch directory: {batch}
   Stage: 1

   Aggregated counts:
   Pre-validation:  {N} Critical, {N} Warning, {N} Suggestion, {N} Nit ({N} total)
   Post-validation: {N} Critical, {N} Warning ({N} refactor-eligible)
   Adjustments: {N} fabricated removed, {N} false positives removed, {N} downgraded, {N} promoted to Warning, {N} promoted to Critical
   ```

   Uses `subagent_type: "general-purpose"`, `model: "sonnet"`.

   **Prior manifest lookup:** glob `reviews/done/*-{partition}/findings.md` and `reviews/archive/*-{partition}/findings.md`, take highest timestamp. If found, add to the prompt:

   ```
   Prior manifest path: {path to prior findings.md}
   Prior round date: {date from prior manifest}
   ```

   The report agent writes `{batch}/stage1-report.md` with convergence section if prior manifest was provided.

10. **Aggregate & display** — parent reads the report at `{batch}/stage1-report.md`, prints summary to user:

   ```
   Stage 1 Complete
   ────────────────
   Files analyzed: {N}

   Pre-validation:  {N} Critical, {N} Warning, {N} Suggestion, {N} Nit ({N} total)
   Post-validation: {N} Critical, {N} Warning ({N} refactor-eligible)

   Adjustments: {N} fabricated removed, {N} false positives removed, {N} downgraded,
                {N} promoted to Warning, {N} promoted to Critical

   Refactor tasks ({N}):
     P1: refactor-{slug} — {title} ({N} Critical, {N} Warning)
     P2: refactor-{slug} — {title} ({N} Warning)

   Files with no actionable findings: {list}
   ```

   If convergence data exists in the report, append:

   ```
   Convergence (vs {prior batch name})
   ──────────────────────────────────
   Confirmed: {N}  Consolidated: {N}  Not reproduced: {N}  New perspective: {N}
   New on changed code: {N}  New on unchanged code: {N}
   Changes on confirmed: {N} severity, {N} category
   ```

   List every refactor task with its priority and finding counts so the user can audit before running Stage 2.

11. **Lint** — spawn a subagent (using the `model` parameter) with this prompt:

   ```
   Read `~/.claude/skills/todo/lint-agent.md` — those are your complete instructions.
   Execute the full lint procedure on `.agents/TODO/`.
   ```

   Remember to resolve `~` per rule 6. Lint only touches TODO root — the reviews/ subdirectory is automatically excluded.

12. **If analyze-only:** spawn a haiku subagent to move the batch to done:
   - `git mv {batch} .agents/TODO/reviews/done/{batch-name}`
   - Commit with `[todo]` prefix
   - Parent deletes `.review-state`

---

## Stage 2: Refactoring

Subagents execute refactor tasks through the full 4-phase work protocol (plan → execute → verify → complete).

### Parent Procedure

1. **Discover tasks** — glob `{batch}/refactor-*.md` (batch from `.review-state`). Read frontmatter only (status + priority + tags). Select where tags contain `review` and `refactor`, status is `pending`. Sort by priority (P1 first), then created date. If none found: "No refactoring tasks."

2. **Batch and spawn subagents** — group by file size:

   | File size | Tasks per subagent |
   |-----------|-------------------|
   | <200 lines | 5-8 |
   | 200-500 lines | 3-5 |
   | 500+ lines | 1-2 |

   Each subagent `Task` call uses `subagent_type: "general-purpose"`, the `model` parameter, and this prompt:

   ```
   Read `~/.claude/skills/code-review/refactor-agent.md` — those are your complete instructions.

   Batch directory: {batch}

   Refactor tasks to process:
   - {batch}/refactor-{slug1}.md
   - {batch}/refactor-{slug2}.md
   ```

3. **Validate** — after subagents return, check each task file:
   - `status: done` in frontmatter
   - ALL 4 sections present: `## Acceptance Criteria`, `## Verify Plan`, `## Verify Report`, `## Work Report`
   - All criteria `[x]` or `[E]` (none `[ ]`)
   - If incomplete: re-read task, identify gaps, fix in parent context
   - Collect `archrev-refactor-*` escalation tasks

4. **Report** — spawn a **sonnet** subagent to generate the stage 2 report:

   ```
   Read `~/.claude/skills/code-review/report-agent.md` — those are your complete instructions.

   Batch directory: {batch}
   Stage: 2
   ```

   Uses `subagent_type: "general-purpose"`, `model: "sonnet"`. The agent writes `{batch}/stage2-report.md`.

5. **Lint** — spawn a subagent (using the `model` parameter) with this prompt:

   ```
   Read `~/.claude/skills/todo/lint-agent.md` — those are your complete instructions.
   Execute the full lint procedure on `.agents/TODO/`.
   ```

   Remember to resolve `~` per rule 6.

6. **Finalize** — spawn a haiku subagent to move the batch to done:
   - `git mv {batch} .agents/TODO/reviews/done/{batch-name}`
   - Commit with `[todo]` prefix
   - Parent deletes `.review-state`

---

## Route: refactor (standalone)

If no `.review-state`: scan `reviews/` for active batches (directories at `reviews/` root, not in `done/` or `archive/`) with pending `refactor-*.md` tasks. If one found, use it. If multiple, ask user. If none found, report "No active review batches with pending refactor tasks."

---

## Route: status

Show active batches, done batches, per-batch stats:

```
Review Batches
──────────────

Active:
  2026-02-23-1430-db — 12 analyze, 5 refactor (3 pending, 2 done)

Done:
  2026-02-22-1030-db — 8 analyze, 3 refactor (all done)
  2026-02-21-0900-api — 15 analyze, 7 refactor (all done)

Archive: 3 batches
```

Glob `reviews/*/`, `reviews/done/*/`, `reviews/archive/*/`. For each batch, count analyze-*.md and refactor-*.md, read refactor frontmatter for status breakdown.

---

## Guide Management

Standards live at `~/.claude/coding-standards/` — `languages/`, `frameworks/`, and `review/` subdirectories. Multiple guides apply simultaneously (e.g., TypeScript + React + Hono for a `.tsx` route handler).

- `guide list` — glob `~/.claude/coding-standards/{languages,frameworks,review}/*.md`, show metadata
- `guide <name>` — show if exists; if missing, ask user to create (generate from agent knowledge + OWASP/linter/style guide cross-reference) or skip. New guides go in the appropriate subdirectory of `~/.claude/coding-standards/`.

---

## State Files (gitignored)

**`.agents/TODO/.review-state`** — created at review start, deleted on completion:
```yaml
stage: 1
source: path          # or "changed"
path: src/lib/
partition: db
batch: .agents/TODO/reviews/2026-02-23-1430-db
mode: parallel
started: 2026-02-20T14:30:00Z
analyze-total: 12
analyze-done: 7
refactor-total: 0
refactor-done: 0
```

**`.agents/TODO/.review-last-commit`** — written when `/code-review changed` completes:
```yaml
commit: abc123def456789
date: 2026-02-21T12:23:00Z
```

## Git Discipline

- **Stage 1:** Task tracking commits only (`[todo]` prefix). Zero code changes. Stage only batch directory files.
- **Stage 2:** Code commits (source only) + task tracking commits (batch directory files only, `[todo]` prefix). Never mix.
