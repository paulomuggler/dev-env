---
name: review
description: Code review — analyze files for issues, create refactoring tasks, execute fixes
user-invocable: true
disable-model-invocation: true
arguments: $ARGUMENTS
---

# /review — Code Review Skill

Single-file-scope code review: analyze files read-only (Stage 1), then refactor via `/todo work` protocol (Stage 2). Every finding must be completable within one file. Cross-file concerns are escalated to `/architecture-review` (see Appendix).

---

## Execution Rules (READ FIRST)

These rules are non-negotiable. Violating any of them breaks the review.

1. **Never use worktree isolation** — NEVER pass `isolation: "worktree"` to the Task tool. All subagents work in the main repo directly. Each task targets a unique file, so there are no conflicts. Worktrees cause merge hell for zero benefit.
2. **Subagent type: `"general-purpose"`** — NEVER use `"Explore"` or any other type. Every `Task` tool call MUST use `subagent_type: "general-purpose"`.
3. **Pass the `model` parameter** — every `Task` tool call MUST include `model: "{model}"` where `{model}` comes from the `--model` flag (default: `opus`).
4. **Subagents write task files** — the parent agent does NOT write findings or analysis content. Subagents read source files, analyze, write findings into task files, create refactor tasks, and mark tasks done.
5. **Parent validates, never redoes** — after subagents return, the parent spot-checks output and fixes gaps. It does NOT re-analyze files or rewrite findings from scratch.

---

## Flags

Parsed from anywhere in `$ARGUMENTS`:

| Flag | Values | Default | Effect |
|------|--------|---------|--------|
| `--serial` | *(boolean)* | off | Process tasks in main context instead of via subagents |
| `--model` | `haiku`, `sonnet`, `opus` | `opus` | Model used for all subagent `Task` tool invocations |

---

## Resume Check

Before routing, check if `.agents/TODO/.review-state` exists. If it does:

1. Read the file to get current state
2. Inform user: "Resuming review of {path} (stage {stage}, {mode} mode)"
3. Resume: if `stage: 1` → continue Stage 1; if `stage: 2` → continue Stage 2
4. Do NOT start fresh

---

## Routing

Parse `$ARGUMENTS` (after extracting flags):

| First token | Route | Description |
|-------------|-------|-------------|
| `analyze` | **stage1** | Analysis only (remaining args = path/glob) |
| `refactor` | **stage2** | Refactoring only (picks up existing refactor-* tasks) |
| `changed` | **changed-files** | Review files changed in git history |
| `guide` | **guide-manage** | Show, create, or list review guides |
| `status` | **review-status** | Show review-tagged tasks |
| path or glob | **full** | Both stages sequentially |
| *(empty)* | **help** | Usage summary |

---

## Route: help

```
/review <path>                      Full review (analyze + refactor)
/review <path> --serial             Serial mode
/review <path> --model sonnet       Use sonnet for subagents
/review analyze <path>              Stage 1 only
/review refactor                    Stage 2 only
/review changed                     Since last reviewed commit
/review changed <N>                 Last N commits
/review changed <hash>              Since commit hash
/review changed --since <date>      Since date
/review changed --analyze           Stage 1 only
/review guide <name>                Show/create review guide
/review guide list                  List available guides
/review status                      Show review-tagged tasks
```

---

## Route: review-status

1. Glob `.agents/TODO/analyze-*.md` and `.agents/TODO/refactor-*.md`
2. Parse frontmatter, display grouped by type and status:

```
Review Tasks
────────────
Analyze (3 pending, 2 done)
  [ ] analyze-src-lib-api-client — Analyze src/lib/api-client.ts
  [x] analyze-src-lib-db         — Analyze src/lib/db.ts

Refactor (1 pending, 1 done)
  [ ] refactor-src-lib-api-client — Refactor src/lib/api-client.ts (P1)
  [x] refactor-src-lib-db         — Refactor src/lib/db.ts (P2)
```

---

## Route: changed-files

Review files changed in git history.

### Argument parsing

