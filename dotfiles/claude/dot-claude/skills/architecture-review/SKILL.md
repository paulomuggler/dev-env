---
name: architecture-review
description: Cross-file architectural analysis — find dead code, circular deps, duplication, coupling, layering violations, and create refactoring tasks
user-invocable: true
disable-model-invocation: true
arguments: $ARGUMENTS
---

# /architecture-review — Architectural Review Skill

Cross-file architectural analysis: build a structural model of the codebase (Stage 1), identify architectural issues, create refactoring tasks, then execute fixes via `/todo work` protocol (Stage 2). Complements `/code-review` which handles single-file concerns only.

**Integration:** Uses `.agents/TODO/` for all task tracking. Creates tasks and delegates execution to the `/todo` work protocol.

**State:**
- `.agents/TODO/.archreview-state` — tracks multi-stage progress across context compactions
- `.agents/TODO/.archreview-model.md` — structural model snapshot

Both files are gitignored.

---

## Analysis Categories

| Category | What to Find |
|----------|-------------|
| Dead Code | Exported symbols with no importers. Orphan files (neither export consumed symbols nor are imported). Unreachable modules. |
| Circular Dependencies | Import cycles of any length. Distinguish between benign type-only cycles and problematic runtime cycles. |
| God Files | Files with excessive size, too many exports, too many responsibilities. Files imported by a disproportionate number of other files (high fan-in). |
| Duplication | Similar logic replicated across files — opportunities to extract shared modules. Near-identical functions, copy-paste patterns, parallel implementations. |
| Layering Violations | Imports that cross architectural boundaries. UI reaching into data layer, one app importing another's internals, business logic importing framework-specific code. |
| Coupling & Cohesion | Modules with excessive cross-boundary imports (tight coupling). Related logic scattered across too many files (low cohesion). High fan-out files. |
| Inconsistent Patterns | Same problem solved differently across the codebase — error handling, config access, API client usage, logging, validation. |
| API Surface | Modules exporting too much. Missing index/barrel files where they'd help, or barrel files re-exporting too much. |

**Not exhaustive.** Flag any architectural concern discovered, even if it doesn't fit these categories. Examples: missing auth middleware on route groups, chatty inter-service calls, N+1 patterns spanning service boundaries, configuration drift, raw infrastructure used directly in business logic.

**Severity levels:**
- **Critical** — Runtime circular deps, layering violations in security paths, significant duplication with same bug in copies. Creates P1 refactor task.
- **Warning** — Dead exports, god files, structural circular deps, significant duplication, poor cohesion. Creates P2 refactor task.
- **Suggestion** — High coupling, minor duplication, inconsistent patterns, orphan files, API surface notes. Documented in findings only, no refactor task.

---

## Resume Check (ALWAYS DO THIS FIRST)

Before routing, check if `.agents/TODO/.archreview-state` exists. If it does:

1. Read the file to get the current review state
2. Inform the user: "Resuming architecture review of {path} (stage {stage})"
3. Resume based on state:
   - If `stage: 1, scan-done: false` → continue scanning
   - If `stage: 1, scan-done: true, analyze-done: false` → model exists, continue analysis
   - If `stage: 2` → count remaining `archrev-refactor-*` tasks with `status: pending`, continue refactoring
4. Do NOT start fresh — continue from saved state

---

## Routing

Parse `$ARGUMENTS` to determine the route:

| First token | Route | Description |
|-------------|-------|-------------|
| `refactor` | **stage2** | Execute pending archrev-refactor tasks |
| `model` | **show-model** | Display `.archreview-model.md` |
| `guide` | **guide-manage** | Show, create, or list architecture guides |
| `status` | **archrev-status** | Show architecture-review-tagged tasks |
| path or glob | **full** | Full pipeline (analyze + refactor), or analyze-only if `--analyze-only` flag |
| *(empty)* | **help** | Usage summary |

**Flags (anywhere in args):**
- `--analyze-only` — Run analysis but don't execute refactoring
- `--serial` — Force serial execution for refactoring (already the default)

---

## Route: help (no args)

Display usage summary:

```
/architecture-review <path>                    Full pipeline (analyze + refactor)
/architecture-review <path> --analyze-only     Analyze only, skip refactoring
/architecture-review refactor                  Execute pending archrev-refactor tasks
/architecture-review model                     Display the structural model
/architecture-review guide <language>          Show/create architecture guide
/architecture-review guide list                List available guides
/architecture-review status                    Show architecture-review-tagged tasks
```

---

