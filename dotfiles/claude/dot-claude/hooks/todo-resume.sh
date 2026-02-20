#!/bin/bash
# Hook: Re-inject /todo work protocol after context compaction
# Triggered by: SessionStart (with compact matcher)
#
# Problem: After compaction, the full SKILL.md instructions are lost.
# Solution: Cat the actual SKILL.md + current state into the message.
# No lossy hand-maintained summary — the source of truth is SKILL.md itself.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
WORK_STATE="$PROJECT_DIR/.agents/TODO/.work-state"

if [ ! -f "$WORK_STATE" ]; then
  echo '{"decision": "approve"}'
  exit 0
fi

TASK=$(grep '^task:' "$WORK_STATE" | cut -d' ' -f2)
PHASE=$(grep '^phase:' "$WORK_STATE" | cut -d' ' -f2)
MODE=$(grep '^mode:' "$WORK_STATE" | cut -d' ' -f2)

if [ -z "$TASK" ]; then
  echo '{"decision": "approve"}'
  exit 0
fi

# Read task title
TASK_FILE="$PROJECT_DIR/.agents/TODO/$TASK.md"
TASK_TITLE=""
if [ -f "$TASK_FILE" ]; then
  TASK_TITLE=$(grep '^title:' "$TASK_FILE" | sed 's/^title: *//')
fi

# Find the plan file if in executing phase
PLAN_HINT=""
if [ "$PHASE" = "executing" ]; then
  PLANS_DIR="$HOME/.claude/plans"
  for f in "$PLANS_DIR"/*.md; do
    [ -f "$f" ] || continue
    if head -1 "$f" | grep -q "^# Plan: $TASK"; then
      PLAN_HINT="Plan file: $f — re-read it before continuing execution."
      break
    fi
  done
fi

# Add verify hint if in verify phase
VERIFY_HINT=""
if [ "$PHASE" = "verify" ]; then
  VERIFY_HINT="Read the task file's ## Verify Plan section and continue checking off items."
fi

# Add complete hint if in complete phase
COMPLETE_HINT=""
if [ "$PHASE" = "complete" ]; then
  COMPLETE_HINT="Write the work report, mark the task done, run lint, and commit."
fi

# Read the full SKILL.md — this is the single source of truth
SKILL_FILE="$HOME/.claude/skills/todo/SKILL.md"
SKILL_CONTENT=""
if [ -f "$SKILL_FILE" ]; then
  SKILL_CONTENT=$(cat "$SKILL_FILE")
fi

# Build the directive: current state + full skill protocol
DIRECTIVE="## /todo Work Protocol (re-injected after context compaction)

You are resuming in-progress /todo work. The full skill protocol is included below.

### Current State
- **Task:** $TASK ($TASK_TITLE)
- **Phase:** $PHASE
- **Mode:** $MODE
- **Task file:** .agents/TODO/$TASK.md"

if [ -n "$PLAN_HINT" ]; then
  DIRECTIVE="$DIRECTIVE
- $PLAN_HINT"
fi

if [ -n "$VERIFY_HINT" ]; then
  DIRECTIVE="$DIRECTIVE
- $VERIFY_HINT"
fi

if [ -n "$COMPLETE_HINT" ]; then
  DIRECTIVE="$DIRECTIVE
- $COMPLETE_HINT"
fi

DIRECTIVE="$DIRECTIVE

### Resume Instructions
- Read \`.agents/TODO/$TASK.md\` for full task context and acceptance criteria
- If phase is \`planning\`: continue exploring and writing the plan, then ExitPlanMode
- If phase is \`executing\`: re-read the plan file, then continue implementing
- If phase is \`verify\`: read the task file's Verify Plan section and continue checking off items
- If phase is \`complete\`: write the work report, mark the task done, run lint, and commit

### Full /todo Skill Protocol
$SKILL_CONTENT"

# Escape for JSON
ESCAPED=$(echo "$DIRECTIVE" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')

cat <<EOF
{
  "decision": "approve",
  "message": $ESCAPED
}
EOF
