---
description: Implement AI prompts marked with # AI: comments in a file
argument-hint: <file-path>
allowed-tools: Read, Edit, Grep
---

# Implement AI Prompts

You are implementing changes requested via inline `# AI:` comment markers.

**File to process:** `$ARGUMENTS`

**Your task:**
1. Read the file at `$ARGUMENTS`
2. Find all lines containing `# AI:` markers (case-insensitive)
3. Extract the prompts and their line numbers/context
4. Implement each requested change in place
5. Preserve the file's structure, style, and existing code
6. Remove or comment out the `# AI:` markers after implementation

**Marker syntax examples:**
```bash
# AI: Add error handling here
# AI: Refactor this to use arrays instead of string splitting
# ai: Add logging before this function call
```

**Important:**
- Maintain code quality and consistency with existing patterns
- If a prompt is unclear or impossible, ask for clarification instead of guessing
- Preserve indentation, spacing, and coding style
- Test that your changes are syntactically correct

Now process the file and implement the requested changes.