## Route: archrev-status

1. Glob `.agents/TODO/archrev-*.md`
2. Parse frontmatter from each file
3. Display grouped by status:

```
Architecture Review Tasks
─────────────────────────
Refactor (2 pending, 1 done)
  [ ] archrev-refactor-break-auth-session-cycle — Circular Deps: break auth↔session cycle (P1)
  [ ] archrev-refactor-extract-shared-validation — Duplication: extract shared validation (P2)
  [x] archrev-refactor-narrow-utils-api-surface  — API Surface: narrow utils exports (P2)

Analysis (1 done)
  [x] archrev-analyze-src — Architectural analysis of src/
```

---

## Route: show-model

1. Check if `.agents/TODO/.archreview-model.md` exists
2. If yes, display its contents
3. If no, inform: "No structural model found. Run `/architecture-review <path>` to generate one."

---

## Route: full (path provided)

Run Stage 1, then optionally Stage 2.

1. Parse path/glob, `--analyze-only`, and `--serial` flags from `$ARGUMENTS`
2. Create `.agents/TODO/.archreview-state`:
   ```yaml
   stage: 1
   path: <path>
   started: <ISO timestamp>
   scan-done: false
   analyze-done: false
   refactor-total: 0
   refactor-done: 0
   ```
3. Execute Stage 1 (see below)
4. If `--analyze-only`, delete `.agents/TODO/.archreview-state` and stop
5. Update state: `stage: 2`, set `refactor-total` count
6. Execute Stage 2 (see below)
7. Delete `.agents/TODO/.archreview-state`
8. Report summary

---

## Stage 1: Analysis (Read-Only)

Zero code modifications. Builds a structural model, identifies architectural issues, creates refactoring tasks.

### Step 1: Structural Scan

Build a structural model of the codebase. This is the foundation all analysis categories work from.

The model should capture:
- **Import graph:** which files import which, resolved to actual file paths
- **Export map:** what each file exports (names and types: function, const, type, class, etc.)
- **File metrics:** line count, export count, import count per file
- **Derived metrics:** fan-in (importers), fan-out (dependencies), dead exports (exported but never imported)
- **Circular dependencies:** cycles in the import graph
- **Module boundaries:** directory-level groupings, package.json boundaries

**Approach:** Decide the best scanning strategy based on codebase size and structure. For small-to-medium codebases, grep-based scanning of import/export statements is fast and sufficient. For larger codebases, use subagents to scan directory subtrees in parallel. The structural model doesn't require reading full file content — import/export statement patterns and line counts are enough.

**Output:** Write the model to `.agents/TODO/.archreview-model.md`.

Update `.archreview-state`: `scan-done: true`

### Step 2: Architectural Analysis

Apply the analysis categories against the structural model and codebase. Load all applicable guides (see Guide Layering).

You have autonomy in how to investigate each category. Some categories can be answered purely from the structural model (dead exports, circular deps, god files). Others require reading file content to compare patterns or detect duplication. Decide when to work in the main context, when to spawn subagents, and how deep to go based on what you find.

**Guides are supplementary, not primary.** Rely first on your own knowledge and judgment about architecture, language idioms, and best practices. Guides add ecosystem-specific context — they don't define the boundaries of analysis.

#### Subagent Strategy

When spawning subagents for analysis, use **general-purpose subagents** (`subagent_type: "general-purpose"`). These can read source files, analyze, and write findings directly into `.agents/TODO/` task files — eliminating the parent as a bottleneck and preventing data loss if the parent context compacts.

General-purpose subagents inherit the parent model. No model override is needed.

**WRITE RESTRICTION:** Every analysis subagent prompt must begin with:
> **WRITE RESTRICTION:** You may ONLY create or modify files under `.agents/TODO/`. Do NOT modify any project source files. This is a read-only analysis.

**Delegation patterns:**
- **By category:** Assign one subagent per analysis category (dead code, circular deps, duplication, etc.). Each reads the structural model + relevant files, writes findings and creates refactor tasks for its category.
- **By subtree:** For large codebases, assign subagents to directory subtrees. Each analyzes all categories within its subtree.
- **Hybrid:** Use the structural model to identify clusters of concern, then spawn targeted subagents for each cluster.

Each subagent should write its findings into the analysis summary task file (or a dedicated section) and create `archrev-refactor-*` task files for Critical/Warning findings. The parent validates results after subagents return — checking that task files are properly formatted, findings have evidence, and no project files were modified.

#### Guide Layering

