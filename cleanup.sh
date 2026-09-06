#!/usr/bin/env bash
# OpenClaw Portable v7 - zero-trace cleanup (issue #43: safe to unmount)
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="$SCRIPT_DIR/data"
STATE_DIR="$DATA_DIR/.openclaw"

echo
echo "=========================================="
echo "  OpenClaw Portable v7 - Cleanup"
echo "=========================================="
echo

echo "[Scan] Checking for user data and sensitive files..."
HAS=0
[ -d "$STATE_DIR" ] && { echo "  [!] data/.openclaw (config incl. API keys, sessions, auth)"; HAS=1; }
[ -d "$DATA_DIR/workspace" ] && { echo "  [!] data/workspace (agent workspace files)"; HAS=1; }
[ -f "$DATA_DIR/gateway.log" ] && { echo "  [!] data/gateway.log (runtime log)"; HAS=1; }
[ -f "$DATA_DIR/ollama.log" ] && { echo "  [!] data/ollama.log (runtime log)"; HAS=1; }

if [ "$HAS" = "0" ]; then
  echo
  echo "[OK] No user data found. Safe to unmount."
  exit 0
fi

echo
echo "Choose cleanup level:"
echo "  [1] Light  - logs only"
echo "  [2] Deep   - ALL user data (API keys, sessions, workspace)"
echo "  [3] Cancel"
read -r -p "Choice (1-3): " CHOICE

case "$CHOICE" in
  1)
    echo "[Cleaning] Logs..."
    rm -f "$DATA_DIR/gateway.log" "$DATA_DIR/ollama.log"
    echo "[Done] Light cleanup - config and sessions preserved."
    ;;
  2)
    read -r -p "Deep cleanup removes ALL config incl. API keys. Confirm? (yes/N): " CONFIRM
    if [ "$CONFIRM" = "yes" ] || [ "$CONFIRM" = "YES" ]; then
      echo "[Cleaning] All user data..."
      rm -rf "$STATE_DIR" "$DATA_DIR/workspace"
      rm -f "$DATA_DIR/gateway.log" "$DATA_DIR/ollama.log"
      echo "[Done] Deep cleanup - next start regenerates config fresh."
    fi
    ;;
  *)
    echo "[Cancelled]"
    ;;
esac

echo
echo "[OK] Cleanup complete. Safe to unmount."
echo "    (data/ollama-models and the bundled model are public model files - kept.)"
