---
name: review
description: Code review — analyze files for issues, create refactoring tasks, execute fixes
user-invocable: true
disable-model-invocation: true
arguments: $ARGUMENTS
---

# /review — Code Review Skill

Single-file-scope code review: analyze files read-only (Stage 1), then refactor via `/todo work` protocol (Stage 2). Every finding must be completable within one file. Cross-file concerns discovered during refactoring are escalated to `/architecture-review` via the Cross-File Escalation Protocol.

**Integration:** Uses `.agents/TODO/` for all task tracking. Creates tasks and delegates execution to the `/todo` work protocol.

**State:** `.agents/TODO/.review-state` tracks multi-stage progress across context compactions.

---

## Review Categories (Single-File Scope)

These categories are the primary focus, but **not exhaustive**. Flag any issue you discover within single-file scope, even if it doesn't fit neatly into a listed category.

| Category | Description |
|----------|-------------|
| Security | Injection, auth bypass, crypto misuse, data exposure |
| Correctness | Logic errors, off-by-one, null handling, edge cases |
| Performance | Unnecessary allocations, algorithmic complexity, hot-path inefficiency |
| Error Handling | Missing error paths, swallowed exceptions, fail-open patterns |
| Code Quality | Complexity, naming, dead code, magic numbers, duplication |
| Style | Language-specific idioms, conventions, formatting |
| Single-File Design | SRP violations, god functions, excessive responsibilities |
| Comment Hygiene | Stale comments, resolved TODOs, misleading descriptions |

**Other concerns you may discover** (examples, not exhaustive):
- Authentication/authorization gaps within a file (missing checks, inconsistent validation)
- Resource management (unclosed handles, missing cleanup, leak-prone patterns)
- Concurrency issues (race conditions, missing locks, unsafe shared state)
- Accessibility problems in UI components

When flagging issues outside the listed categories, use a descriptive category name in the finding (e.g., `**[Resource Management]**`, `**[Accessibility]**`).

**Excluded:** Dependency inversion across modules, component coupling, test coverage requiring new files, architectural concerns spanning multiple files. See `/architecture-review` for cross-file concerns.

**Severity levels:**
- **Critical** — Security vulnerabilities, data loss risks, correctness bugs. Creates P1 refactor task.
- **Warning** — Performance issues, error handling gaps, code quality problems. Creates P2 refactor task.
- **Suggestion** — Improvements worth noting. Documented in findings only, no refactor task.
- **Nit** — Trivial style preferences. Documented only.

---

## Resume Check (ALWAYS DO THIS FIRST)

Before routing, check if `.agents/TODO/.review-state` exists. If it does:

1. Read the file to get the current review state
2. Inform the user:
   - If `source: changed` → "Resuming review of changed files ({git-range}, stage {stage}, {mode} mode)"
   - Otherwise → "Resuming review of {path} (stage {stage}, {mode} mode)"
3. Resume based on state:
   - If `stage: 1` → count remaining `analyze-*` tasks with `status: pending`, continue Stage 1
   - If `stage: 2` → count remaining `refactor-*` tasks with `status: pending`, continue Stage 2
4. Do NOT start fresh — continue from saved state

---

## Routing

Parse `$ARGUMENTS` to determine the route:

| First token | Route | Description |
|-------------|-------|-------------|
| `analyze` | **stage1** | Analysis only (remaining args = path/glob) |
| `refactor` | **stage2** | Refactoring only (picks up existing refactor-* tasks) |
| `changed` | **changed-files** | Review files changed in git history |
| `guide` | **guide-manage** | Show, create, or list review guides |
| `status` | **review-status** | Show review-tagged tasks from INDEX.md |
| path or glob | **full** | Both stages sequentially |
| *(empty)* | **help** | Usage summary |

**Flags (anywhere in args):**
- `--serial` — Process tasks sequentially in main context instead of parallel via subagents

---

## Route: help (no args)

Display usage summary:

```
/review <path>                      Both stages (analyze + refactor)
/review <path> --serial             Both stages, serial mode
/review analyze <path>              Stage 1 only — analysis
/review refactor                    Stage 2 only — execute pending refactor tasks
/review changed                     Since last reviewed commit
/review changed <N>                 Files changed in last N commits
/review changed <hash>              Files changed since commit
/review changed --since <date>      Files changed since date
/review changed --analyze           Stage 1 only
/review guide <name>                Show/create review guide (language or framework)
/review guide list                  List available guides
/review status                      Show review-tagged tasks
```

