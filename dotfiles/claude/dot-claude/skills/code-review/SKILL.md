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

## Flags

| Flag | Default | Effect |
|------|---------|--------|
| `--serial` | off | Sequential subagent execution instead of parallel |
| `--model` | `sonnet` | Model for subagent `Task` calls (`haiku`, `sonnet`, `opus`) |

## Resume Check

If `.agents/TODO/.review-state` exists: read it, inform user "Resuming review of {path} (stage {stage})", resume from saved stage. Do NOT start fresh.

## Routing

| First token | Route |
|-------------|-------|
| `analyze` | Stage 1 only (remaining args = path/glob) |
| `refactor` | Stage 2 only (picks up pending refactor-* tasks) |
| `changed` | Review files changed in git history |
| `guide` | Guide management (see below) |
| `status` | Show review-tagged tasks from `.agents/TODO/` |
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

## Stage 1: Analysis (Read-Only)

Zero code modifications. Subagents create task files and write findings.

### Parent Procedure

1. **Resolve files** — expand path/glob. Filter out non-code files, generated dirs (`node_modules/`, `dist/`, `.git/`), files under 5 lines. Cap at 20 analysis tasks total; warn if exceeded.

2. **Deduplicate** — glob `.agents/TODO/analyze-*.md` and `.agents/TODO/refactor-*.md` filenames. Skip files whose slug already exists. Do NOT read INDEX.md.

3. **Detect guides** — check file extensions and dependency manifests. Build a list of guide paths from `~/.claude/skills/code-review/guides/`. If a needed guide doesn't exist, ask user to create or skip. Each batch should need at most 2-3 guides; split by language/framework if more.

4. **Batch and spawn subagents** — group files by size and guide affinity:

   | File size | Files per subagent |
   |-----------|-------------------|
   | <200 lines | 3-5 |
   | 200-500 lines | 2-3 |
   | 500+ lines | 1 |

   Each subagent `Task` call uses `subagent_type: "general-purpose"`, the `model` parameter, and this prompt:

   ```
   Read `~/.claude/skills/code-review/analyze-agent.md` — those are your complete instructions.

   Files to analyze:
   - {path1}
   - {path2}

   Review guides (read before analyzing matching files):
   - ~/.claude/skills/code-review/guides/{guide1}.md
   - ~/.claude/skills/code-review/guides/{guide2}.md
   ```

   Subagents create analyze-*.md files, write findings, commit, and return one-line summaries. They do NOT create refactor tasks.

5. **Validate and create refactor tasks** — wait for ALL analysis subagents to complete. Spawn validation subagents (using the `model` parameter, NOT haiku):

   ```
   Read `~/.claude/skills/code-review/validate-agent.md` — those are your complete instructions.

   Analysis tasks to validate:
   - .agents/TODO/analyze-{slug1}.md
   - .agents/TODO/analyze-{slug2}.md
   ```

   Validation subagents verify findings against source code, delete fabricated findings, and create refactor tasks for validated Critical/Warning findings. Parent handles any flagged issues from the validation summary.

6. **Aggregate counts** — collect pre/post validation counts from all validation subagent return summaries. Sum across subagents for the totals.

7. **Lint and report** — spawn haiku subagent: `Read ~/.claude/skills/todo/lint-agent.md and execute the lint procedure on .agents/TODO/`. Then report:

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

   List every refactor task with its priority and finding counts so the user can audit before running Stage 2.

---

## Stage 2: Refactoring

Subagents execute refactor tasks through the full 4-phase work protocol (plan → execute → verify → complete).

### Parent Procedure

1. **Discover tasks** — glob `.agents/TODO/refactor-*.md`. Read frontmatter only (status + priority + tags). Select where tags contain `review` and `refactor`, status is `pending`. Sort by priority (P1 first), then created date. If none found: "No refactoring tasks."

2. **Batch and spawn subagents** — group by file size:

   | File size | Tasks per subagent |
   |-----------|-------------------|
   | <200 lines | 5-8 |
   | 200-500 lines | 3-5 |
   | 500+ lines | 1-2 |

   Each subagent `Task` call uses `subagent_type: "general-purpose"`, the `model` parameter, and this prompt:

   ```
   Read `~/.claude/skills/code-review/refactor-agent.md` — those are your complete instructions.

   Refactor tasks to process:
   - .agents/TODO/refactor-{slug1}.md
   - .agents/TODO/refactor-{slug2}.md
   ```

3. **Validate** — after subagents return, check each task file:
   - `status: done` in frontmatter
   - ALL 4 sections present: `## Acceptance Criteria`, `## Verify Plan`, `## Verify Report`, `## Work Report`
   - All criteria `[x]` or `[E]` (none `[ ]`)
   - If incomplete: re-read task, identify gaps, fix in parent context
   - Collect `archrev-refactor-*` escalation tasks

4. **Lint and report** — spawn haiku subagent for lint. Then report:

   ```
   Stage 2 Complete — Tasks: {done}/{total}, Commits: {N}, Escalated: {N}, Failures: {N}
   ```

---

## Guide Management

Guides live at `~/.claude/skills/code-review/guides/{name}.md` (language or framework). Multiple guides apply simultaneously (e.g., TypeScript + React for `.tsx`).

- `guide list` — glob guides, show metadata
- `guide <name>` — show if exists; if missing, ask user to create (generate from agent knowledge + OWASP/linter/style guide cross-reference) or skip

---

## State Files (gitignored)

**`.agents/TODO/.review-state`** — created at review start, deleted on completion:
```yaml
stage: 1
source: path          # or "changed"
path: src/lib/
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

- **Stage 1:** Task tracking commits only (`[todo]` prefix). Zero code changes.
- **Stage 2:** Code commits (source only) + task tracking commits (`.agents/TODO/` only, `[todo]` prefix). Never mix.
