---
name: lint-fix
description: Run linters and fix issues — dispatch one subagent per file
user-invocable: true
disable-model-invocation: false
arguments: $ARGUMENTS
---

# /lint-fix — Lint Fix Skill

Dispatch subagents to fix lint issues file-by-file. Each subagent owns its file completely: runs
the linters, applies auto-fixes, reasons about unsafe fixes, applies manual fixes, verifies.

## Quick Reference

```
/lint-fix                           Fix everything
/lint-fix apps/api/                 Fix in subtree only
/lint-fix --dry-run                 Report only, don't fix anything
/lint-fix --rules unsafe            Only no-unsafe-* family
/lint-fix --rules nullish           Only prefer-nullish-coalescing
/lint-fix --rules any               Only noExplicitAny + noImplicitAnyLet
/lint-fix --rules assertions        Only noNonNullAssertion
/lint-fix --model sonnet            Use sonnet for subagents (default: haiku)
```

## Execution Rules

1. **Never use worktree isolation** — all subagents work in the main repo. Each targets a unique file.
2. **Subagent type: `"general-purpose"`** — always.
3. **Default model: `haiku`** — sufficient for most mechanical fixes. Use `--model sonnet` for
   `--rules unsafe` (tracing `any` sources may require reading imported signatures).
4. **Orchestrator owns git** — subagents edit files only. Orchestrator stages, commits, verifies.
5. **Resolve `~`** before constructing subagent prompts.

## Flags

| Flag | Default | Effect |
|------|---------|--------|
| `--dry-run` | off | Scan and report only — no fixes, no commits |
| `--rules` | *(all)* | Comma-separated rule group filter (see Rule Groups below) |
| `--model` | `haiku` | Model for subagent Task calls |
| `--max-files` | `20` | Maximum files to dispatch per batch |
| `--max-batches` | `5` | Maximum batches before stopping (context budget guard) |

## Rule Groups

Shorthand names for `--rules` flag. Multiple can be comma-separated.

| Group | Rules included |
|-------|---------------|
| `unsafe` | `no-unsafe-argument`, `no-unsafe-assignment`, `no-unsafe-call`, `no-unsafe-member-access`, `no-unsafe-return` |
| `nullish` | `prefer-nullish-coalescing` |
| `any` | `noExplicitAny`, `noImplicitAnyLet` |
| `assertions` | `noNonNullAssertion`, `no-unnecessary-type-assertion` |
| `template` | `restrict-template-expressions`, `restrict-plus-operands`, `useTemplate` |
| `unused` | `noUnusedVariables`, `noUnusedImports`, `noUnusedFunctionParameters` |
| `imports` | `useNodejsImportProtocol`, `useImportType` |

## Excluded Rules (never processed)

These need refactoring or domain knowledge, not lint fixing:

- `noExcessiveCognitiveComplexity` — structural refactoring
- `useExhaustiveDependencies` — React hook semantics, high false-positive rate
- `noLabelWithoutControl`, `useButtonType`, `noStaticElementInteractions`, `useKeyWithClickEvents`, `noAutofocus`, `noSvgWithoutTitle` — a11y rules need UI context
- `noUselessCatch` — may be intentional error boundaries
- `useIterableCallbackReturn` — needs algorithm understanding
- Parse errors — structural issues, not lint

## Procedure

### Phase 1: Discover files

1. Detect linter tools available in the project:
   - Check for `biome.json` → Biome available
   - Check for `eslint.config.*` → ESLint available
2. Get the list of files with lint issues (lightweight — file names only, not full diagnostics):
   - Biome: `pnpm exec biome lint --max-diagnostics=0 2>&1 | grep -oP '^[^\s]+\.tsx?' | sort -u`
   - ESLint: `pnpm exec eslint -f json | jq -r '.[] | select(.messages | length > 0) | .filePath'`
3. Merge and deduplicate the file lists
4. Apply path filter if subtree argument given
5. Apply `--rules` filter: if set, re-run linters with rule filter to narrow the file list
6. Report to user: "{N} files with lint issues"
7. If `--dry-run`: run linters with full output, show summary table by rule, stop here

### Phase 2–3: Batch loop (dispatch → verify → commit → repeat)

Sort all discovered files by path. Split into batches of `--max-files` (default 20).
Loop over batches, stopping when all files are processed or `--max-batches` (default 5) is
reached.