---

## Route: review-status

1. Glob `.agents/TODO/analyze-*.md` and `.agents/TODO/refactor-*.md`
2. Parse frontmatter from each file
3. Display grouped by type (analyze vs refactor) and status:

```
Review Tasks
────────────
Analyze (3 pending, 2 done)
  [ ] analyze-src-lib-api-client — Analyze src/lib/api-client.ts
  [ ] analyze-src-lib-auth       — Analyze src/lib/auth.ts
  [ ] analyze-src-utils-format   — Analyze src/utils/format.ts
  [x] analyze-src-lib-db         — Analyze src/lib/db.ts
  [x] analyze-src-lib-config     — Analyze src/lib/config.ts

Refactor (1 pending, 1 done)
  [ ] refactor-src-lib-api-client — Refactor src/lib/api-client.ts (P1)
  [x] refactor-src-lib-db         — Refactor src/lib/db.ts (P2)
```

---

## Route: changed-files

Review files changed in git history. Resolves files from git instead of glob-expanding a path, then feeds them into the same Stage 1/Stage 2 pipeline.

### Argument parsing

Parse tokens after `changed`:

| Pattern | Detection | Git command |
|---------|-----------|-------------|
| *(empty)* | No positional arg | Read `.agents/TODO/.review-last-commit` for base commit. If file doesn't exist, default to `HEAD~1` and inform user: "No previous review found, reviewing changes in last commit." |
| Pure digits (e.g. `5`) | Regex `^\d+$` | `git diff --name-only --diff-filter=ACMR HEAD~{N}..HEAD` |
| 7-40 hex chars (e.g. `abc123`) | Regex `^[0-9a-f]{7,40}$` | `git diff --name-only --diff-filter=ACMR {hash}..HEAD` |
| `--since <date>` | Flag detection | `git log --since="{date}" --name-only --pretty=format: --diff-filter=ACMR \| sort -u` |

**Flags:**
- `--analyze` — Stage 1 only (skip Stage 2). Default is full both stages.
- `--serial` — Serial mode (existing flag).

### File resolution

1. Run the appropriate git command to get a list of changed files
2. If no files returned, inform user: "No changed files found in the specified range." and exit
3. Apply the same filters as Stage 1 file resolution:
   - Exclude non-code files, generated directories, files under 5 lines
   - Detect languages/frameworks, load guides
4. Deduplicate against existing `analyze-*`/`refactor-*` tasks in INDEX.md
5. Group into batches, cap at 20 analysis tasks

### Execution

1. Record `HEAD` commit hash at start (before any work begins)
2. Create `.agents/TODO/.review-state`:
   ```yaml
   stage: 1
   source: changed
   git-range: <base>..HEAD
   path: (changed files)
   mode: parallel  # or serial if --serial
   started: <ISO timestamp>
   analyze-total: 0
   analyze-done: 0
   refactor-total: 0
   refactor-done: 0
   ```
3. Execute Stage 1 with the resolved file list (same procedure as the existing Stage 1)
4. If `--analyze` flag: skip Stage 2, write `.review-last-commit`, delete `.review-state`, report summary
5. Otherwise: update state to `stage: 2`, execute Stage 2, then write `.review-last-commit`, delete `.review-state`, report summary

### State tracking: `.review-last-commit`

Written to `.agents/TODO/.review-last-commit` when a `changed` review completes. This file is gitignored.

```yaml
commit: <full HEAD hash recorded at start of review>
date: <ISO timestamp of completion>
files-reviewed: <count>
findings: <summary, e.g. "3 Critical, 7 Warning">
```

**Lifecycle:**
- Read at start of `/review changed` (no args) to determine base commit
- Written when the review completes (after Stage 1 if `--analyze`, after Stage 2 if full)
- Contains HEAD at time of review **start**, not completion — so concurrent changes aren't missed
- If file doesn't exist, `/review changed` defaults to `HEAD~1`

---

## Route: full (path provided, no subcommand)

Run Stage 1 then Stage 2 sequentially.

