#!/bin/bash
# Hook: Inject auto-prompt on fresh session start for auto-clear work loop
# Triggered by: SessionStart (no matcher — fires on every fresh start)
#
# Reads the .auto-prompt transport file left by the auto-clear hook,
# injects it as a message into the new Claude session, and deletes
# the transport file so it only fires once.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
AUTO_PROMPT="$PROJECT_DIR/.agents/TODO/.auto-prompt"
LOG="$HOME/.claude/hook-debug.log"

# No transport file → no-op
if [ ! -f "$AUTO_PROMPT" ]; then
  echo '{"decision": "approve"}'
  exit 0
fi

echo "[$(date -Iseconds)] auto-start: found auto-prompt, injecting" >> "$LOG"

# Read the prompt and delete the file
PROMPT=$(cat "$AUTO_PROMPT")
rm -f "$AUTO_PROMPT"

# Escape for JSON
ESCAPED=$(printf '%s' "$PROMPT" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')

echo "[$(date -Iseconds)] auto-start: injected prompt, deleted transport file" >> "$LOG"

cat <<EOF
{
  "decision": "approve",
  "message": $ESCAPED
}
EOF
