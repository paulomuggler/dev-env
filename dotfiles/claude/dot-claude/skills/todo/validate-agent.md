# TODO Validate Agent Instructions

You generate a **human validation script** for completed tasks. This is a structured document that a human operator walks through to confirm that agent-claimed work actually holds up.

The output is NOT automated testing. It is a checklist of things a human can verify manually — clicking through UI, running queries, reading code, checking git diffs.

---

## Arguments

Parse the arguments passed after `validate`:

| Pattern | Meaning |
|---------|---------|
| *(empty)* | All tasks currently in `.agents/TODO/done/` |
| `--since YYYY-MM-DD` | Tasks with `updated` date >= the given date (check both `done/` and `archive/done/`) |
| `--tasks slug1,slug2,...` | Specific task slugs (check `done/`, `archive/done/`, and active directory) |
| `--archive YYYY-MM-DD` | All tasks in `.agents/TODO/archive/done/YYYY-MM-DD/` |

---

## Procedure

### 1. Collect Tasks

Based on the arguments, gather the set of completed task files to validate.

- Read each task file's full content (frontmatter + body)
- Order tasks chronologically by `updated` date, earliest first
- If no tasks match the filter, report "No completed tasks found matching the filter" and stop

### 2. For Each Task, Extract Validation Material

Read the task file and collect:

a. **Title and slug** from frontmatter
b. **Acceptance criteria** — all `- [ ]` and `- [x]` checkbox items from the `## Acceptance Criteria` section
c. **Work report** — the `## Work Report` section, specifically:
   - "What was done" items
   - "Files changed" list
   - "Decisions made" list
d. **Verify report** — the `## Verify Report` section if present (agent's self-verification)
e. **Tags** from frontmatter (to categorize the task type)

### 3. Find the Git Commit

For each task, find the commit(s) associated with the work:

```bash
git log --oneline --all --after="YYYY-MM-DDT00:00:00" --before="YYYY-MM-DDT23:59:59" -- <files from work report>
```

Use the task's `updated` date (and `created` date if different) as the date range. Also check for `[todo]` commits referencing the slug. Collect the **code commit hash(es)** — not the `[todo]` tracking commits.

If no commits found by file path, try searching by date range and commit message keywords from the task title.

Record the primary commit hash (or list of hashes if multiple commits).

### 4. Generate Validation Checks

For each task, generate human-actionable validation checks from the collected material:

#### From acceptance criteria
Each acceptance criterion becomes a check, reframed from the agent's perspective to the human's:
- Agent: "Zod schema validates judge output" → Human: "Open a scoring run with validation enabled, trigger it, check that invalid output is retried"
- Agent: "tsc --noEmit clean" → Human: "Run `tsc --noEmit` and confirm exit code 0"

The check should tell the human **what to do** and **what to expect**, not just restate the criterion.

#### From work report: files changed
Generate a "spot check" item: the human can review the git diff to confirm the described changes exist.

#### From work report: decisions made
For non-trivial decisions, generate a "design review" check — the human should assess whether the decision was reasonable given the context.

#### From task type (inferred from tags and content)
- **UI tasks** (tags contain `ui`, or files include routes/components) → "Open [URL], perform [action], verify [result]"
- **Schema/migration tasks** (files include `migrations/`) → "Check migration was applied: `SELECT ...`" or "Verify column exists"
- **API tasks** (files include `routes/`) → "Hit endpoint with curl/httpie, check response"
- **Document/report tasks** (tags contain `assessment`, `report`, or output is .md files) → "Read the document, assess: [specific quality criteria]"
- **Refactor tasks** (tags contain `refactor`) → "Confirm existing functionality still works: [specific check]"

### 5. Write the Validation Script

Create the output file at `.agents/TODO/validations/YYYY-MM-DDTHHMM.md` (using current timestamp).

Create the `validations/` directory if it doesn't exist.

Use this format:

```markdown
---
generated: YYYY-MM-DDTHH:MM:SS
tasks: [slug1, slug2, ...]
task_count: N
---

# Human Validation Script — YYYY-MM-DD

N tasks to validate. Listed in chronological order (earliest completed first).

---

## 1. task-title (slug)

**Completed:** YYYY-MM-DD
**Commit(s):** `abc1234`, `def5678`
**Files touched:** path/to/file.ts, path/to/other.ts (+ N more)

### Checks

- [ ] **Check description** — What to do, what to expect
- [ ] **Check description** — What to do, what to expect
- [ ] ...

### Design decisions to review
- **Decision:** rationale from work report. *Assess: is this reasonable?*

### Notes
> Any context the validator should know (e.g., "this task depends on X being deployed",
> "the agent's verify report flagged Y as a concern").

---

## 2. next-task-title (slug)
...

---

## Sign-off

| # | Task | Slug | Status | Validator | Date | Notes |
|---|------|------|--------|-----------|------|-------|
| 1 | task-title | slug | | | | |
| 2 | task-title | slug | | | | |
| ... | | | | | | |

Status values: PASS / FAIL / SKIP / PARTIAL
```

### 6. Report

Output a summary to the user:

```
Validation Script Generated
────────────────────────────
Tasks: N
Output: .agents/TODO/validations/YYYY-MM-DDTHHMM.md

Tasks included:
  1. task-title (slug) — N checks
  2. task-title (slug) — N checks
  ...
```

---

## Guidelines

- **Be specific.** "Verify the feature works" is not a check. "Open http://localhost:5173/experiments/1/scoring, click 'New Definition', toggle 'Validate output' on, confirm max retries input appears" is.
- **Include commands.** If the check involves running something, write the exact command.
- **Don't over-generate.** 3-6 checks per task is typical. A simple one-file refactor might have 2 checks. A complex multi-file feature might have 8. Use judgment.
- **Chronological order.** Don't reorder by risk or priority. Just list tasks in the order they were completed (`updated` date, earliest first).
- **Git commit hashes are pointers, not checks.** Include them so the human can `git show <hash>` if they want to inspect the diff. Don't make "review the diff" a separate check unless the task is specifically a refactor where the diff IS the deliverable.
- **Reuse the agent's verify report.** If the agent already ran Playwright screenshots or curl commands, note that in the "Notes" section — the human can decide whether to re-run those checks or trust them.
- **Don't duplicate the task file.** The validation script should be self-contained enough to follow without reading the original task, but it shouldn't reproduce the entire task body. Reference the task file path if the human wants full context.
