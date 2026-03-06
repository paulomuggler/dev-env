#!/bin/bash
# Hook: Prevent stopping when work loop is active and phases are incomplete
# Triggered by: Stop event
#
# Blocks stopping when:
# - phase: executing → "Haven't verified yet"
# - phase: verify → "Verification in progress"
# - phase: planning → "Still planning"
# - phase: complete → "Completion in progress"
#
# Instance scoping: only blocks the instance that owns the work state (by PID).
# Crash resilience: if the owning process is dead, approves immediately.
#
# Safety valve: after MAX_RETRIES blocks, allows stop to prevent infinite loops.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
WORK_STATE="$PROJECT_DIR/.agents/TODO/.work-state"
RETRY_FILE="$PROJECT_DIR/.claude/todo-loop-retries"
MAX_RETRIES=5

# No work state → approve
if [ ! -f "$WORK_STATE" ]; then
  echo '{"decision": "approve"}'
  exit 0
fi

# Instance scoping: check if this instance owns the work state
STATE_PID=$(grep '^pid:' "$WORK_STATE" | cut -d' ' -f2)
if [ -n "$STATE_PID" ]; then
  # If the owning process is dead (crashed/restarted), approve immediately
  if ! kill -0 "$STATE_PID" 2>/dev/null; then
    echo '{"decision": "approve"}'
    exit 0
  fi
  # If a different live instance owns the work state, don't block
  if [ "$STATE_PID" != "$PPID" ]; then
    echo '{"decision": "approve"}'
    exit 0
  fi
fi

MODE=$(grep '^mode:' "$WORK_STATE" | cut -d' ' -f2)

# Not in a work mode → approve
case "$MODE" in
  loop|P0|P1|P2|P3|P4|P5) ;;
  *)
    echo '{"decision": "approve"}'
    exit 0
    ;;
esac

PHASE=$(grep '^phase:' "$WORK_STATE" | cut -d' ' -f2)
TASK=$(grep '^task:' "$WORK_STATE" | cut -d' ' -f2)

# No task set (between tasks) → approve
if [ -z "$TASK" ]; then
  echo '{"decision": "approve"}'
  exit 0
fi

# Check retry counter (safety valve)
RETRIES=0
if [ -f "$RETRY_FILE" ]; then
  RETRIES=$(cat "$RETRY_FILE" 2>/dev/null || echo 0)
fi

if [ "$RETRIES" -ge "$MAX_RETRIES" ]; then
  # Safety valve: reset counter and allow stop
  rm -f "$RETRY_FILE"
  echo '{"decision": "approve"}'
  exit 0
fi

# Increment retry counter
echo $((RETRIES + 1)) > "$RETRY_FILE"

# Block based on phase
REASON=""
case "$PHASE" in
  executing)
    REASON="Task execution not verified. Transition to verify phase before marking done. Update .work-state phase to 'verify' and run the verify procedure for task '$TASK'."
    ;;
  verify)
    REASON="Verification in progress. Complete all verify plan items in .agents/TODO/$TASK.md before stopping."
    ;;
  planning)
    REASON="Still in planning phase. Continue planning or ExitPlanMode before stopping."
    ;;
  complete)
    REASON="Completion in progress. Writing work report and marking task done. Finish the complete phase for task '$TASK'."
    ;;
  *)
    # Unknown phase → approve
    rm -f "$RETRY_FILE"
    echo '{"decision": "approve"}'
    exit 0
    ;;
esac

ESCAPED=$(printf '%s' "$REASON" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')

cat <<EOF
{
  "decision": "block",
  "reason": $ESCAPED
}
EOF
