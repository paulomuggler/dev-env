#!/bin/bash
# Hook: Auto-approve ExitPlanMode if plan matches current TODO task
# Triggered by: PermissionRequest (ExitPlanMode)
#
# Validation: Plan file must start with "# Plan: {task-slug}" matching
# the task in .agents/TODO/.work-state

LOG="$HOME/.claude/hook-debug.log"
ASK='{"hookSpecificOutput": {"hookEventName": "PermissionRequest", "decision": {"behavior": "ask"}}}'

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
WORK_STATE="$PROJECT_DIR/.agents/TODO/.work-state"
PLANS_DIR="$HOME/.claude/plans"

echo "[$(date -Iseconds)] Hook invoked, PROJECT_DIR=$PROJECT_DIR" >> "$LOG"

# If no active work state, ask user for approval
if [ ! -f "$WORK_STATE" ]; then
  echo "[$(date -Iseconds)] No work state file at $WORK_STATE" >> "$LOG"
  echo "$ASK"
  exit 0
fi

# Get task slug from work state
TASK=$(grep '^task:' "$WORK_STATE" | cut -d' ' -f2)

if [ -z "$TASK" ]; then
  echo "[$(date -Iseconds)] No task in work state" >> "$LOG"
  echo "$ASK"
  exit 0
fi

echo "[$(date -Iseconds)] Looking for plan matching task=$TASK" >> "$LOG"

# Search ALL plan files for the matching header (not just most recent)
PLAN_FILE=""
for f in "$PLANS_DIR"/*.md; do
  [ -f "$f" ] || continue
  if head -1 "$f" | grep -q "^# Plan: $TASK"; then
    PLAN_FILE="$f"
    break
  fi
done

# Fallback: most recently modified plan file
if [ -z "$PLAN_FILE" ]; then
  PLAN_FILE=$(ls -t "$PLANS_DIR"/*.md 2>/dev/null | head -1)
  echo "[$(date -Iseconds)] No exact match, falling back to most recent: $PLAN_FILE" >> "$LOG"
fi

if [ -z "$PLAN_FILE" ]; then
  echo "[$(date -Iseconds)] No plan files found" >> "$LOG"
  echo "$ASK"
  exit 0
fi

# Check if plan file starts with the expected header
if grep -q "^# Plan: $TASK" "$PLAN_FILE"; then
  echo "[$(date -Iseconds)] ALLOW — plan=$PLAN_FILE matches task=$TASK" >> "$LOG"
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PermissionRequest",
    "decision": {
      "behavior": "allow"
    }
  }
}
EOF
else
  echo "[$(date -Iseconds)] ASK — plan header '$(head -1 "$PLAN_FILE")' does not match task=$TASK" >> "$LOG"
  echo "$ASK"
fi
