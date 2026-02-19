#!/usr/bin/env bash
set -euo pipefail
SESSION_NAME="${SESSION_NAME:-agente-codex-api}"
PORT="${PORT:-8787}"
HOST="${HOST:-127.0.0.1}"
MODEL="${MODEL:-openai/gpt-5-codex}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TOKEN="${GITHUB_TOKEN:-${1:-}}"

if [[ -z "${TOKEN}" ]]; then
  echo "ERROR: Falta token. Usa:"
  echo "  GITHUB_TOKEN=tu_token ./tools/start_api_tmux.sh"
  echo "o"
  echo "  ./tools/start_api_tmux.sh tu_token"
  exit 2
fi

if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
  tmux kill-session -t "$SESSION_NAME"
fi

tmux new-session -d -s "$SESSION_NAME" -c "$REPO_DIR"
tmux set-environment -t "$SESSION_NAME" GITHUB_TOKEN "$TOKEN"
tmux set-environment -t "$SESSION_NAME" PORT "$PORT"
tmux set-environment -t "$SESSION_NAME" HOST "$HOST"
tmux set-environment -t "$SESSION_NAME" MODEL "$MODEL"
tmux send-keys -t "$SESSION_NAME" 'python3 tools/github_models_proxy.py' C-m
sleep 1

tmux capture-pane -t "$SESSION_NAME" -p | tail -n 20

echo "OK: API local activa en http://$HOST:$PORT/chat (sesión tmux: $SESSION_NAME)"