1. Parse path/glob and `--serial` flag from `$ARGUMENTS`
2. Create `.agents/TODO/.review-state`:
   ```yaml
   stage: 1
   source: path
   path: <path>
   mode: parallel  # or serial if --serial flag
   started: <ISO timestamp>
   analyze-total: 0
   analyze-done: 0
   refactor-total: 0
   refactor-done: 0
   ```
3. Execute Stage 1 (see below)
4. Update state: `stage: 2`, set `analyze-done` count, set `refactor-total` count
5. Execute Stage 2 (see below)
6. Delete `.agents/TODO/.review-state`
7. Report summary

---

## Stage 1: Analysis (Read-Only)

Zero code modifications. Creates TODO tasks with findings.

### Procedure

1. **Resolve target files** — expand path/glob. Filter out:
   - Non-code files: images, lockfiles (`package-lock.json`, `pnpm-lock.yaml`), binary files
   - Generated directories: `node_modules/`, `dist/`, `.git/`, `build/`, `coverage/`
   - Files under 5 lines (likely config stubs)

   Group small related files (same directory, similar purpose) into batches of up to 5 files per analysis task. Cap at 20 analysis tasks total; warn the user if file count would exceed this.

2. **Detect languages and frameworks, load guides** — multiple guides may apply to any given file. Load all that are relevant and pass them as context.

   **Language detection** — map file extensions to language keys:

   | Extensions | Language key |
   |-----------|-------------|
   | `.ts`, `.tsx`, `.js`, `.jsx`, `.mjs`, `.cjs` | typescript |
   | `.py`, `.pyi` | python |
   | `.rs` | rust |
   | `.go` | go |
   | `.java`, `.kt`, `.kts` | java |
   | `.rb` | ruby |
   | `.c`, `.cpp`, `.h`, `.hpp` | cpp |
   | `.cs` | csharp |
   | `.swift` | swift |
   | `.sh`, `.bash`, `.zsh` | shell |

   **Framework detection** — check project indicators to identify major frameworks:

   | Indicator | Framework key |
   |-----------|--------------|
   | `react`, `react-dom` in dependencies; `.tsx`/`.jsx` files | react |
   | `next` in dependencies; `next.config.*` | nextjs |
   | `express` in dependencies | express |
   | `fastify` in dependencies | fastify |
   | `vue` in dependencies; `.vue` files | vue |
   | `@angular/core` in dependencies | angular |
   | `svelte` in dependencies; `.svelte` files | svelte |
   | `django` in requirements; `settings.py` | django |
   | `flask` in requirements | flask |
   | `fastapi` in requirements | fastapi |
   | `axum`, `actix-web`, `rocket` in Cargo.toml | (respective name) |

   This table is not exhaustive — detect any major framework you recognize from config files, dependency manifests, or import patterns.

   **Guide layering** — for each file, determine which guides apply. A React + TypeScript file needs both `typescript.md` and `react.md`. An Express route handler needs `typescript.md` and `express.md`. Load all applicable guides from `~/.claude/skills/review/guides/{name}.md`.

   **Guides are supplementary, not primary.** Rely first on your own knowledge and judgment about code quality, security, performance, and best practices. Guides add ecosystem-specific precision — they don't define the boundaries of what you look for.

   For each detected language/framework: check if a guide exists. If missing, trigger guide creation flow (see Guide Management section). Multiple guides may be created in one session if the codebase uses multiple frameworks.

3. **Deduplicate** — read `.agents/TODO/INDEX.md`. If `analyze-{file-slug}` or `refactor-{file-slug}` tasks already exist for any target file, skip that file and inform the user.

