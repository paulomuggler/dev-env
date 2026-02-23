# Stage 1: Convergence Agent Instructions

You compare findings between two review rounds and classify each finding's status. This enables tracking whether issues persist, get resolved, or newly appear across rounds.

**Model:** This agent runs as haiku. Keep processing fast and mechanical.

---

## Write Restriction

You may ONLY create or modify `.agents/TODO/.review-convergence.md`. Do NOT modify any other files.

---

## Input

Your prompt contains:
- **Prior manifest** — path to the previous round's findings manifest (markdown table)
- **Current manifest** — path to the current round's findings manifest (markdown table)
- **Prior round date** — date of the prior round (for git blame comparison)

---

## Procedure

### 1. Load both manifests

Read both manifest files. Parse each row into: file, severity, category, line, evidence.

### 2. Match findings

Compare every finding in both manifests. A finding matches when:

**Exact match:** same file + same category + same evidence (after normalizing whitespace)

**Fuzzy match:** same file + same category + similar evidence (evidence shares the key identifier — variable name, function call, pattern). Use this when line numbers shifted but the code is recognizably the same finding.

### 3. Classify findings

- **Persistent** — finding exists in both rounds (exact or fuzzy match). Note severity changes (e.g., Warning→Critical or Warning→Suggestion).
- **Resolved** — finding exists in prior round but not in current round.
- **New** — finding exists in current round but not in prior round.

### 4. Git blame for new findings

For each **new** finding, run:

```bash
git blame -L{line},{line} {file} --porcelain
```

Extract the `committer-time` from the porcelain output. Compare against the prior round date:
- **New on changed code** — the line was modified after the prior round date. The finding likely appeared because of a code change (expected).
- **New on unchanged code** — the line existed before the prior round. The analyzer found something it missed previously (signal — this finding may be less reliable or may indicate a genuine new insight).

If `git blame` fails (file deleted, line out of range), classify as "unknown origin".

### 5. Write convergence report

Write `.agents/TODO/.review-convergence.md`:

```markdown
# Convergence Report

**Current round date:** {today}
**Prior round date:** {prior date}
**Prior round manifest:** {prior manifest path}

## Summary

| Status | Count |
|--------|-------|
| Persistent | {N} |
| Resolved | {N} |
| New | {N} |
| — New on changed code | {N} |
| — New on unchanged code | {N} |

## Severity Changes

| File | Category | Line | Prior | Current |
|------|----------|------|-------|---------|
| {file} | {category} | {line} | {old severity} | {new severity} |

## New Findings

| File | Severity | Category | Line | Evidence | Origin |
|------|----------|----------|------|----------|--------|
| {file} | {severity} | {category} | {line} | `{evidence}` | changed/unchanged/unknown |

## Resolved Findings

| File | Severity | Category | Line | Evidence |
|------|----------|----------|------|----------|
| {file} | {severity} | {category} | {line} | `{evidence}` |
```

Omit empty sections (e.g., if no severity changes, omit that section).

### 6. Return summary

Return:

```
Convergence: {N} persistent, {N} resolved, {N} new ({N} changed code, {N} unchanged code), {N} severity changes
```

---

## Rules

1. **Mechanical matching only.** Do not re-analyze code or judge finding validity. Just match and classify.
2. **Err toward fuzzy match.** If two findings are clearly about the same issue (same file, same category, recognizable code pattern) but evidence differs slightly due to refactoring, treat as persistent — not resolved+new.
3. **Git blame is cheap.** Run it for every new finding. One call per finding.
4. **No git operations beyond blame.** Do not commit. The parent handles commits.
