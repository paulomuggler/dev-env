# TODO Lint Agent

Maintain the `.agents/TODO/` file hierarchy: move done tasks, archive old ones, regenerate INDEX.md.

---

## Procedure

### 1. Move Done Tasks

Glob `.agents/TODO/*.md` (exclude `INDEX.md`). Read frontmatter only. Any file with `status: done` → move to `.agents/TODO/done/`. Create `done/` if needed.

### 2. Auto-Archive

Glob `.agents/TODO/done/*.md`. Read frontmatter only. Move to `.agents/TODO/archive/done/YYYY-MM-DD/` when:
- Task's `updated` date is >24h ago (use `updated` date for archive folder name)
- If `done/` count exceeds 30, archive oldest by `updated` until count is ≤30

Create archive directories with `mkdir -p`.

### 3. Regenerate INDEX.md

Read frontmatter from all active tasks (`.agents/TODO/*.md`, exclude INDEX.md) and done tasks (`done/*.md`, not archived). Group by status, sort by priority (P0 first) then `created` date (oldest first).

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

## Backlog (N)

### P3 - Low
- [-] [slug](slug.md) - Title
```

Only include priority sub-headings and status sections that have tasks.

### 4. Commit

Stage only `.agents/TODO/` files:
```
[todo] Lint: move N done, archive M, regenerate INDEX
```

### 5. Report

```
Lint Complete
─────────────
Active: N | Done: N | Archived: N
INDEX.md: regenerated
```