Multiple guides may apply to a single analysis. Load all that are relevant and synthesize them:

1. **Language guide** (e.g., `typescript.md`) — module system, type system patterns, import conventions
2. **Framework guide** (e.g., `react.md`, `express.md`) — component architecture, middleware patterns, lifecycle idioms

For a React + TypeScript codebase, both `typescript.md` and `react.md` would be loaded. Merge their guidance with your own knowledge. If a guide is missing, proceed using your own expertise — guide availability should never block analysis.

Guide location: `~/.claude/skills/architecture-review/guides/{name}.md`

#### Guide Detection

Detect languages and frameworks from the codebase:

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

For each detected language, check `~/.claude/skills/architecture-review/guides/{language}.md`. If a guide exists, load it. If missing, proceed without it — do not block analysis. Guide creation can be triggered separately via `/architecture-review guide <name>`.

### Step 3: Create Tasks from Findings

Each Critical or Warning finding becomes a refactor task.

**Task slug:** `archrev-refactor-{descriptive-slug}` (e.g., `archrev-refactor-break-auth-session-cycle`, `archrev-refactor-extract-shared-validation`)

**Key difference from `/code-review`:** Tasks may touch multiple files (e.g., "extract shared module X from files A, B, C"). The Key Files section lists ALL files the task will touch.

**Deconfliction rule:** Tasks with overlapping Key Files must execute serially. During Stage 2, check for file overlaps and ensure conflicting tasks don't run in parallel.

**Task template:**

```yaml
---
slug: archrev-refactor-{slug}
title: "{Category}: {description}"
priority: P1  # Critical findings; P2 for Warning
status: pending
created: YYYY-MM-DD
updated: YYYY-MM-DD
depends-on: []
tags: [architecture-review, refactor]
---

# {title}

## Context
{Why this is an issue, what the structural model shows, impact on the codebase}

## Key Files
- `{file}` — {what needs to change}

## Findings
### {Severity}
1. **[{Category}]** {description}
   - Evidence: {import chain, metric, code snippet}
   - Fix: {specific refactoring approach}

## Acceptance Criteria
- [ ] {criterion per finding}
- [ ] All files compile after changes
```

**Summary task:** Also create `archrev-analyze-{scope-slug}.md` (marked done immediately) documenting all findings including Suggestions for the record.

Summary task template:

```yaml
---
slug: archrev-analyze-{scope-slug}
title: "Architectural analysis of {path}"
priority: P2
status: done
created: YYYY-MM-DD
updated: YYYY-MM-DD
depends-on: []
tags: [architecture-review, analyze]
---

# Architectural analysis of {path}

## Scope
Files scanned: {count} ({total lines} lines)
Languages: {detected languages}
Guides loaded: {list or "none"}

## All Findings

### Critical
{numbered list}

### Warning
{numbered list}

### Suggestion
{numbered list}

## Tasks Created
{list of created task slugs with titles}
```

Run `/todo lint` after creating all tasks.

Update `.archreview-state`: `analyze-done: true`, set `refactor-total`

### Analysis Report

After creating tasks, display:

```
Architectural Analysis Complete
───────────────────────────────
Scope: {path}
Files scanned: {count} ({lines} lines)

Findings:
  Dead Code:       {N} {severities}
  Circular Deps:   {N} {severities}
  God Files:       {N} {severities}
  Duplication:     {N} {severities}
  Layering:        {N} {severities}
  Coupling:        {N} {severities}
  Inconsistent:    {N} {severities}
  API Surface:     {N} {severities}

Tasks created: {N} ({breakdown by priority})
Model: /architecture-review model
```

---

## Stage 2: Refactoring

Executes archrev-refactor tasks through the full `/todo work` protocol (plan, execute, verify, complete).

**Task Isolation:** Stage 2 does NOT use `/todo work` directly (which picks any pending task). Instead it filters by tag to only touch architecture-review-created tasks.

### Procedure

1. **Discover tasks** — glob `.agents/TODO/archrev-refactor-*.md`. Parse frontmatter. Select tasks where:
   - `tags` contains BOTH `architecture-review` AND `refactor`
   - `status` is `pending`

   Sort by priority (P1 first) then created date (oldest first). If none found, report: "No refactoring tasks. Run `/architecture-review <path>` first."

2. **Execute (serial, default):**

   For each task in order, run the full 4-phase work protocol as defined by the `/todo` skill:
   - Write `.agents/TODO/.work-state` for the task
   - Plan: Read task, plan the refactoring approach
   - Execute: Apply the changes, commit
   - Verify: Run type checks, linting, tests as appropriate
   - Complete: Write work report, mark done, lint, commit task tracking

   Cross-file changes benefit from sequential verification — each refactoring may affect how subsequent tasks should be approached.

