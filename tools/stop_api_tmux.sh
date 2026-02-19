#!/usr/bin/env bash
set -euo pipefail
SESSION_NAME="${SESSION_NAME:-agente-codex-api}"
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  tmux kill-session -t "$SESSION_NAME"
  echo "OK: sesión '$SESSION_NAME' detenida"
else
  echo "INFO: no existía la sesión '$SESSION_NAME'"
fi