**For each batch:**

#### 2a. Dispatch subagents

For each file in the batch, spawn a subagent:

   ```
   subagent_type: "general-purpose"
   model: "{model}"
   prompt: |
     {contents of fix-agent.md}

     ---

     ## Your Assignment

     **File:** `{absolute_path}`
     **Project root:** `{project_root}`
     **Rule filter:** {rule groups if --rules specified, or "all applicable"}

     **Linter commands:**
     - Biome: `pnpm exec biome lint {relative_path}`
     - ESLint: `pnpm exec eslint {relative_path}`
     - Typecheck: `pnpm exec tsc --noEmit -p {nearest_tsconfig}`

     **Fix patterns reference:**
     {contents of fix-patterns.md}
   ```

   Note: subagent runs the linters itself to get its own issues. No pre-parsed issue list
   needed — the subagent has full local context.

**Parallelism — stagger for prompt caching:**
- **Batch 1 only:** Launch **1 subagent first** and wait for it to complete. This warms the
  prompt cache (the shared prefix of fix-agent instructions + fix-patterns reference).
  Then launch the remaining files in the batch in parallel (up to 5 at a time).
- **Batches 2+:** Cache is already warm. Launch all files in the batch in parallel (up to 5).

Collect results from each subagent (returned in its structured report):
- `fixed`: issues resolved
- `suppressed`: issues intentionally suppressed with justification
- `skipped`: issues requiring cross-file changes or human judgment
- `failed`: fixes attempted but reverted (broke typecheck or introduced new issues)

#### 2b. Verify and commit the batch

1. Run typecheck across the full project: `pnpm typecheck`
2. If typecheck fails:
   - Identify which file(s) caused the failure from the error output
   - Revert those files: `git checkout -- {file}`
   - Move them from `fixed` to `failed` in the batch results with the typecheck error
   - Re-run typecheck to confirm it passes
   - Repeat until typecheck passes
3. Stage all successfully modified files: `git add {files}`
4. Commit: `lint: fix {N} issues across {F} files (batch {B}/{total})`
5. Print batch summary: files fixed, issues fixed/suppressed/skipped/failed

#### 2c. Continue or stop

- If more batches remain and batch count < `--max-batches`: continue to next batch
- If `--max-batches` reached with files remaining: stop and report remaining file count
  with message: `"{N} files remaining. Re-run to continue."`

### Phase 4: Report

Print summary (aggregated across all batches):

```
## Lint Fix Report

| Metric | Value |
|--------|-------|
| Batches completed | {B} / {total} |
| Files dispatched | {N} |
| Files with fixes | {N} |
| Files remaining | {N} (0 if all batches completed) |
| Issues fixed | {N} |
| Issues suppressed | {N} |
| Issues skipped | {N} |
| Issues failed | {N} |

### Failed files (if any)
| File | Error |
|------|-------|
| {path} | {typecheck error or subagent failure reason} |

These files were reverted to their original state. To retry with a smarter model:
`/lint-fix {path} --model sonnet`

### Suppressed issues (if any)
| File | Line | Rule | Justification |
|------|------|------|---------------|
| {path} | {line} | {rule} | {agent's justification} |

Review these — the agent judged them correct but suppression should be the exception.

### Skipped issues (if any)
| File | Line | Rule | Reason |
|------|------|------|--------|
| {path} | {line} | {rule} | {why skipped — cross-file, semantic risk, etc.} |

### Agent Stats
| Metric | Value |
|--------|-------|
| Subagents dispatched | {N} |
| Wall clock time | {duration} |
| Aggregated agent time | {sum of individual duration_ms} |
| Total tokens | {sum of total_tokens from all subagents} |
| Total tool uses | {sum of tool_uses from all subagents} |

Per-agent breakdown:
| # | File | Tokens | Tools | Duration |
|---|------|--------|-------|----------|
| 1 | {relative_path} | {total_tokens} | {tool_uses} | {duration_ms} |
```

Note: The Task tool returns `total_tokens`, `tool_uses`, and `duration_ms` per subagent.
Cached vs uncached token split and input/output breakdown are not available.
If files remain after `--max-batches`, the report ends with:
`"{N} files remaining. Re-run to continue."`
