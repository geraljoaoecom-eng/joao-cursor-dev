#!/bin/zsh
# Usage: ./dev.sh <project-dir> [port]
# Example: ./dev.sh spy-ecom 5173
set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <project-dir> [port]" >&2
  exit 1
fi

PROJECT_DIR="$1"
PORT="${2:-}"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "[error] Directory '$PROJECT_DIR' not found in $(pwd)" >&2
  exit 1
fi

# Pick a free port if none provided (scan from 5173)
if [ -z "${PORT}" ]; then
  START=5173
  END=6000
  for p in $(seq $START $END); do
    if ! lsof -i :$p >/dev/null 2>&1; then
      PORT=$p
      break
    fi
  done
  if [ -z "${PORT}" ]; then
    echo "[error] No free port found between $START-$END" >&2
    exit 1
  fi
fi

cd "$PROJECT_DIR"

echo "[info] Serving $(pwd) at http://127.0.0.1:$PORT (live reload)"
exec npx -y live-server --port=$PORT --no-browser --watch=.
