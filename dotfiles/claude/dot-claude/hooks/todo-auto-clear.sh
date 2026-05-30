#!/bin/bash
# Hook: Auto-clear context between tasks in TODO work loop
# Triggered by: PostToolUse (Write|Edit|Bash matcher)
#
# Detects when the agent writes clear-pending: true to .work-state,
# indicating a task transition in auto-clear mode. Removes the sentinel,
# kills Claude, and relaunches with the continuation prompt via tmux
# send-keys so the new process inherits the shell environment.
#
# Triggers on Write/Edit to .work-state OR Bash commands that mention
# .work-state (e.g., `cat > .work-state`, `sed -i ... .work-state`,
# `tee .work-state`). The actual sentinel check below is the source of
# truth — Bash commands that touch .work-state but don't set
# clear-pending: true exit cleanly without acting.

LOG="$HOME/.claude/hook-debug.log"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
WORK_STATE="$PROJECT_DIR/.agents/TODO/.work-state"

# Read JSON from stdin to check which file/command was used
json=$(cat)
file_path=$(echo "$json" | jq -r '.tool_input.file_path // empty')
command=$(echo "$json" | jq -r '.tool_input.command // empty')

# Only act on tool calls that could have touched .work-state
touches_work_state=0
if [[ "$file_path" == *".agents/TODO/.work-state" ]]; then
  touches_work_state=1
elif [[ "$command" == *".agents/TODO/.work-state"* ]] || [[ "$command" == *".work-state"* ]]; then
  touches_work_state=1
fi

if [[ "$touches_work_state" != "1" ]]; then
  exit 0
fi

echo "[$(date -Iseconds)] auto-clear: tool touched .work-state (via $([ -n "$file_path" ] && echo "Write/Edit" || echo "Bash"))" >> "$LOG"

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
CLAUDE_PID="$PPID"
kill "$CLAUDE_PID"

# 6. Wait until the OS has actually reaped Claude. kill -0 returns success
#    while the PID still exists. Bound the wait to ~3s; after that we proceed
#    anyway and let the next checks catch any residual badness.
for _ in $(seq 1 30); do
  kill -0 "$CLAUDE_PID" 2>/dev/null || break
  sleep 0.1
done
if kill -0 "$CLAUDE_PID" 2>/dev/null; then
  echo "[$(date -Iseconds)] auto-clear: Claude PID=$CLAUDE_PID still alive after 3s wait" >> "$LOG"
fi

# 7. Wait until the pane's foreground process is no longer 'claude' — i.e.,
#    the parent shell has actually regained control of the pty. Bound to ~5s.
#    Polling pane_current_command (rather than a fixed sleep) avoids the race
#    where send-keys arrives before readline is ready.
for _ in $(seq 1 50); do
  current=$(tmux display-message -p -t "$PANE_ID" '#{pane_current_command}' 2>/dev/null)
  if [ -n "$current" ] && [ "$current" != "claude" ]; then
    break
  fi
  sleep 0.1
done
echo "[$(date -Iseconds)] auto-clear: pane $PANE_ID foreground is now '$current'" >> "$LOG"

# 8. Send the wrapper path and Enter as TWO separate send-keys calls with a
#    small gap. A single burst of "<path>\n" can be picked up by readline's
#    bracketed-paste handler, which inserts the newline as a literal char
#    instead of executing the line. Splitting them keeps each keystroke
#    distinct.
tmux send-keys -t "$PANE_ID" -l "$WRAPPER"
sleep 0.2
tmux send-keys -t "$PANE_ID" Enter

echo "[$(date -Iseconds)] auto-clear: restart command sent via wrapper" >> "$LOG"

exit 0
