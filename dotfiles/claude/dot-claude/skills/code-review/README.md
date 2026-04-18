# /code-review — Code Review Skill

Single-file-scope code review: analyze files for issues, then refactor through the TODO work protocol.

## Quick Reference

```
/code-review <path>                      Full review (analyze + refactor)
/code-review <path> --serial             Serial mode (main context, no subagents)
/code-review <path> --model sonnet       Use sonnet model for subagents (default: opus)
/code-review analyze <path>              Stage 1 only — analysis
/code-review analyze <path> --serial     Analysis only, serial mode
/code-review refactor                    Stage 2 only — execute pending refactor tasks
/code-review refactor --serial           Refactors serially
/code-review changed                     Since last reviewed commit
/code-review changed <N>                 Last N commits
/code-review changed <hash>              Since commit hash
/code-review changed --since <date>      Since date
/code-review changed --analyze           Stage 1 only
/code-review guide <name>                Show or create a review guide
/code-review guide list                  List available guides
/code-review status                      Show review-tagged tasks
```

## Flags

| Flag | Values | Default | Effect |
|------|--------|---------|--------|
| `--serial` | *(boolean)* | off | Process in main context instead of spawning subagents |
| `--model` | `haiku`, `sonnet`, `opus` | `opus` | Model used for subagent Task tool invocations |

## How It Works

### Stage 1: Analysis (read-only)

1. Resolves target files from the path/glob
2. Detects languages and frameworks, loads all applicable guides (language + framework)
3. Reads each file and evaluates against recommended categories plus anything else discovered
4. Documents findings by severity (Critical, Warning, Suggestion, Nit)
5. Creates one refactor task per file that has Critical or Warning findings

**Output:** `analyze-*` tasks (done) + `refactor-*` tasks (pending) in `.agents/TODO/`

### Stage 2: Refactoring

1. Picks up pending `refactor-*` tasks tagged with `[review, refactor]`
2. Executes each through the full `/todo work` protocol (plan, execute, verify, complete)
3. Each task targets exactly one file — safe for parallel execution

### Parallel vs Serial

**Parallel (default):** Batches tasks across subagents for concurrent execution. Faster but uses more context. Each subagent handles a batch of non-conflicting tasks.

**Serial (`--serial`):** Processes tasks one at a time in the main context. Slower but gives you full visibility into each analysis/refactor step.

## Review Categories

Recommended categories (single-file scope). The agent also flags any other issues it discovers — these are a starting point, not a boundary.

| Category | What It Catches |
|----------|----------------|
| Security | Injection, auth bypass, crypto misuse, data exposure |
| Correctness | Logic errors, off-by-one, null handling, edge cases |
| Performance | Unnecessary allocations, complexity, hot-path issues |
| Error Handling | Missing error paths, swallowed exceptions, fail-open |
| Code Quality | Complexity, naming, dead code, magic numbers, duplication |
| Style | Language idioms, conventions, formatting |
| Single-File Design | SRP violations, god functions, too many responsibilities |
| Comment Hygiene | Stale comments, resolved TODOs, misleading descriptions |

The agent may also flag: auth/validation gaps, resource management issues, concurrency problems, accessibility concerns, or any other issue it discovers within single-file scope.

## Severity Levels

| Severity | Task Created? | Priority |
|----------|--------------|----------|
| Critical | Yes | P1 |
| Warning | Yes | P2 |
| Suggestion | No (documented only) | — |
| Nit | No (documented only) | — |

## Review Guides

Guides live in `~/.claude/skills/code-review/guides/{name}.md`. They provide language- and framework-specific rules, anti-patterns, and examples.

### Guide types

- **Language guides** (`typescript.md`, `python.md`) — language-specific pitfalls, idioms, type system issues
- **Framework guides** (`react.md`, `express.md`) — framework-specific anti-patterns, lifecycle issues, security patterns

Multiple guides load simultaneously. A React + TypeScript file gets both `typescript.md` and `react.md`.

**Guides are supplementary.** The agent uses its own knowledge as the primary source. Guides add ecosystem-specific precision — they don't limit what the agent looks for.

### Available guides

Check with `/code-review guide list`.

### Creating a guide

When `/code-review` encounters a language or framework without a guide, it asks whether to create one. Guides are generated from the agent's knowledge of best practices, cross-referenced against well-known standards (OWASP, official style guides, ecosystem linters, framework docs).

You can also create or view a guide directly:

```
/code-review guide typescript    # Show the TypeScript guide
/code-review guide react         # Create React guide if missing
/code-review guide python        # Create Python guide if missing
```

### Guide format

```markdown
# {Name} Review Guide

## Metadata
- **Type:** language | framework
- **Extensions:** .ext1, .ext2 (for language guides)
- **Updated:** YYYY-MM-DD

## Categories
### Security
- Rules with code examples
### Correctness
- Rules with code examples
...

## Anti-Patterns
| Pattern | Severity | Fix |
|---------|----------|-----|
| ... | ... | ... |
```

### Writing good guide rules

- Include concrete code examples (bad + good) for each rule
- Tie rules to specific severity levels
- Focus on patterns the agent might miss without explicit guidance
- Don't duplicate what the agent already knows — focus on ecosystem-specific gotchas
- Framework guides should focus on what the framework adds beyond the language guide
- Keep anti-pattern tables scannable: pattern name, severity, one-line fix

## State and Resume

The skill tracks progress in `.agents/TODO/.review-state` (gitignored). If a review is interrupted (context compaction, session end), running any `/code-review` command will detect and resume the in-progress review.

## Integration with /todo

- Analysis creates task files directly in `.agents/TODO/`
- `/todo lint` syncs the INDEX after batch operations
- Refactoring uses the full 4-phase work protocol
- Review tasks are tagged `[review, analyze]` or `[review, refactor]` for filtering
- Non-review tasks in TODO are never touched by `/code-review refactor`

## Examples

### Review a single file
```
/code-review src/lib/api-client.ts
```

### Review a directory
```
/code-review src/lib/
```

### Analyze only (skip refactoring)
```
/code-review analyze src/utils/
```

### Run pending refactors from a previous analysis
```
/code-review refactor
```

### Check review progress
```
/code-review status
```
