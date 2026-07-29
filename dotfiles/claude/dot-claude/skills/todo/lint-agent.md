# TODO Lint Agent

> **As of 2026-07-30 this procedure is automated by `lint.mjs` (same directory)
> — run `node ~/.claude/skills/todo/lint.mjs` instead of spawning an agent.**
> This document remains the procedure's specification and the fallback for
> repair scenarios the script refuses (it exits non-zero naming what needs
> judgment; dispatch an agent on this file for that case only).

Maintain the `.agents/TODO/` file hierarchy: move done tasks, archive old ones,
regenerate INDEX.md — and keep REVIEW-QUEUE.md links live.

**Two invariants this procedure must never violate** (both have been broken in
practice — the guards below exist because of real incidents):

1. **Every file move is a single `git mv`** — atomic, staging the add and the
   delete together. NEVER copy-to-new-path-then-`rm`: that leaves the file
   duplicated in HEAD and a deletion unstaged.
2. **Status values are kebab-case exactly as the schema defines them** —
   `pending`, `in-progress`, `blocked`, `done`, `closed`, `backlog`. NEVER
   "correct" `in-progress` to `in_progress`. NEVER place a task under an INDEX
   section whose name doesn't match the task's own frontmatter `status:`.

---

## Procedure

### 1. Move tasks to their status directory (use `git mv`)

For each move, use `git mv <from> <to>` — never `cp`+`rm`. `mkdir -p` the
destination first if needed. If a moved task's slug appears in
`.agents/TODO/REVIEW-QUEUE.md`, rewrite that link to the new path in the same
pass (step 4 re-checks this).

- **Done:** glob `.agents/TODO/*.md` (exclude the non-task files: `INDEX.md`, `REVIEW-QUEUE.md`, `CONTINUATION.md`), read frontmatter only;
  any `status: done` → `git mv` to `.agents/TODO/done/`.
- **Backlog:** any `status: backlog` → `git mv` to `.agents/TODO/backlog/`.
  Reverse: any `backlog/*.md` whose status is NOT `backlog` (promoted) →
  `git mv` back to `.agents/TODO/`.
- **Closed:** glob `.agents/TODO/*.md` and `backlog/*.md`; any `status: closed`
  → `git mv` to `.agents/TODO/closed/`.

### 2. Auto-archive — but NEVER archive a task still under review

Glob `.agents/TODO/done/*.md` and `.agents/TODO/closed/*.md` (frontmatter only).
A task is archive-eligible ONLY when BOTH hold:

- **Age/count:** its `updated` timestamp is >24h ago (use the date portion —
  first 10 chars — of `updated` for the `archive/{done,closed}/YYYY-MM-DD/`
  folder name), OR the directory count exceeds 30 (then archive oldest by
  `updated` until the count is ≤30); AND
- **Not still under review:** it has NO open (unchecked `- [ ]`) line in
  `.agents/TODO/REVIEW-QUEUE.md` AND does not carry `human-validation: pending`
  in frontmatter. A task awaiting the user's review stays in `done/`/`closed/`
  where the reviewer expects it, regardless of age — **skip it, do not archive.**

Archive with `git mv`. `updated` may be `YYYY-MM-DD` (legacy) or
`YYYY-MM-DD_HH:mm` (current); both compare lexicographically — truncate to 10
chars for folder names. Create archive dirs with `mkdir -p`.

### 3. Regenerate INDEX.md — section keyed on actual status, counts match rows

Read frontmatter from all active tasks (`.agents/TODO/*.md`, excluding the non-task files `INDEX.md`, `REVIEW-QUEUE.md`, `CONTINUATION.md`),
`backlog/*.md`, `done/*.md` (not archived), and `closed/*.md` (not archived).

**Each task goes under the section matching its own `status:` frontmatter — and
nothing else.** A `status: done` task belongs under `## Done`, never under
`## In Progress`, even mid-move. Within a section, sort by priority (P0 first)
then `created` (oldest first; lexicographic tolerates both timestamp formats).

**Every `## Section (N)` count MUST equal the number of rows listed beneath it.**
Derive N by counting the rows you actually emit — not a separate tally.

```markdown
# TODO Index
> Auto-generated. Run `/todo lint` to regenerate.

## Pending (N)

### P0 - Critical
- [ ] [slug](slug.md) - Title

### P2 - Normal
- [ ] [slug](slug.md) - Title

## In Progress (N)
- [~] [slug](slug.md) - Title

## Blocked (N)
- [!] [slug](slug.md) - Title (blocked by: dep1, dep2)

## Done (N)
- [x] [slug](done/slug.md) - Title

## Closed (N)
- [slug](closed/slug.md) - Title

## Backlog (N)

### P3 - Low
- [-] [slug](backlog/slug.md) - Title
```

Only include priority sub-headings and status sections that have tasks. Use the
correct path prefix per section (`done/`, `closed/`, `backlog/`; active tasks
have no prefix).

### 4. Maintain REVIEW-QUEUE.md links

For every task that moved this run, ensure its link in
`.agents/TODO/REVIEW-QUEUE.md` points at the task's new path (`done/`, `closed/`,
`archive/done/YYYY-MM-DD/`, …). Change only the link target — never the checkbox
state or the descriptive text.

### 5. Self-check BEFORE committing (all four must pass)

- **Tree integrity:** `git status --short` shows no file both added-and-deleted
  (duplicate in HEAD) and nothing deleted-but-unstaged — every move is a clean
  rename (`R`).
- **Status casing:** no frontmatter `status:` was changed; all are kebab-case
  schema values.
- **INDEX integrity:** every task under a section actually has that `status:`;
  every `(N)` equals its listed row count.
- **REVIEW-QUEUE links resolve:** every `](…)` path in REVIEW-QUEUE.md points at
  an existing file.

If any check fails, FIX it before committing. If it can't be fixed, report the
failed check rather than committing over it.

### 6. Commit

Moves are already staged by `git mv`. Stage the rest with a **directory pathspec**, never a
hand-built list of filenames:

```bash
# `:(top)` = pathspec from the REPO ROOT, so this works from any cwd.
git add -A ':(top).agents/TODO'
git commit -m "[todo] Lint: move N done, N closed, N backlog, archive M, regenerate INDEX"
git status --short          # MUST be clean for .agents/TODO afterwards
```

**Why this exact form** — the same silent-drop has now bitten **three** consecutive runs, by
two different routes, and both end identically: `git add` fails, stages **nothing**, the shell
moves on, and the commit lands with only the `git mv` rename — silently dropping the
regenerated `INDEX.md`. The commit's own exit code is 0, so nothing signals the loss.

1. **Enumerated filenames** include a file's **pre-rename** path, which no longer exists after
   `git mv` → bad pathspec, whole `add` fails.
2. **A relative directory pathspec** (`git add -A .agents/TODO`) resolves against the **current
   working directory**. Run from inside `.agents/TODO/` it becomes
   `.agents/TODO/.agents/TODO` — nonexistent, same silent failure.

`:(top)` anchors the pathspec to the repository root, which defeats both.

**Always run `git status --short` after committing** and confirm no `.agents/TODO/` file is
left modified or staged. A clean commit exit code is not proof the commit contained what you
intended. If something was dropped, make a **second** commit — do not amend.

### 7. Report

```
Lint Complete
─────────────
Active: N | In Progress: N | Backlog: N | Done: N | Closed: N | Archived: N
INDEX.md: regenerated · REVIEW-QUEUE links: all resolve
```
