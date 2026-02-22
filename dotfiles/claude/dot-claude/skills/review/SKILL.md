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

   Run `/todo lint` after creating all tasks.

5. **Spawn subagents** (parallel mode) or process inline (serial mode):

   **Parallel:** batch analysis tasks using the Batching Strategy. For each batch, spawn a `general-purpose` subagent with the `model` parameter from `--model` flag and the prompt below.

   **Serial:** process each task in main context using the same procedure as the subagent prompt.

6. **Validate subagent output:**
   a. Read each analysis task file. Confirm `status: done` and `## Findings` section has actual content.
   b. Confirm all acceptance criteria are `[x]`.
   c. **Cross-check refactor tasks against analysis**: for each refactor task, verify its findings appear verbatim in the corresponding analysis task. If a refactor task contains findings not present in the analysis, delete the refactor task and recreate it from the actual analysis findings (or delete it entirely if the analysis has no Critical/Warning findings for that file).
   d. **Spot-check evidence**: for 1-2 files per batch, re-read the source file and verify a Critical/Warning finding's `Evidence:` snippet matches. Flag fabricated evidence.
   e. Handle any incomplete tasks in parent context.
   f. Count total findings and refactor tasks.

7. **Complete:** Run `/todo lint`. Update `.review-state` counts. Report:

   ```
   Stage 1 Complete
   ────────────────
   Files analyzed: 8
   Findings: 3 Critical, 7 Warning, 12 Suggestion
   Refactor tasks created: 5 (2 P1, 3 P2)
   ```

### Subagent Prompt Template (Stage 1)

This is the full prompt passed to each Stage 1 subagent:

> **WRITE RESTRICTION:** You may ONLY create or modify files under `.agents/TODO/`. Do NOT modify any project source files. This is read-only analysis.
>
> You are performing Stage 1 code review analysis. For each analysis task assigned to you:
>
> 1. **Read** the analysis task file to get target files from `## Key Files`
> 2. **Read** each target file completely
> 3. **Analyze** using the review guide (below) and your own knowledge
> 4. **Write findings** into the analysis task file — replace `## Findings` placeholder using the format below
> 5. **Check off all acceptance criteria** (`- [ ]` → `- [x]`)
> 6. **Create refactor tasks** — ONLY for files that have Critical or Warning findings **in the ## Findings section you wrote in step 4**. One refactor task per file. Files with only Suggestions/Nits get NO refactor task.
>    - The refactor task's `## Findings to Address` section MUST be a verbatim copy of the Critical and Warning entries you wrote in step 4 for that file. Do NOT re-analyze, do NOT generate new findings, do NOT read archived tasks. This is a mechanical copy operation.
>    - If a file has no Critical or Warning findings in your step 4 output, do NOT create a refactor task for it.
> 7. **Mark done** — set frontmatter `status: done` and `updated: {today}`
>
> **Severity levels:**
> - **Critical** — Security vulnerabilities, data loss, correctness bugs → P1 refactor task
> - **Warning** — Performance, error handling, code quality → P2 refactor task
> - **Suggestion** — Worth noting, documented only
> - **Nit** — Trivial, documented only
>
> **Categories:** Security, Correctness, Performance, Error Handling, Code Quality, Style, Single-File Design, Comment Hygiene. Not exhaustive — flag anything within single-file scope.
>
> **Guides are supplementary.** Use them for ecosystem-specific precision. Rely first on your own judgment.
>
> **Evidence must be verbatim.** Every `Evidence:` snippet MUST be copied exactly from the file as returned by the Read tool. Re-read the line range if unsure.
>
> **Do NOT read `.agents/TODO/archive/`** or any previously-created task files. Your findings must come exclusively from reading the current source files. Prior review rounds are irrelevant.
>
> **Findings format** (written into the analysis task file):
> ```markdown
> ## Findings
>
> ### {file-path}
>
> #### Critical
> 1. **[Category]** L{line}: Description
>    - Evidence: `code snippet`
>    - Fix: Description of fix
>
> #### Warning
> 1. **[Category]** L{line}: Description
>    - Evidence: `code snippet`
>    - Fix: Description of fix
>
> #### Suggestion
> 1. **[Category]** L{line}: Description
>    - Fix: Description of fix
> ```
> Omit empty severity sections. If a file has no findings: `### {path}` with "No findings."
>
> **Refactor task template** — create `.agents/TODO/refactor-{file-slug}.md`:
> ```yaml
> ---
> slug: refactor-{file-slug}
> title: "Refactor {path} — {N} findings"
> priority: P1  # P1 if any Critical; P2 if only Warnings
> status: pending
> created: {today}
> updated: {today}
> depends-on: []
> tags: [review, refactor]
> ---
>
> # Refactor {path} — {N} findings
>
> ## Context
> Code review found {N} actionable issues in {path}. Apply all fixes below.
>
> ## Key Files
> - `{path}` — Target file to refactor
>
> ## Findings to Address
> {VERBATIM COPY of Critical and Warning findings for this file from the ## Findings section of the analysis task. No additions, no rewording, no new findings.}
>
> ## Acceptance Criteria
> - [ ] Fix: {finding 1 short description}
> - [ ] Fix: {finding 2 short description}
> - [ ] All changes stay within {path} — if cross-file changes needed, mark `[E]` and follow Cross-File Escalation Protocol
> - [ ] File still compiles/passes linting after changes
> ```
>
> Analysis tasks to process: {list of .agents/TODO/analyze-*.md file paths}
> Review guide: {guide content}

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
   - Run `/todo lint`

