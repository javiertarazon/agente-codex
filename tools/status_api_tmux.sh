#!/usr/bin/env bash
set -euo pipefail
SESSION_NAME="${SESSION_NAME:-agente-codex-api}"
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  echo "SESSION: $SESSION_NAME (running)"
  tmux capture-pane -t "$SESSION_NAME" -p | tail -n 30
else
  echo "SESSION: $SESSION_NAME (stopped)"
fi
