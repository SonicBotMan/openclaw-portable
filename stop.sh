#!/usr/bin/env bash
# OpenClaw Portable v7 - stop (only processes from THIS portable tree)
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE="$SCRIPT_DIR/node/node"

echo
echo "=========================================="
echo "  OpenClaw Portable v7 - Stopping"
echo "=========================================="
echo

if [ ! -x "$NODE" ]; then
  echo "[WARN] node/node not found - cannot run the stop helper."
  exit 1
fi

echo "[1/2] Stopping gateway + Ollama ..."
"$NODE" "$SCRIPT_DIR/scripts/stop.js" "$SCRIPT_DIR"

echo "[2/2] Verifying ports are released..."
VERIFY_FAIL=0
for p in 18789 18790 11434 11435; do
  if (exec 3<>/dev/tcp/127.0.0.1/"$p") 2>/dev/null; then
    exec 3>&- 2>/dev/null || true
    echo "[WARN] Port $p is still in use."
    VERIFY_FAIL=1
  fi
done
if [ "$VERIFY_FAIL" = "0" ]; then
  echo "[OK]   All ports released."
fi

echo
echo "=========================================="
echo "  OpenClaw stopped."
echo "  data/ (config, sessions, model store) preserved."
echo "  Use ./cleanup.sh to remove API keys before unmounting."
echo "=========================================="
