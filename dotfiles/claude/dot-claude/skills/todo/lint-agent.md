# TODO Lint Agent

Maintain the `.agents/TODO/` file hierarchy: move done tasks, archive old ones, regenerate INDEX.md.

---

## Procedure

### 1. Move Done Tasks

Glob `.agents/TODO/*.md` (exclude `INDEX.md`). Read frontmatter only. Any file with `status: done` → move to `.agents/TODO/done/`. Create `done/` if needed.

### 1b. Move Backlog Tasks

Glob `.agents/TODO/*.md` (exclude `INDEX.md`). Read frontmatter only. Any file with `status: backlog` → move to `.agents/TODO/backlog/`. Create `backlog/` if needed.

Also check the reverse: glob `.agents/TODO/backlog/*.md`. Any file whose status is NOT `backlog` (e.g., promoted to `pending`) → move back to `.agents/TODO/`.

### 1c. Move Closed Tasks

Glob `.agents/TODO/*.md` (exclude `INDEX.md`) and `.agents/TODO/backlog/*.md`. Read frontmatter only. Any file with `status: closed` → move to `.agents/TODO/closed/`. Create `closed/` if needed.

### 2. Auto-Archive

Glob `.agents/TODO/done/*.md`. Read frontmatter only. Move to `.agents/TODO/archive/done/YYYY-MM-DD/` when:
- Task's `updated` timestamp is >24h ago (use only the **date portion** — first 10 chars — of `updated` for the archive folder name; the `_HH:mm` suffix is dropped)
- If `done/` count exceeds 30, archive oldest by `updated` until count is ≤30

Glob `.agents/TODO/closed/*.md`. Read frontmatter only. Move to `.agents/TODO/archive/closed/YYYY-MM-DD/` when:
- Task's `updated` timestamp is >24h ago (use only the **date portion** of `updated` for the archive folder name)
- If `closed/` count exceeds 30, archive oldest by `updated` until count is ≤30

Note: `updated` may be in either `YYYY-MM-DD` (legacy) or `YYYY-MM-DD_HH:mm` (current) format. Both sort and compare lexicographically; truncate to 10 chars for folder names.

Create archive directories with `mkdir -p`.

### 3. Regenerate INDEX.md

Read frontmatter from all active tasks (`.agents/TODO/*.md`, exclude INDEX.md), backlog tasks (`backlog/*.md`), done tasks (`done/*.md`, not archived), and closed tasks (`closed/*.md`, not archived). Group by status, sort by priority (P0 first) then `created` timestamp (oldest first; lexicographic string compare tolerates both date-only and date_time formats).

Write `.agents/TODO/INDEX.md`:

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

Only include priority sub-headings and status sections that have tasks.

### 4. Commit

Stage only `.agents/TODO/` files:
```
[todo] Lint: move N done, N closed, N backlog, archive M, regenerate INDEX
```

### 5. Report

```
Lint Complete
─────────────
Active: N | Backlog: N | Done: N | Closed: N | Archived: N
INDEX.md: regenerated
```