4. **Report:**

   ```
   Stage 2 Complete
   ────────────────
   Tasks completed: 5/5
   Commits: 5
   Escalated: 2 (→ archrev-refactor-*)
   Failures: 0
   ```

### Subagent Prompt Template (Stage 2)

> You are performing Stage 2 code review refactoring. **You MUST follow the `/todo work` 4-phase protocol for every task.** No phase may be skipped.
>
> **Before starting, read these files:**
> - `~/.claude/skills/todo/SKILL.md` — read the full **Sub-command: work** section (the 4-phase procedure), **Sub-command: verify** (verify plan and report format), **Work Report Section** (the 5 required subsections), and **Git Commit Discipline** (commit stream separation)
> - `~/.claude/skills/review/SKILL.md` — read the **Appendix: Cross-File Escalation** section
> - The project's `CLAUDE.md` if it exists — coding conventions and verification standards
>
> **The 4 phases — ALL are mandatory, in order:**
>
> ### Phase 1: Plan
> - Read the task file completely (frontmatter, context, key files, findings, acceptance criteria)
> - Read the target source file completely
> - Plan the refactoring approach for each finding
> - Understand what verification will be needed (plan this now, execute in phase 3)
>
> ### Phase 2: Execute
> - Apply the fixes described in `## Findings to Address`
> - **Check off each acceptance criterion** as you complete it: `- [ ]` → `- [x]`
> - If a finding requires cross-file changes: mark `[E]` and follow Cross-File Escalation Protocol instead
> - Commit after each logical unit of work — code-only commits, concise messages explaining *why*
> - Every criterion must end as `[x]` or `[E]`, never left as `[ ]`
>
> ### Phase 3: Verify (DO NOT SKIP)
> - Append `## Verify Plan` to the task file with checkbox items for each verification step
> - At minimum, EVERY refactor task MUST include: `- [ ] tsc --noEmit passes` (for TypeScript) or equivalent compile check
> - For UI changes: Playwright navigation + snapshot + screenshot
> - For API changes: curl the endpoint
> - Execute each verification step. Check off items as they pass: `- [ ]` → `- [x]`
> - Append `## Verify Report` summarizing results with concrete evidence (command output, screenshot paths, etc.)
>
> ### Phase 4: Complete (DO NOT SKIP)
> - Append `## Work Report` with ALL 5 subsections:
>   1. **What was done** — summary of changes
>   2. **How** — approach taken
>   3. **Decisions** — choices made and why
>   4. **Files changed** — list of modified files
>   5. **Follow-up** — anything remaining (or "None")
> - If any findings were escalated, also include a `### Escalated` subsection
> - Set frontmatter `status: done` and `updated: {today}`
> - Make a task tracking commit: stage only `.agents/TODO/` files, prefix message with `[todo]`
> - Do NOT move task files to `done/` or run `/todo lint` — the parent handles that
>
> **Completed task file MUST contain all of these sections:**
> - `## Acceptance Criteria` — every item `[x]` or `[E]`
> - `## Verify Plan` — every item `[x]`
> - `## Verify Report` — with evidence
> - `## Work Report` — with all 5 subsections
>
> **Git discipline:** Two separate commit streams. Code commits = source files only, concise *why* messages. Task tracking commits = `.agents/TODO/` files only, `[todo]` prefix. Never mix code and task tracking in one commit.
>
> Tasks to process: {list of .agents/TODO/refactor-*.md file paths}

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

## Appendix: Cross-File Escalation Protocol

This is a contingency for Stage 2 only. Agents should NOT proactively look for cross-file concerns (that's `/architecture-review`'s scope). Use when a finding that appeared single-file-scoped actually requires cross-file changes.

1. **Do not make cross-file changes.** Leave the finding unaddressed.

2. **Mark the criterion as escalated** — `[E]` instead of `[x]`:
   ```markdown
   - [E] Fix: dead code in parseConfig → Escalated to archrev-refactor-consolidate-config-parsers
   ```

3. **Document in Work Report** under `### Escalated`:
   ```markdown
   ### Escalated
   - **[Category]** L{line}: {description}
     - Reason: {why cross-file changes needed}
     - Files affected: `file1.ts`, `file2.ts`
     - Escalated to: `archrev-refactor-{slug}`
   ```

4. **Create an `archrev-refactor-*` task:**
   ```yaml
   ---
   slug: archrev-refactor-{descriptive-slug}
   title: "{Category}: {description}"
   priority: P1  # match original finding severity
   status: pending
   created: YYYY-MM-DD
   updated: YYYY-MM-DD
   depends-on: []
   tags: [architecture-review, refactor]
   ---

   # {title}

   ## Context
   Escalated from code review of `{original-file}`. Requires cross-file changes.

   ## Origin
   - Review task: `refactor-{file-slug}`
   - Original finding: **[{Category}]** L{line}: {description}

   ## Key Files
   - `{file1}` — {what needs to change}
   - `{file2}` — {what needs to change}

   ## Findings
   ### {Severity}
   1. **[{Category}]** {description}
      - Evidence: {code snippet}
      - Fix: {cross-file refactoring approach}

   ## Acceptance Criteria
   - [ ] {criterion per file/change}
   - [ ] All files compile after changes
   ```

   The `[architecture-review, refactor]` tags let `/architecture-review refactor` discover these tasks.
