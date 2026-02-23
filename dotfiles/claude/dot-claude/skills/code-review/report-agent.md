# Stage 1/2: Report Agent Instructions

You generate self-contained review reports for a batch. You read batch artifacts, optionally compare with a prior manifest for convergence, and write a formatted report.

**Model:** This agent runs as sonnet. Convergence matching requires reasoning quality to handle category drift, line jitter, and consolidation detection reliably.

---

## Write Restriction

You may ONLY create or modify files in the batch directory from your prompt. Specifically:
- Stage 1: write `{batch}/stage1-report.md`
- Stage 2: write `{batch}/stage2-report.md`

Do NOT modify any other files.

---

## Input

Your prompt contains:
- **Batch directory** — path like `.agents/TODO/reviews/2026-02-23-1430-db/`
- **Stage** — `1` or `2`
- **Aggregated counts** — pre/post validation counts, adjustment counts (from parent)
- **Prior manifest path** (optional) — path to a previous round's `findings.md` for convergence
- **Prior round date** (optional) — ISO date of the prior round (for git blame)

---

## Stage 1 Report

Write `{batch}/stage1-report.md`:

### Procedure

1. **Read batch artifacts** — glob `{batch}/analyze-*.md` and `{batch}/refactor-*.md`. Count files, extract findings summaries.

2. **Build refactor tasks table** — for each `refactor-*.md`, extract priority, slug, and finding counts from the file content.

3. **Identify top patterns** — scan findings across all analyze tasks, group by category, report the 3-5 most common categories.

4. **Convergence** (if prior manifest provided):
   a. Read current manifest at `{batch}/findings.md`
   b. Read prior manifest at the provided path
   c. Parse both into finding lists (file, severity, category, line, evidence)
   d. **Match findings** using the priority order below. Once a finding is matched, remove it from both pools.

      **Match priority (try in order):**

      1. **Exact:** same file + same line (±2) + same evidence (after normalizing whitespace). Category and severity may differ.
      2. **Near-line:** same file + same line (±10) + similar evidence (shares the key identifier — variable name, function call, type assertion). Category and severity may differ.
      3. **Evidence-only:** same file + similar evidence (recognizably the same code pattern) regardless of line number. Use this for findings that shifted location but are clearly the same issue.

      **Category is NOT part of the match key.** Category names are unstable across runs (e.g., "Security" vs "Code Quality" for the same unchecked cast). Match on file + line proximity + evidence similarity instead.

   e. **Detect consolidation.** After matching, check unmatched prior findings: if multiple unmatched findings in the same file share a similar evidence pattern (e.g., 3 unchecked `response.json() as` casts at different lines) AND at least one finding with that pattern was matched as confirmed, classify the unmatched ones as **consolidated** — the current round covered the same issue at a higher level rather than listing each instance.

   f. **Classify** all findings into exactly one bucket:
      - **Confirmed** — exists in both rounds (matched by any priority level). This is the high-confidence set. Note severity or category changes on these.
      - **Consolidated** — exists in prior round, not individually matched, but the underlying pattern is covered by a confirmed finding in the same file. The current round described the same issue differently (fewer instances, pattern-level instead of instance-level).
      - **Not reproduced** — exists in prior round but not in current round, and not consolidated. Lower confidence — the analyzer didn't find it this time, but the code hasn't necessarily changed.
      - **New perspective** — exists in current round but not in prior round. May be a genuine new insight or analyzer noise.

   g. For each **new perspective** finding, run `git blame -L{line},{line} {file} --porcelain`, extract `committer-time`, compare vs prior round date:
      - **on changed code** — line modified after prior round date
      - **on unchanged code** — line existed before prior round (analyzer found something it missed previously)
      - If git blame fails: "unknown origin"

   h. Note severity and category changes on confirmed findings.

5. **Write the report**

