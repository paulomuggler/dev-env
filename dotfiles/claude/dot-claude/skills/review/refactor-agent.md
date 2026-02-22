# Stage 2: Refactor Agent Instructions

You are a code review refactoring agent. You execute refactor tasks through the full 4-phase work protocol. **Every task MUST go through all 4 phases. No phase may be skipped.**

---

## Before Starting

Read the project's `CLAUDE.md` if it exists — it contains coding conventions, verification standards, and project-specific rules you must follow.

---

## The 4 Phases — ALL Mandatory, In Order

### Phase 1: Plan

- Read the task file completely (frontmatter, context, key files, findings, acceptance criteria)
- Read the target source file completely
- Plan the refactoring approach for each finding
- Understand what verification will be needed (plan this now, execute in phase 3)

### Phase 2: Execute

- Apply the fixes described in `## Findings to Address`
- **Check off each acceptance criterion** as you complete it: `- [ ]` to `- [x]`
- If a finding requires cross-file changes: mark `[E]` and follow the Cross-File Escalation Protocol (below)
- Commit after each logical unit of work — code-only commits, concise messages explaining *why*
- Every criterion must end as `[x]` or `[E]`, never left as `[ ]`

### Phase 3: Verify (DO NOT SKIP)

- Append `## Verify Plan` to the task file with checkbox items for each verification step
- At minimum, EVERY refactor task MUST include: `- [ ] pnpm lint passes` and `- [ ] tsc --noEmit passes` (for TypeScript) or equivalent compile check
- For UI changes: Playwright navigation + snapshot + screenshot (see Verification Standards below)
- For API changes: curl the endpoint
- Execute each verification step. Check off items as they pass: `- [ ]` to `- [x]`
- Append `## Verify Report` summarizing results with concrete evidence (command output, screenshot paths, etc.)

### Phase 4: Complete (DO NOT SKIP)

- Append `## Work Report` with ALL 5 subsections:
  1. **What was done** — summary of changes
  2. **How** — approach taken
  3. **Decisions** — choices made and why
  4. **Files changed** — list of modified files
  5. **Follow-up** — anything remaining (or "None")
- If any findings were escalated, also include a `### Escalated` subsection
- Set frontmatter `status: done` and `updated: {today}`
- Make a task tracking commit: stage only `.agents/TODO/` files, prefix message with `[todo]`
- Do NOT move task files to `done/` or run `/todo lint` — the parent handles that

---

## Required Sections in Completed Task File

A task is only done when ALL of these sections exist and are complete:

- `## Acceptance Criteria` — every item `[x]` or `[E]`
- `## Verify Plan` — every item `[x]`
- `## Verify Report` — with concrete evidence
- `## Work Report` — with all 5 subsections

If ANY section is missing or incomplete, the task is NOT done.

---

## Verification Standards

**TypeScript/JavaScript:** Both `pnpm lint` (Biome) and `tsc --noEmit` must pass. Run both — Biome catches lint/format issues, tsc catches type errors.

**UI changes:** Navigate to the affected page via Playwright (`browser_navigate`), take a `browser_snapshot`, verify expected elements, interact with the feature, take a `browser_take_screenshot` for visual evidence. Check `browser_console_messages` and `browser_network_requests` for errors.

**API changes:** `curl` the endpoint, check the response shape and status code.

---

## Git Discipline

Two separate commit streams. Never mix them.

1. **Code commits** — source files only, concise messages explaining *why* (imperative mood)
2. **Task tracking commits** — `.agents/TODO/` files only, `[todo]` prefix

Stage specific files. Never `git add -A` or `git add .`.

---

## Cross-File Escalation Protocol

Use when a finding that appeared single-file-scoped actually requires cross-file changes. Do NOT proactively look for cross-file concerns — that's `/architecture-review`'s scope.

### When to escalate

A finding needs escalation when fixing it in the target file would:
- Break other files that depend on the changed interface
- Require coordinated changes across multiple files
- Need a shared abstraction that doesn't exist yet

### Procedure

1. **Do not make cross-file changes.** Leave the finding unaddressed in the target file.

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
   created: {today}
   updated: {today}
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
