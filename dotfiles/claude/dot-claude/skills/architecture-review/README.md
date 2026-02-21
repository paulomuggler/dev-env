# /architecture-review — Architectural Review Skill

Cross-file architectural analysis: find dead code, circular dependencies, duplication, layering violations, coupling issues, and other structural problems across the codebase. Complements `/review` which handles single-file concerns only.

## Quick Reference

```
/architecture-review <path>                    Full pipeline (analyze + refactor)
/architecture-review <path> --analyze-only     Analyze only, skip refactoring
/architecture-review refactor                  Execute pending archrev-refactor tasks
/architecture-review model                     Display the structural model
/architecture-review guide <name>              Show/create architecture guide
/architecture-review guide list                List available guides
/architecture-review status                    Show architecture-review-tagged tasks
```

## How It Works

### Stage 1: Analysis (read-only)

1. **Structural scan** — builds an import graph, export map, and file metrics for the target path
2. **Architectural analysis** — applies analysis categories against the structural model, loading applicable language/framework guides
3. **Task creation** — Critical and Warning findings become `archrev-refactor-*` tasks in `.agents/TODO/`

**Output:** `.archreview-model.md` (structural model), `archrev-analyze-*` task (findings record), `archrev-refactor-*` tasks (pending work)

### Stage 2: Refactoring

1. Picks up pending `archrev-refactor-*` tasks tagged with `[architecture-review, refactor]`
2. Executes each through the full `/todo work` protocol (plan, execute, verify, complete)
3. Tasks may touch multiple files — serial execution is the default for safety

### Analyze-Only Mode

Use `--analyze-only` to run Stage 1 without executing refactoring. Useful for getting a structural overview and reviewing findings before committing to changes.

## Analysis Categories

| Category | What It Finds |
|----------|--------------|
| Dead Code | Exported symbols with no importers, orphan files, unreachable modules |
| Circular Dependencies | Import cycles (distinguishes type-only from runtime) |
| God Files | Excessive size, too many exports, too many responsibilities, high fan-in |
| Duplication | Similar logic across files, copy-paste patterns, parallel implementations |
| Layering Violations | Imports crossing architectural boundaries (UI→data, app→app internals) |
| Coupling & Cohesion | Excessive cross-boundary imports, scattered related logic, high fan-out |
| Inconsistent Patterns | Same problem solved differently across the codebase |
| API Surface | Over-exported internals, missing/bloated barrel files |

The agent also flags concerns outside these categories: security gaps, cross-boundary performance issues, configuration drift, missing abstractions.

## Severity Levels

| Severity | Task Created? | Priority |
|----------|--------------|----------|
| Critical | Yes | P1 |
| Warning | Yes | P2 |
| Suggestion | No (documented only) | — |

## Structural Model

The structural model (`.agents/TODO/.archreview-model.md`) captures:
- Import graph with resolved file paths
- Export map (names and types per file)
- File metrics (line count, export count, import count)
- Derived metrics (fan-in, fan-out, dead exports)
- Circular dependency cycles
- Module boundaries

View it anytime with `/architecture-review model`.

## Architecture Guides

Guides live in `~/.claude/skills/architecture-review/guides/{name}.md`. They provide language- and framework-specific architectural knowledge.

### Available guides

Check with `/architecture-review guide list`.

### Guide types

- **Language guides** (`typescript.md`, `python.md`) — module system, type patterns, dependency management
- **Framework guides** (`react.md`, `express.md`) — component architecture, anti-patterns, modularization idioms

Multiple guides load simultaneously for multi-framework projects (e.g., TypeScript + React).

### Creating a guide

```
/architecture-review guide python        # Create Python guide if missing
/architecture-review guide react         # Create React guide if missing
```

Guides are supplementary — the agent uses its own knowledge as the primary source and guides add ecosystem-specific precision.

## State and Resume

Progress is tracked in `.agents/TODO/.archreview-state` (gitignored). If a review is interrupted, running any `/architecture-review` command detects and resumes the in-progress review.

## Integration with /todo

- Analysis creates task files directly in `.agents/TODO/`
- `/todo lint` syncs the INDEX after batch operations
- Refactoring uses the full 4-phase work protocol
- Tasks are tagged `[architecture-review, analyze]` or `[architecture-review, refactor]`
- Non-architecture-review tasks in TODO are never touched by `/architecture-review refactor`

## Key Differences from /review

| Aspect | /review | /architecture-review |
|--------|---------|---------------------|
| Scope | Single file | Cross-file |
| Categories | Security, correctness, style... | Dead code, circular deps, coupling... |
| Task mapping | 1:1 file-to-task | Tasks may touch multiple files |
| Default execution | Parallel | Serial (cross-file changes are riskier) |
| Model | None | Structural model (import graph, metrics) |
| Guides | Per-language | Per-language AND per-framework |

## Examples

### Analyze a directory

```
/architecture-review src/
```

### Analyze only (review findings before refactoring)

```
/architecture-review src/ --analyze-only
```

### Execute pending refactoring tasks

```
/architecture-review refactor
```

### Check the structural model

```
/architecture-review model
```

### Check progress

```
/architecture-review status
```