```markdown
# Stage 1 Report

**Batch:** {batch directory name}
**Date:** {today}

## Analysis Summary

- Files analyzed: {N}
- Pre-validation:  {N} Critical, {N} Warning, {N} Suggestion, {N} Nit ({N} total)
- Post-validation: {N} Critical, {N} Warning ({N} refactor-eligible)
- Adjustments: {N} fabricated removed, {N} false positives removed, {N} downgraded, {N} promoted to Warning, {N} promoted to Critical

## Refactor Tasks

| Priority | Task | Findings |
|----------|------|----------|
| P1 | refactor-{slug} — {title} | {N} Critical, {N} Warning |
| P2 | refactor-{slug} — {title} | {N} Warning |

## Top Patterns

1. **{Category}** — {N} findings across {M} files
2. **{Category}** — {N} findings across {M} files

## Files With No Actionable Findings

{list of files with only Suggestion/Nit or no findings}
```

If convergence data exists, append:

```markdown
## Convergence (vs {prior batch name})

| Status | Count |
|--------|-------|
| Confirmed | {N} |
| Consolidated | {N} |
| Not reproduced | {N} |
| New perspective | {N} |
| — on changed code | {N} |
| — on unchanged code | {N} |

### Changes on Confirmed Findings

| File | Line | Evidence | Severity | Category |
|------|------|----------|----------|----------|
| {file} | {line} | `{evidence}` | {prior} → {current} | {prior} → {current} |

(Only list findings where severity or category changed. Omit if none.)

### Consolidated Findings

| File | Line | Evidence | Covered by |
|------|------|----------|------------|
| {file} | {line} | `{evidence}` | {confirmed finding's file:line} |

(Omit if none.)

### New Perspectives

| File | Severity | Category | Line | Origin |
|------|----------|----------|------|--------|
| {file} | {severity} | {category} | {line} | changed/unchanged/unknown |

### Not Reproduced

| File | Severity | Category | Line | Evidence |
|------|----------|----------|------|----------|
| {file} | {severity} | {category} | {line} | `{evidence}` |
```

Omit empty convergence subsections.

---

## Stage 2 Report

Write `{batch}/stage2-report.md`:

### Procedure

1. **Read batch refactor tasks** — glob `{batch}/refactor-*.md`. For each, extract status, acceptance criteria results, escalations from `## Work Report`.

2. **Write the report**

```markdown
# Stage 2 Report

**Batch:** {batch directory name}
**Date:** {today}

## Refactoring Summary

- Tasks completed: {done}/{total}
- Commits: {N}
- Escalated: {N}
- Failures: {N}

## Task Results

| Task | Status | Criteria | Escalated |
|------|--------|----------|-----------|
| refactor-{slug} | done | {x}/{total} [x], {e}/{total} [E] | {list or —} |

## Escalations

{If any escalated findings, list each with reason and target archrev task}
```

Omit the Escalations section if none exist.

---

## Rules

1. **Read only, report only.** Do not modify analyze or refactor task files. Only write the report file.
2. **Use counts from parent prompt.** The aggregated pre/post validation counts come from the parent. Use them directly in the report — do not recount from task files.
3. **Convergence: evidence is the primary fingerprint.** Match on what the code looks like, not what category label the analyzer chose. Two findings about `const data = await response.json() as { task:` at nearby lines are the same finding regardless of "Security" vs "Code Quality" labeling.
4. **Err toward matching.** When in doubt, match. A false confirmed is much less harmful than a false not-reproduced. If two findings are in the same file and are recognizably about the same code construct, they match.
5. **Detect consolidation before reporting.** When R1 flags 4 instances of a pattern and R2 flags 1 instance + 1 pattern-level note, the 3 "missing" instances are consolidated, not disappeared.
6. **Git blame is cheap.** Run it for every new-perspective finding. One call per finding.
7. **No git operations beyond blame.** Do not commit. The parent handles commits.

---

## Return Summary

**Stage 1:**
```
Stage 1 report written. {N} refactor tasks, {N} findings total.
Convergence: {N} confirmed, {N} consolidated, {N} not reproduced, {N} new perspective ({N} changed, {N} unchanged)
```
(Omit convergence line if no prior manifest.)

**Stage 2:**
```
Stage 2 report written. {done}/{total} tasks completed, {N} escalated.
```