| Pattern | Git command |
|---------|-------------|
| *(empty)* | Base from `.agents/TODO/.review-last-commit`. If missing, default to `HEAD~1` |
| Pure digits (`5`) | `git diff --name-only --diff-filter=ACMR HEAD~{N}..HEAD` |
| Hex hash (`abc123`) | `git diff --name-only --diff-filter=ACMR {hash}..HEAD` |
| `--since <date>` | `git log --since="{date}" --name-only --pretty=format: --diff-filter=ACMR \| sort -u` |

Extra flags: `--analyze` (Stage 1 only).

### Execution

1. Record `HEAD` commit hash at start
2. Create `.review-state` with `source: changed`, `git-range: <base>..HEAD`
3. Run resolved files through Stage 1 (same procedure)
4. If `--analyze`: skip Stage 2, write `.review-last-commit`, delete `.review-state`, report
5. Otherwise: update state to `stage: 2`, execute Stage 2, write `.review-last-commit`, delete `.review-state`, report

---

## Route: full

Run Stage 1 then Stage 2 sequentially.

1. Parse path/glob and flags from `$ARGUMENTS`
2. Create `.review-state` (see State Files section)
3. Execute Stage 1
4. Update state: `stage: 2`
5. Execute Stage 2
6. Delete `.review-state`, report summary

---

## Route: guide-manage

See Guide Management section.

---

## Stage 1: Analysis (Read-Only)

Zero code modifications. Creates TODO tasks with findings.

### Parent Procedure

1. **Resolve files** — expand path/glob. Filter out:
   - Non-code files (images, lockfiles, binaries)
   - Generated directories (`node_modules/`, `dist/`, `.git/`, `build/`, `coverage/`)
   - Files under 5 lines

   Group small related files into batches of up to 5 per analysis task. Cap at 20 analysis tasks; warn user if exceeded.

2. **Detect guides** — detect languages/frameworks from file extensions and dependency manifests. For each batch, determine which guides apply (e.g., a `.tsx` file gets both `typescript.md` and `react.md`). If a needed guide doesn't exist, trigger the guide creation flow (see Guide Management).

3. **Deduplicate** — read `.agents/TODO/INDEX.md`. Skip files that already have `analyze-*` or `refactor-*` tasks.

4. **Create analysis task files** — for each file/batch, write `.agents/TODO/analyze-{file-slug}.md`:

   ```yaml
   ---
   slug: analyze-{file-slug}
   title: "Analyze {path} for code quality issues"
   priority: P2
   status: pending
   created: YYYY-MM-DD
   updated: YYYY-MM-DD
   depends-on: []
   tags: [review, analyze]
   ---

   # Analyze {path} for code quality issues

   ## Context
   Code review analysis of {path}. Read the file, apply all applicable review guides,
   and document findings by severity.

   ## Key Files
   - `{path}` — Target file
   - `~/.claude/skills/review/guides/{language}.md` — Language guide
   - `~/.claude/skills/review/guides/{framework}.md` — Framework guide (if applicable)

   ## Acceptance Criteria
   - [ ] Read target file completely
   - [ ] Apply categories: Security, Correctness, Performance, Error Handling, Code Quality, Style, Single-File Design, Comment Hygiene (plus anything else discovered)
   - [ ] Document all findings with severity, category, line numbers, evidence, and fix
   - [ ] Only flag issues completable within this single file
   ```

   Run lint after creating all tasks — spawn a `general-purpose` subagent with `model: "haiku"`:
   `Read ~/.claude/skills/todo/lint-agent.md and execute the lint procedure on .agents/TODO/`

5. **Spawn subagents** — batch analysis tasks using the Batching Strategy:

   **Parallel (default):** spawn one `general-purpose` subagent per batch, all in parallel.

   **Serial (`--serial`):** spawn one `general-purpose` subagent per task, sequentially (one at a time). Still uses subagents — serial means sequential execution, not main-context execution. This protects parent context from growing with each analysis.

   All subagent `Task` calls MUST use the `model` parameter from `--model` flag and the prompt template below.