4. **Create analysis tasks** — for each file or batch, write `.agents/TODO/analyze-{file-slug}.md`:

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
   and document findings by severity. Guides are supplementary — also rely on your own
   knowledge to flag any issue you discover.

   ## Key Files
   - `{path}` — Target file for analysis
   - `~/.claude/skills/review/guides/{language}.md` — Language review guide
   - `~/.claude/skills/review/guides/{framework}.md` — Framework review guide (if applicable)

   ## Acceptance Criteria
   - [ ] Read target file completely
   - [ ] Apply recommended categories: Security, Correctness, Performance, Error Handling, Code Quality, Style, Single-File Design, Comment Hygiene
   - [ ] Also flag any other issues discovered (categories are recommended, not exhaustive)
   - [ ] Document all findings in the Findings section below with severity, category, line numbers, evidence, and fix description
   - [ ] Only flag issues completable within this single file
   ```

   Run `/todo lint` after creating all analysis tasks.

5. **Execute analysis:**

   **Parallel (default):** Use the batching strategy to group analysis tasks. For each batch, spawn an Explore subagent with this prompt:

   > Analyze these files for code quality issues. For each file, read it completely, then apply all provided review guides and your own knowledge to identify findings.
   >
   > **Recommended categories:** Security, Correctness, Performance, Error Handling, Code Quality, Style, Single-File Design, Comment Hygiene. These are not exhaustive — also flag any other issues you discover within single-file scope. Use descriptive category names for findings outside the standard list.
   >
   > **Guides are supplementary.** Use them for ecosystem-specific precision, but rely first on your own judgment. If a guide doesn't cover something you know is a problem, flag it anyway.
   >
   > Return findings in this exact format per file:
   > ```
   > FILE: {path}
   > ### Critical
   > 1. **[Category]** L{line}: Description
   >    - Evidence: `code snippet`
   >    - Fix: Description of fix
   > ### Warning
   > 1. **[Category]** L{line}: Description
   >    - Fix: Description of fix
   > ### Suggestion
   > 1. **[Category]** L{line}: Description
   >    - Fix: Description of fix
   > ```
   >
   > Files to analyze: {list}
   > Language guide: {language guide content, or "none"}
   > Framework guide: {framework guide content, or "none"}

   Include ALL applicable guides in the subagent prompt. A React + TypeScript file gets both the typescript and react guide content. Each subagent batch should include guides relevant to the files in that batch.

   After subagents return, the parent agent writes findings into each analysis task file's `## Findings` section and creates refactor tasks.

   **Serial:** Process each analysis task in the main context. Read each target file, apply all applicable guides and your own knowledge, write findings directly.

6. **Create refactor tasks from findings — one per file:**

   Each analyzed file with Critical or Warning findings gets exactly **one** refactor task. This enforces the 1:1 file-to-refactor-task mapping needed for safe parallel execution in Stage 2.

   ```yaml
   ---
   slug: refactor-{file-slug}
   title: "Refactor {path} — {N} findings"
   priority: P1  # if any Critical findings; P2 if only Warnings
   status: pending
   created: YYYY-MM-DD
   updated: YYYY-MM-DD
   depends-on: []
   tags: [review, refactor]
   ---

   # Refactor {path} — {N} findings

   ## Context
   Code review found {N} actionable issues in {path}. Apply all fixes below.
   Findings are listed in severity order (Critical first, then Warning).

   ## Key Files
   - `{path}` — Target file to refactor

   ## Findings to Address

   ### Critical
   1. **[Category]** L{line}: Description
      - Evidence: `code snippet`
      - Fix: Description of fix

   ### Warning
   1. **[Category]** L{line}: Description
      - Fix: Description of fix

   ## Acceptance Criteria
   - [ ] Fix: {Critical finding 1 short description}
   - [ ] Fix: {Warning finding 1 short description}
   - [ ] All changes stay within {path} — if a fix requires cross-file changes, mark as `[E]` and follow Cross-File Escalation Protocol
   - [ ] File still compiles/passes linting after changes
   ```

   Files with only Suggestions or Nits get NO refactor task — findings are documented in the analysis task only.

7. **Complete:** Mark all analysis tasks as done (set `status: done`, `updated` to today). Run `/todo lint`. Update `.review-state` counts. Report summary:

   ```
   Stage 1 Complete
   ────────────────
   Files analyzed: 8
   Findings: 3 Critical, 7 Warning, 12 Suggestion
   Refactor tasks created: 5 (2 P1, 3 P2)
   ```

### Findings Format (written into analyze task body)

