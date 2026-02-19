#!/usr/bin/env bash
set -euo pipefail
PORT="${PORT:-8787}"
HOST="${HOST:-127.0.0.1}"
MODEL="${MODEL:-openai/gpt-5-codex}"
PROMPT="${*:-Di hola y confirma que la API local funciona}"

curl -sS -X POST "http://$HOST:$PORT/chat"   -H "Content-Type: application/json"   -d "{"model":"$MODEL","prompt":"$PROMPT"}" | python3 -m json.tool