6. **Validate subagent output** — spawn a validation subagent (model: `haiku` is sufficient) for each batch:

   Validation subagent prompt:
   ```
   You are validating Stage 1 code review output. For each analysis task below:
   1. Read the analysis task file. Confirm `status: done` and `## Findings` section exists with content.
   2. Confirm all acceptance criteria are `[x]`.
   3. For each refactor task that was created, verify its `## Findings to Address` entries
      appear verbatim in the corresponding analysis task's `## Findings` section.
      If a refactor task has findings NOT in the analysis, report it as INVALID.
   4. For EVERY Critical and Warning finding: re-read the source file at the claimed line number.
      Verify the `Evidence:` snippet matches the actual code. Report mismatches as FABRICATED.
   5. Report a summary: tasks validated, findings verified, any issues found.

   Analysis tasks: {list}
   Refactor tasks: {list}
   ```

   After validation subagents return, the parent handles any flagged issues (delete invalid refactor tasks, re-analyze incomplete tasks). Count total findings and refactor tasks.

7. **Complete:** Spawn a lint subagent (`model: "haiku"`, prompt: `Read ~/.claude/skills/todo/lint-agent.md and execute the lint procedure on .agents/TODO/`). Update `.review-state` counts. Report:

   ```
   Stage 1 Complete
   ────────────────
   Files analyzed: 8
   Findings: 3 Critical, 7 Warning, 12 Suggestion
   Refactor tasks created: 5 (2 P1, 3 P2)
   ```

### Subagent Prompt (Stage 1)

Each subagent receives a short prompt — the full instructions live in `analyze-agent.md`:

```
Read `~/.claude/skills/review/analyze-agent.md` — those are your complete instructions.

Analysis tasks to process:
- .agents/TODO/analyze-{slug1}.md
- .agents/TODO/analyze-{slug2}.md

Review guides (read each before analyzing files that match its extensions/framework):
- ~/.claude/skills/review/guides/typescript.md (for .ts/.tsx files)
- ~/.claude/skills/review/guides/react.md (for .tsx files using React)
```

**Guide delivery:** pass guide *paths*, not content. The subagent reads guides on-demand as it encounters relevant files, rather than loading everything upfront. This keeps the prompt small and lets guides compete less with the instruction file for context attention.

**Guide count in batching:** each batch should require at most 2-3 guides. If a batch would need more (e.g., files spanning 4+ frameworks), split the batch by language/framework instead. This is more important than file count — a batch of 5 small files needing 1 guide is better than 2 files needing 5 guides.

The subagent reads its own instructions, reads the source files, writes findings into the analysis task files, creates refactor tasks, and commits — all autonomously. The parent does NOT rewrite or relay findings.

---

## Stage 2: Refactoring

Executes refactor tasks through the **full `/todo work` protocol**. Every task MUST go through all 4 phases: **plan → execute → verify → complete**. Skipping phases (especially verify and complete) is the most common failure mode — do not allow it.

### Parent Procedure

1. **Discover tasks** — glob `.agents/TODO/refactor-*.md`. Select where tags contain both `review` and `refactor`, and `status` is `pending`. Sort by priority (P1 first), then created date. If none: "No refactoring tasks. Run `/review analyze <path>` first."

2. **Execute** — each refactor task owns exactly one file (1:1 ownership). No two tasks touch the same file. This enables safe parallel execution.

   **Parallel:** batch tasks using the Batching Strategy. Spawn `general-purpose` subagents with the `model` parameter from `--model` flag and the prompt below.

   **Serial:** process each task in main context following the same 4-phase protocol.

3. **Validate** — after subagents return, rigorously check each task file:
   - `status: done` in frontmatter
   - ALL 4 required sections present: `## Acceptance Criteria`, `## Verify Plan`, `## Verify Report`, `## Work Report`
   - Every acceptance criterion is `[x]` or `[E]` (none left `[ ]`)
   - Every verify plan item is `[x]`
   - Work report has all 5 subsections
   - If ANY section is missing or incomplete: **re-read the task, identify gaps, fix in parent context**
   - Collect any `archrev-refactor-*` tasks from escalation
   - Spawn a lint subagent (`model: "haiku"`, prompt: `Read ~/.claude/skills/todo/lint-agent.md and execute the lint procedure on .agents/TODO/`)

4. **Report:**

   ```
   Stage 2 Complete
   ────────────────
   Tasks completed: 5/5
   Commits: 5
   Escalated: 2 (→ archrev-refactor-*)
   Failures: 0
   ```

### Subagent Prompt (Stage 2)

