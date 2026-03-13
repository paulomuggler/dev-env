#!/bin/bash
# Hook: Auto-clear context between tasks in TODO work loop
# Triggered by: PostToolUse (Write|Edit matcher)
#
# Detects when the agent writes clear-pending: true to .work-state,
# indicating a task transition in auto-clear mode. Removes the sentinel,
# writes an auto-prompt transport file, kills Claude, and relaunches
# via tmux send-keys so the new process inherits the shell environment.

LOG="$HOME/.claude/hook-debug.log"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
WORK_STATE="$PROJECT_DIR/.agents/TODO/.work-state"
AUTO_PROMPT="$PROJECT_DIR/.agents/TODO/.auto-prompt"

# Read JSON from stdin to check which file was written
json=$(cat)
file_path=$(echo "$json" | jq -r '.tool_input.file_path // empty')

# Only act on writes to .work-state
if [[ "$file_path" != *".agents/TODO/.work-state" ]]; then
  exit 0
fi

echo "[$(date -Iseconds)] auto-clear: Write to .work-state detected" >> "$LOG"

# Check if the file exists and contains clear-pending
if [ ! -f "$WORK_STATE" ]; then
  echo "[$(date -Iseconds)] auto-clear: .work-state does not exist on disk" >> "$LOG"
  exit 0
fi

if ! grep -q '^clear-pending: true' "$WORK_STATE"; then
  echo "[$(date -Iseconds)] auto-clear: no clear-pending sentinel found" >> "$LOG"
  exit 0
fi

# Instance scoping: only act if this instance owns the work state
STATE_PID=$(grep '^pid:' "$WORK_STATE" | cut -d' ' -f2)
if [ -n "$STATE_PID" ] && [ "$STATE_PID" != "$PPID" ]; then
  echo "[$(date -Iseconds)] auto-clear: PID mismatch (state=$STATE_PID, ours=$PPID), skipping" >> "$LOG"
  exit 0
fi

# Require tmux — this mechanism depends on it
if [ -z "$TMUX" ]; then
  echo "[$(date -Iseconds)] auto-clear: not running in tmux, cannot restart" >> "$LOG"
  exit 0
fi

echo "[$(date -Iseconds)] auto-clear: clear-pending detected, initiating restart" >> "$LOG"

# 1. Remove clear-pending from .work-state
sed -i '/^clear-pending: true$/d' "$WORK_STATE"

# 2. Read next task slug for the prompt
TASK=$(grep '^task:' "$WORK_STATE" | cut -d' ' -f2)
MODE=$(grep '^mode:' "$WORK_STATE" | cut -d' ' -f2)

# 3. Write auto-prompt transport file
cat > "$AUTO_PROMPT" <<PROMPT
Resume /todo work $MODE — pick up task $TASK (auto-clear mode, fresh context).
PROMPT

echo "[$(date -Iseconds)] auto-clear: wrote auto-prompt for task=$TASK mode=$MODE" >> "$LOG"

# 4. Get current tmux pane before killing Claude
PANE_ID=$(tmux display-message -p '#{pane_id}')

echo "[$(date -Iseconds)] auto-clear: killing Claude (PID=$PPID), will restart in pane=$PANE_ID" >> "$LOG"

# 5. Kill Claude — shell regains control of the pane
kill "$PPID"

# 6. Wait for shell to be ready
sleep 0.5

# 7. Type 'claude' into the shell via tmux
tmux send-keys -t "$PANE_ID" "claude" Enter

echo "[$(date -Iseconds)] auto-clear: restart command sent" >> "$LOG"

exit 0
