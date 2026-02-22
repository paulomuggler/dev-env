# TODO Lint Agent Instructions

You are running the lint procedure for the `.agents/TODO/` task tracking system. This validates all task files, auto-archives old done tasks, and regenerates INDEX.md.

---

## Procedure

### 1. File Discovery

- Glob `.agents/TODO/*.md` (exclude `INDEX.md`) to find all active task files
- Glob `.agents/TODO/done/*.md` for done-reference checking

### 2. Validate Each Active Task File

Parse YAML frontmatter (between `---` delimiters) and check:

a. **Required fields present:** `slug`, `title`, `priority`, `status`, `created`, `updated`, `depends-on`, `tags`
b. **Slug matches filename** — `slug` value must equal the filename without `.md`
c. **Priority valid** — one of: `P0`, `P1`, `P2`, `P3`, `P4`, `P5`
d. **Status valid** — one of: `pending`, `in-progress`, `blocked`, `done`, `backlog`
e. **Dependencies exist** — each entry in `depends-on` references an existing task slug (active or done)
f. **No circular dependencies** — DFS cycle detection across all tasks
g. **No duplicate slugs** across all active task files
h. **Warn** if >50 active task files

Report any errors or warnings found.

### 3. Auto-Archive Done Tasks

Move tasks from `.agents/TODO/done/` to `.agents/TODO/archive/done/YYYY-MM-DD/` when:
- Task's `updated` date is >24h ago (use the task's `updated` date for the archive folder name)
- If count of done tasks in `.agents/TODO/done/` exceeds 30, archive the oldest ones (by `updated` date) until count is ≤30

Create the archive date directories as needed (`mkdir -p`).

### 4. Regenerate INDEX.md

Read all active task files + done/ tasks (not archived). Group by status. Sort pending and backlog by priority then by created date (oldest first).

Write `.agents/TODO/INDEX.md` with this format:

```markdown
# TODO Index
> Auto-generated from task files. Run `/todo lint` to regenerate.

## Pending (N)

### P0 - Critical
- [ ] [slug](slug.md) - Title

### P1 - High
- [ ] [slug](slug.md) - Title

### P2 - Normal
- [ ] [slug](slug.md) - Title

### P3 - Low
- [ ] [slug](slug.md) - Title

### P4 - Someday
- [ ] [slug](slug.md) - Title

### P5 - Wishlist
- [ ] [slug](slug.md) - Title

## In Progress (N)
- [~] [slug](slug.md) - Title

## Blocked (N)
- [!] [slug](slug.md) - Title (blocked by: dep1, dep2)

## Done (N)
- [x] [slug](slug.md) - Title

## Backlog (N)

### P2 - Normal
- [-] [slug](slug.md) - Title

### P3 - Low
- [-] [slug](slug.md) - Title
```

- Only include priority sub-headings that have tasks
- Counts in section headers reflect actual task count for that status
- Omit empty status sections entirely

### 5. Commit

Stage only `.agents/TODO/` files and commit with `[todo]` prefix:
```
[todo] Lint: validate N tasks, archive M done, regenerate INDEX
```

### 6. Report

Output a summary:
```
Lint Complete
─────────────
Active tasks: N
Errors: N
Warnings: N
Archived: N done tasks
INDEX.md: regenerated
```
