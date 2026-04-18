# Refine Notes Procedure

Process human validation notes left on done tasks. Two modes:

## Mode: Interactive (default)

Walk through each done task that has unprocessed notes, one at a time:

1. **Scan**: Glob `.agents/TODO/done/*.md`, read each file looking for `## Human Validation` sections that contain `[NOTE:` markers or unchecked items (`- [ ]`).
2. **Present**: For each task with notes, show:
   - Task title and slug
   - Each note/question, one at a time
   - Any design decisions that have `[NOTE:` annotations
3. **Discuss**: For each note, engage interactively:
   - Answer questions the user left
   - Discuss design considerations
   - Propose follow-up tasks if the note implies work
4. **Resolve**: After discussing, either:
   - Create follow-up task(s) from the note
   - Mark the note as addressed (remove `[NOTE:` or check the box)
   - Leave it if the user wants to defer
5. **Commit**: After processing a task's notes, commit the task file changes with `[todo]` prefix

## Mode: Autonomous (`refine auto`)

Process all notes without interaction — generate follow-up tasks for anything that implies work, answer questions inline, close out notes. Report summary at the end.

## Note Detection

Notes appear in these forms:
- `[NOTE: ...]` inline annotations on design decisions or validation checks
- Unchecked `- [ ]` items in Human Validation that have text annotations
- Questions ending in `?` within note blocks
- Any text the user added after the agent-generated content in Human Validation or Design Decisions sections
