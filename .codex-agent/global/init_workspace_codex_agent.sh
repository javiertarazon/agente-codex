#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-$PWD}"
SRC_DIR="/home/javie/.codex/agent-global"
DST_DIR="${TARGET_DIR%/}/.codex-agent"

mkdir -p "$DST_DIR"

for f in start_chrome_cdp.ps1 chrome_cdp.ps1; do
  if [ -f "$SRC_DIR/$f" ] && [ ! -f "$DST_DIR/$f" ]; then
    cp "$SRC_DIR/$f" "$DST_DIR/$f"
  fi
done

if [ ! -f "$DST_DIR/tasks.yaml" ]; then
  cat > "$DST_DIR/tasks.yaml" << 'YAML'
{
  "version": 1,
  "tasks": []
}
YAML
fi

if [ ! -f "$DST_DIR/audit-log.jsonl" ]; then
  : > "$DST_DIR/audit-log.jsonl"
fi

echo "Initialized: $DST_DIR"
