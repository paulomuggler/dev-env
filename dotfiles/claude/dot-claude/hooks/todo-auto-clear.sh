#!/bin/bash
# Hook: Auto-clear context between tasks in TODO work loop
# Triggered by: PostToolUse (Write|Edit matcher)
#
# Detects when the agent writes clear-pending: true to .work-state,
# indicating a task transition in auto-clear mode. Removes the sentinel,
# kills Claude, and relaunches with the continuation prompt via tmux
# send-keys so the new process inherits the shell environment.

LOG="$HOME/.claude/hook-debug.log"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
WORK_STATE="$PROJECT_DIR/.agents/TODO/.work-state"

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

# 3. Create wrapper script that writes its own PID then exec's claude.
#    exec replaces the wrapper process with claude, preserving the PID.
#    This gives us the exact PID of the new claude instance.
WRAPPER="/tmp/claude-auto-clear-$$.sh"
cat > "$WRAPPER" <<WRAPEOF
#!/bin/bash
sed -i "s/^pid:.*/pid: \$\$/" "$WORK_STATE"
rm -f "$WRAPPER"
exec bash -ic "claude '/todo work $MODE --auto-clear'"
WRAPEOF
chmod +x "$WRAPPER"

# 4. Find the tmux pane where Claude is actually running (not the focused pane).
#    Claude's parent process is the shell in the pane, which matches pane_pid.
CLAUDE_PARENT=$(ps -o ppid= -p "$PPID" | tr -d ' ')
PANE_ID=$(tmux list-panes -a -F '#{pane_id} #{pane_pid}' | awk -v pid="$CLAUDE_PARENT" '$2 == pid {print $1; exit}')

echo "[$(date -Iseconds)] auto-clear: killing Claude (PID=$PPID), will restart in pane=$PANE_ID with prompt for task=$TASK mode=$MODE" >> "$LOG"

# 5. Kill Claude — shell regains control of the pane
kill "$PPID"

# 6. Wait for shell to be ready, then launch wrapper
sleep 0.5
tmux send-keys -t "$PANE_ID" "$WRAPPER" Enter

echo "[$(date -Iseconds)] auto-clear: restart command sent via wrapper" >> "$LOG"

exit 0