3. **File overlap check:** Before executing, parse Key Files from all pending tasks. If any tasks share files, they MUST run sequentially regardless of execution mode. Flag the overlap to the user.

4. **Complete:** Run `/todo lint`, delete `.agents/TODO/.archreview-state`, report summary:

   ```
   Refactoring Complete
   ────────────────────
   Tasks completed: {N}/{total}
   Commits: {N}
   Failures: {N}
   ```

---

## Guide Management

### Guide location

`~/.claude/skills/architecture-review/guides/{name}.md`

Guides are named by language or framework — not just language. A project might use `typescript.md`, `react.md`, and `express.md` simultaneously.

### What guides cover

Ecosystem-specific architectural knowledge that supplements your own expertise:

- **Language guides** (`typescript.md`, `python.md`, etc.)
  - Module system specifics — resolution rules, barrel file conventions, re-export patterns
  - Type system architectural patterns — generics vs unions, type-level module boundaries
  - Dependency management — workspace patterns, peer deps, tree-shaking implications

- **Framework guides** (`react.md`, `express.md`, etc.)
  - Idiomatic component/module architecture — hooks vs render props, middleware chains, plugin patterns
  - Common architectural anti-patterns specific to the framework
  - Modularization idioms — feature folders vs layer folders, co-location conventions
  - Framework-specific god component/file patterns

**Guides are supplementary.** Your own knowledge is the primary source. Guides add precision for ecosystem-specific concerns — they don't limit what you look for.

### Route: guide-manage

Parse the second token of `$ARGUMENTS` after `guide`:

- **`list`** — Glob `~/.claude/skills/architecture-review/guides/*.md`, list available guides with their metadata
- **`<name>`** — If guide exists, display it. If missing, trigger creation flow.

### Guide creation flow

When a guide doesn't exist:

1. Detect language/frameworks from codebase (file extensions, package.json, config files)
2. Ask user: **"Create {name} architecture guide? (Recommended)"** / "Skip for now"
3. If user chooses to create:
   a. Generate from your knowledge of the language/framework's architectural best practices, common structural anti-patterns, and modularization idioms
   b. Cross-reference against ecosystem standards (official style guides, community conventions, linter rules)
   c. Write to `~/.claude/skills/architecture-review/guides/{name}.md`
   d. Present the guide to the user for review before first use
4. If user skips: proceed with analysis using your own knowledge only (no guide file)

---

## State Management

### `.agents/TODO/.archreview-state` (gitignored)

```yaml
stage: 1
path: src/
started: 2026-02-20T14:30:00Z
scan-done: false
analyze-done: false
refactor-total: 0
refactor-done: 0
```

| Field | Description |
|-------|-------------|
| `stage` | Current stage: `1` (analysis) or `2` (refactoring) |
| `path` | Target path/glob being analyzed |
| `started` | ISO timestamp when review began |
| `scan-done` | Whether the structural scan is complete |
| `analyze-done` | Whether the architectural analysis is complete |
| `refactor-total` | Total refactor tasks created |
| `refactor-done` | Refactor tasks completed |

**Lifecycle:**
- Created when `/architecture-review` starts a flow
- Updated as stages complete
- Checked at start of any `/architecture-review` invocation to resume
- Deleted when review completes

### `.agents/TODO/.archreview-model.md` (gitignored)

Structural model snapshot. Regenerated each time Stage 1 runs.

---

## Git Discipline

- **Stage 1:** Task tracking commits ONLY (`[todo]` prefix). Zero code changes. Analysis creates/updates `.agents/TODO/` files only. Model file is gitignored.
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
| Filter by tag | Tags: `[architecture-review, analyze]` for analysis, `[architecture-review, refactor]` for refactoring |

### Slug conventions

- Analysis summary: `archrev-analyze-{scope-slug}` — e.g., `archrev-analyze-src` for `src/`
- Refactoring: `archrev-refactor-{descriptive-slug}` — e.g., `archrev-refactor-break-auth-session-cycle`

### Scope slug generation

Convert the scope path to a slug: strip trailing slash, replace `/` and `.` with `-`, collapse multiple dashes.

Examples:
- `src/` → `src`
- `apps/taskmill-ui/src/` → `apps-taskmill-ui-src`
- `packages/shared/` → `packages-shared`