```markdown
## Findings

### Critical
1. **[Security]** L42: SQL injection via string concatenation
   - Evidence: `db.query(\`SELECT * FROM ${input}\`)`
   - Fix: Use parameterized query

### Warning
1. **[Performance]** L88-95: N+1 query in loop
   - Fix: Batch query outside loop
2. **[Error Handling]** L120: Swallowed exception in catch block
   - Fix: Log error and rethrow or handle explicitly

### Suggestion
1. **[Code Quality]** L12: Magic number 86400
   - Fix: Extract to named constant `SECONDS_PER_DAY`

### Nit
1. **[Style]** L5: Inconsistent import ordering
   - Fix: Group imports by external/internal
```

---

## Stage 2: Refactoring

Executes refactor tasks through the full `/todo work` protocol (plan, execute, verify, complete).

**Task Isolation:** Stage 2 does NOT use `/todo work` directly (which picks any pending task). Instead it filters by tag to only touch review-created tasks.

### Procedure

1. **Discover tasks** — glob `.agents/TODO/refactor-*.md`. Parse frontmatter. Select tasks where:
   - `tags` contains BOTH `review` AND `refactor`
   - `status` is `pending`

   Sort by priority (P1 first) then created date (oldest first). If none found, report: "No refactoring tasks. Run `/review analyze <path>` first."

2. **File ownership is 1:1** — each refactor task owns exactly one target file (from its Key Files section). No two refactor tasks from the same review session touch the same file. This is the deconfliction mechanism for parallel execution.

3. **Execute** — the execution protocol is identical for serial and parallel modes. The only difference is where it runs (main context vs subagent).

   **Execution protocol (per task):**

   **Step 0 — before any work, read these files:**
   - `~/.claude/skills/todo/SKILL.md` — the work protocol. Read the sections: **Sub-command: work** (4-phase procedure), **Sub-command: verify** (verify plan/report), **Work Report Section** (5-subsection format), and **Git Commit Discipline** (commit stream separation). These define how you plan, execute, verify, report, and commit.
   - `~/.claude/skills/review/SKILL.md` — this file. Read the **Cross-File Escalation Protocol** section under Stage 2. This defines what to do if a finding turns out to require cross-file changes.
   - The project's `CLAUDE.md` if one exists — coding conventions and verification standards.

   Then follow the todo skill's 4-phase work protocol with these review-specific additions:

   a. **Plan:** Read the task file. Read the target file. Plan the refactoring approach for each finding.

   b. **Execute:** Apply the fixes. Commit after each logical unit of work (code-only commits, concise messages explaining *why*). If a finding requires cross-file changes, follow the Cross-File Escalation Protocol instead of making the change.

   c. **Verify:** Follow the todo skill's verify procedure exactly — generate `## Verify Plan`, execute each item with file-type-specific checks (Playwright for UI, curl for API, tsc for TypeScript, etc.), append `## Verify Report` with evidence.

   d. **Complete:** Follow the todo skill's complete procedure exactly — append `## Work Report` with all 5 subsections. If any findings were escalated, also include a `### Escalated` subsection (see Cross-File Escalation Protocol). Set `status: done`, run lint, task tracking commit.

   **Serial mode:** Execute each task in the main context sequentially.

   **Parallel mode:** Batch tasks across general-purpose subagents (see Batching Strategy). Each subagent receives a list of task file paths to process sequentially using the execution protocol above.

   After all subagents return, the parent agent:
   - Reads each task file to confirm `status: done` and that `## Work Report` and `## Verify Report` sections are present
   - Collects any `archrev-refactor-*` tasks created by escalation
   - Runs `/todo lint`
   - Updates `.review-state` counts
   - Reports summary

4. **Complete:** Run `/todo lint`, report summary:

   ```
   Stage 2 Complete
   ────────────────
   Tasks completed: 5/5
   Commits: 5
   Escalated: 2 (→ archrev-refactor-*)
   Failures: 0
   ```

### Cross-File Escalation Protocol

This is a contingency protocol, not a review objective. Agents should NOT proactively look for cross-file concerns — that is `/architecture-review`'s scope. However, during refactoring an agent may discover that a finding — despite appearing single-file-scoped in analysis — actually requires changes across file boundaries to fix properly. When this happens:

1. **Do not make cross-file changes.** The 1:1 file ownership guarantee must be preserved. Leave the finding unaddressed in the target file.

2. **Mark the acceptance criterion as escalated** using `[E]` instead of `[x]` or `[ ]`:

   ```markdown
   - [E] Fix: dead code in parseConfig → Escalated to archrev-refactor-consolidate-config-parsers
   ```

3. **Document in the Work Report** under a `### Escalated` subsection:

   ```markdown
   ### Escalated
   - **[Category]** L{line}: {description}
     - Reason: {why this requires cross-file changes}
     - Files affected: `file1.ts`, `file2.ts`, `file3.ts`
     - Escalated to: `archrev-refactor-{slug}`
   ```

4. **Create an `archrev-refactor-*` task** compatible with the `/architecture-review` refactor stage:

   ```yaml
   ---
   slug: archrev-refactor-{descriptive-slug}
   title: "{Category}: {description}"
   priority: P1  # match original finding severity; P2 for Warning
   status: pending
   created: YYYY-MM-DD
   updated: YYYY-MM-DD
   depends-on: []
   tags: [architecture-review, refactor]
   ---

   # {title}

   ## Context
   Escalated from code review of `{original-file}`. The finding appeared single-file-scoped
   during analysis but requires cross-file changes to fix properly.

   {Why this is an issue, what needs to change across files}

   ## Origin
   - Review task: `refactor-{file-slug}`
   - Original finding: **[{Category}]** L{line}: {description}

   ## Key Files
   - `{file1}` — {what needs to change}
   - `{file2}` — {what needs to change}

   ## Findings
   ### {Severity}
   1. **[{Category}]** {description}
      - Evidence: {code snippet, import chain, etc.}
      - Fix: {specific cross-file refactoring approach}

   ## Acceptance Criteria
   - [ ] {criterion per file/change}
   - [ ] All files compile after changes
   ```

   The `[architecture-review, refactor]` tags ensure `/architecture-review refactor` can discover and execute these tasks. The `## Origin` section provides traceability back to the review that found the issue.

---

## Parallel Execution — Batching Strategy

Subagents are expensive to spawn. Batch multiple tasks per subagent for efficiency.

**Target:** Each subagent should reach ~66% context window usage after completing all its work (input + reasoning + output).

**Stage 1 (Explore subagents):** Estimate per-file context cost: file size + review guide + analysis reasoning + findings output. Batch files so projected total stays under 66% of context.

**Stage 2 (general-purpose subagents):** Estimate per-task cost: file read + plan + code changes + verification + commit + work report. Batch so projected total stays under 66% of context.

**Heuristics:**
- Small files (<200 lines): 5-8 per subagent
- Medium files (200-500 lines): 3-5 per subagent
- Large files (500+ lines): 1-2 per subagent
- Add review guide overhead (~500 lines per guide) once per subagent batch — multiply by number of applicable guides

In both stages: if only a few tasks exist, a single subagent handles all of them. The parallel benefit comes from multiple subagents running concurrently on independent batches.

---

## Guide Management

### Guide location

`~/.claude/skills/review/guides/{name}.md`

Guides are named by language or framework. A project may use `typescript.md`, `react.md`, and `express.md` simultaneously.

### Guide types

- **Language guides** (`typescript.md`, `python.md`, etc.) — language-specific pitfalls, idioms, type system gotchas, standard library misuse
- **Framework guides** (`react.md`, `express.md`, `django.md`, etc.) — framework-specific anti-patterns, lifecycle issues, security patterns, performance traps

### Guide format

```markdown
# {Name} Review Guide

## Metadata
- **Type:** language | framework
- **Extensions:** .ts, .tsx (for language guides)
- **Updated:** YYYY-MM-DD

## Categories

### Security
- Rule with example code

### Correctness
- Rule with example code

### Performance
- Rule with example code

### Error Handling
- Rule with example code

### Code Quality
- Rule with example code

### Style
- Rule with example code

### Comment Hygiene
- Stale comments that no longer match the code
- TODO/FIXME/HACK comments that have been addressed but not removed
- Misleading comments (comment says one thing, code does another)

## Anti-Patterns
| Pattern | Severity | Fix |
|---------|----------|-----|
| Example | Warning | Fix description |
```

Framework guides may omit categories that aren't framework-specific (e.g., Comment Hygiene). Focus on what the framework adds beyond the language guide.

### Route: guide-manage

Parse the second token of `$ARGUMENTS` after `guide`:

- **`list`** — Glob `~/.claude/skills/review/guides/*.md`, list available guides with their metadata (type, extensions, updated date)
- **`<name>`** — If guide exists, display it. If missing, trigger creation flow. Name can be a language (`typescript`) or framework (`react`).

### Guide creation flow

When a review needs a guide that doesn't exist:

1. Detect language from file extensions and frameworks from dependency manifests/config files
2. Ask user: **"Create {name} review guide? (Recommended)"** / "Skip for now"
3. If user chooses to create:
   a. Generate the guide from agent knowledge of the language/framework's best practices, common pitfalls, security patterns, and idiomatic style
   b. Cross-reference for completeness against well-known standards:
      - OWASP patterns for security
      - Language ecosystem defaults (eslint recommended, pylint, clippy, etc.)
      - Official style guides (Google, Airbnb, PEP 8, etc.)
      - Framework-specific best practices (React docs, Express security guide, etc.)
   c. Write to `~/.claude/skills/review/guides/{name}.md`
   d. Present the guide to the user for review before first use
4. If user skips: proceed with analysis using agent knowledge only (no guide file), note in output that no guide was used

Multiple guides may be created in one session if the codebase uses multiple languages/frameworks.

---

## State Management

### `.agents/TODO/.review-state` (gitignored)

```yaml
stage: 1
source: path             # "path" (default) or "changed" (git-based)
git-range: abc123..HEAD  # only present when source: changed
path: src/lib/
mode: parallel
started: 2026-02-20T14:30:00Z
analyze-total: 12
analyze-done: 7
refactor-total: 0
refactor-done: 0
```

| Field | Description |
|-------|-------------|
| `stage` | Current stage: `1` (analysis) or `2` (refactoring) |
| `source` | File resolution strategy: `path` (glob expansion) or `changed` (git diff) |
| `git-range` | Git range used for file resolution (only when `source: changed`) |
| `path` | Target path/glob being reviewed, or `(changed files)` for git-based |
| `mode` | Execution mode: `parallel` or `serial` |
| `started` | ISO timestamp when review began |
| `analyze-total` | Total analysis tasks created |
| `analyze-done` | Analysis tasks completed |
| `refactor-total` | Total refactor tasks created |
| `refactor-done` | Refactor tasks completed |

### `.agents/TODO/.review-last-commit` (gitignored)

Tracks the last commit reviewed via `/review changed`. Used as the default base when running `/review changed` with no arguments.

```yaml
commit: abc123def456789...
date: 2026-02-21T12:23:00Z
files-reviewed: 12
findings: 3 Critical, 7 Warning
```

**`.review-state` lifecycle:**
- Created when `/review` starts a multi-stage flow
- Updated as tasks complete
- Checked at start of any `/review` invocation to resume
- Deleted when review completes (both stages done)

**`.review-last-commit` lifecycle:**
- Read at start of `/review changed` (no args) to determine base commit
- Written when a `changed` review completes
- Contains HEAD at time of review **start**, not completion
- If file doesn't exist, `/review changed` defaults to `HEAD~1`

---

## Git Discipline

- **Stage 1:** Task tracking commits ONLY (`[todo]` prefix). Zero code changes. Analysis creates/updates `.agents/TODO/` files only.
- **Stage 2:** Follows the `/todo work` protocol's commit discipline:
  - Code commits: project source files only, concise messages explaining *why*
  - Task tracking commits: `.agents/TODO/` files only, `[todo]` prefix
  - Never mix code and task tracking in the same commit

---

## TODO Integration

| Action | Mechanism |
|--------|-----------|
| Create tasks | Write `.agents/TODO/{slug}.md` directly using the task template |
| Sync index | Run `/todo lint` after batch operations |
| Execute refactors | Full 4-phase work protocol (plan, execute, verify, complete) |
| Deduplicate | Read INDEX.md before creating tasks |
| Filter by tag | Tags: `[review, analyze]` for analysis, `[review, refactor]` for refactoring |

### Slug conventions

- Analysis: `analyze-{file-slug}` — e.g., `analyze-src-lib-api-client` for `src/lib/api-client.ts`
- Refactoring: `refactor-{file-slug}` — e.g., `refactor-src-lib-api-client` for `src/lib/api-client.ts`

### File slug generation

Convert the file path to a slug: strip extension, replace `/` and `.` with `-`, collapse multiple dashes.

Examples:
- `src/lib/api-client.ts` → `src-lib-api-client`
- `apps/taskmill-ui/src/components/Board.tsx` → `apps-taskmill-ui-src-components-board`