Each subagent receives a short prompt — the full instructions live in `refactor-agent.md`:

```
Read `~/.claude/skills/review/refactor-agent.md` — those are your complete instructions.

Refactor tasks to process:
- .agents/TODO/refactor-{slug1}.md
- .agents/TODO/refactor-{slug2}.md
```

The subagent reads its own instructions (including the 4-phase work protocol, verification standards, cross-file escalation, and git discipline), then executes all assigned tasks autonomously.

---

## Batching Strategy

**Target:** ~66% context window usage per subagent (input + reasoning + output).

| Stage | File size | Tasks per subagent |
|-------|-----------|-------------------|
| Stage 1 (analysis) | <200 lines | 3-5 |
| Stage 1 (analysis) | 200-500 lines | 2-3 |
| Stage 1 (analysis) | 500+ lines | 1 |
| Stage 2 (refactoring) | <200 lines | 5-8 |
| Stage 2 (refactoring) | 200-500 lines | 3-5 |
| Stage 2 (refactoring) | 500+ lines | 1-2 |

Add ~500 lines overhead per guide per subagent. If only a few tasks exist, a single subagent handles all.

---

## Guide Management

### Location

`~/.claude/skills/review/guides/{name}.md` — named by language or framework.

### Route: guide-manage

Parse token after `guide`:
- **`list`** — glob `~/.claude/skills/review/guides/*.md`, list with metadata
- **`<name>`** — show if exists, trigger creation if missing

### Guide creation flow

When a review needs a guide that doesn't exist:

1. Detect language from extensions, frameworks from dependency manifests
2. Ask user: **"Create {name} review guide? (Recommended)"** / "Skip for now"
3. If creating:
   a. Generate from agent knowledge of best practices, common pitfalls, security patterns
   b. Cross-reference: OWASP for security, ecosystem linters (eslint, clippy, pylint), official style guides, framework docs
   c. Write to `~/.claude/skills/review/guides/{name}.md`
   d. Present to user for review before first use
4. If skipped: proceed without guide, note in output

### Guide layering

Multiple guides apply simultaneously. A React + TypeScript file needs both `typescript.md` and `react.md`. An Express route handler needs `typescript.md` and `express.md`.

**Guides are supplementary, not primary.** Rely first on your own knowledge. Guides add ecosystem-specific precision.

---

## State Files

### `.agents/TODO/.review-state` (gitignored)

Created when a multi-stage review starts. Checked on every `/review` invocation to enable resume. Deleted when review completes.

```yaml
stage: 1                        # 1 (analysis) or 2 (refactoring)
source: path                    # "path" or "changed"
git-range: abc123..HEAD         # only when source: changed
path: src/lib/
mode: parallel                  # or serial
started: 2026-02-20T14:30:00Z
analyze-total: 12
analyze-done: 7
refactor-total: 0
refactor-done: 0
```

### `.agents/TODO/.review-last-commit` (gitignored)

Written when a `/review changed` completes. Read on next `/review changed` (no args) to determine base commit. Contains HEAD at review **start**, not completion.

```yaml
commit: abc123def456789...
date: 2026-02-21T12:23:00Z
files-reviewed: 12
findings: 3 Critical, 7 Warning
```

If this file doesn't exist, `/review changed` defaults to `HEAD~1`.

---

## Git Discipline

- **Stage 1:** Task tracking commits only (`[todo]` prefix). Zero code changes.
- **Stage 2:** Code commits (source only, concise *why*) + task tracking commits (`.agents/TODO/` only, `[todo]` prefix). Never mix.

---

## Slug Conventions

- Analysis: `analyze-{file-slug}` (e.g., `analyze-src-lib-api-client`)
- Refactoring: `refactor-{file-slug}` (e.g., `refactor-src-lib-api-client`)
- File slug: strip extension, replace `/` and `.` with `-`, collapse dashes

---

## Appendix: Cross-File Escalation

Stage 2 subagents have the full escalation protocol in `refactor-agent.md`. For the parent's validation purposes: escalated findings are marked `[E]` in acceptance criteria and generate `archrev-refactor-*` tasks tagged `[architecture-review, refactor]`. Collect these during Stage 2 validation.
