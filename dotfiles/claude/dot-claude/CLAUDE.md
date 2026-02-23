# Agent Work Discipline

## Task Tracking (Automatic)

All projects use a file-based task tracking system at `.agents/TODO/`. You MUST use this
system automatically — users should not need to invoke `/todo` for it to be followed.

### When a user gives you a substantial prompt:

1. **Check for existing work state:** Read `.agents/TODO/.work-state` — if it exists, you are
   mid-task. Resume it.

2. **Assess the request:**
   - Is this a new task (feature, bug fix, refactor, investigation)?
     → Check `.agents/TODO/INDEX.md` for related existing tasks
     → If no match: create a task file, then follow the work protocol
     → If a related pending/backlog task exists: pick it up and follow the work protocol
   - Is this iterating on recently completed work?
     → Reopen the task file (set status back to in-progress), update context, continue
   - Is this a trivial/quick action (typo fix, single-line change, question)?
     → Just do it. No task file needed.

3. **Follow the work protocol:** plan → execute → verify → complete. Every non-trivial task
   goes through all 4 phases.

### Use judgment. The threshold is:
- **Needs a task:** Multi-file changes, new features, bug fixes requiring investigation,
  refactors, anything taking more than a few minutes
- **Skip task tracking:** Single-line fixes, answering questions, trivial formatting,
  exploration/research that won't produce code changes

## Coding Standards

When writing or modifying code, check `.claude/standards.yaml` for this project's applicable
standards and lifecycle stage. Always read `~/.claude/coding-standards/principles.md` first —
it defines the project's error philosophy, defensive coding posture, and deprecation policy
based on the lifecycle stage. Then load relevant files from `~/.claude/coding-standards/languages/`
and `~/.claude/coding-standards/frameworks/`. Record which files you consulted in work reports.
If a guide is missing for a language or framework you're using, create it and update the
project's `standards.yaml`.

## Git Commit Discipline

- **Separate commit streams:** Never mix code changes with task tracking changes in the same commit.
  - Code commits: project source files only. Concise messages explaining *why*.
  - Task tracking commits: `.agents/TODO/` files only. Prefix with `[todo]`.
- Commit after each logical unit of work — do not accumulate changes
- Commit immediately when a task reaches the complete phase
- Stage specific files, never `git add -A` blindly
- Never push unless explicitly asked
- Never amend unless explicitly asked
