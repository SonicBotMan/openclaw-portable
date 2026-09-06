#!/usr/bin/env bash
# ============================================
#  OpenClaw Portable v7 - one-click start (Linux/mac)
#
#  Runs from any filesystem (USB stick or plain folder) - no
#  USB detection, no admin rights, nothing installed outside
#  this tree except runtime state under data/.
#  (issue #40: v6 hard-required a USB mount point and exited;
#   v7 works from anywhere.)
#
#  Layout (shipped by CI, see VERSIONS):
#    node/            bundled Node.js
#    openclaw-pkg/    pinned openclaw (offline install verified)
#    ollama/          bundled Ollama (CPU-only)
#    models/          qwen3:1.7b GGUF + Modelfile (model package)
#    data/            runtime state (config, logs, model store)
# ============================================
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE="$SCRIPT_DIR/node/node"
OPENCLAW_MJS="$SCRIPT_DIR/openclaw-pkg/node_modules/openclaw/openclaw.mjs"
OLLAMA_BIN="$SCRIPT_DIR/ollama/ollama"
DATA_DIR="$SCRIPT_DIR/data"
STATE_DIR="$DATA_DIR/.openclaw"
MODEL_STORE="$DATA_DIR/ollama-models"
TEMPLATE="$SCRIPT_DIR/config/openclaw.json"
MODEL_ID="qwen3:1.7b"
# NOTE: file names use a dash (NTFS forbids ':') - Ollama TAGS keep the colon
MODEL_FILE="qwen3-1.7b"
MODEL_PRIMARY="ollama/$MODEL_ID"
LOCAL_MODEL=1
GW_PORT=18789
OL_PORT=11434

echo
echo "=========================================="
echo "  OpenClaw Portable v7 - Starting"
echo "=========================================="
echo

mkdir -p "$DATA_DIR" "$STATE_DIR" "$DATA_DIR/workspace" "$MODEL_STORE"

port_in_use() {
  # returns 0 if something LISTENs on the port
  (exec 3<>/dev/tcp/127.0.0.1/"$1") 2>/dev/null && { exec 3>&-; return 0; } || return 1
}

if port_in_use "$GW_PORT"; then
  echo "[INFO] Gateway port $GW_PORT is busy, using 18790 instead"
  GW_PORT=18790
fi
if port_in_use "$OL_PORT"; then
  echo "[INFO] Ollama port $OL_PORT is busy, using 11435 instead"
  OL_PORT=11435
fi

echo "[1/6] Checking core files..."
if [ ! -x "$NODE" ]; then
  echo "[ERROR] node/node not found - package incomplete. Re-download the core package."
  exit 1
fi
if [ ! -f "$OPENCLAW_MJS" ]; then
  echo "[ERROR] openclaw entry not found at openclaw-pkg/node_modules/openclaw/openclaw.mjs"
  echo "        Re-download the core package from the GitHub releases."
  exit 1
fi
if ! "$NODE" "$OPENCLAW_MJS" --version >/dev/null 2>&1; then
  echo "[ERROR] 'openclaw --version' failed - package incomplete (issue #58, P0)."
  echo "        Re-download the core package from the GitHub releases."
  exit 1
fi
echo "[OK]   OpenClaw $("$NODE" "$OPENCLAW_MJS" --version) (pinned, offline install verified)"

echo "[2/6] Local model backend (Ollama)..."
if [ ! -x "$OLLAMA_BIN" ]; then
  echo "[WARN] ollama/ollama not found (CORE package only) - cloud mode."
  LOCAL_MODEL=0
  MODEL_PRIMARY="openai/gpt-5.6-sol"
else
  export OLLAMA_MODELS="$MODEL_STORE"
  export OLLAMA_HOST="http://127.0.0.1:$OL_PORT"
  if ! port_in_use "$OL_PORT"; then
    echo "[INFO] Starting bundled Ollama on port $OL_PORT ..."
    nohup "$OLLAMA_BIN" serve >"$DATA_DIR/ollama.log" 2>&1 &
    for _ in $(seq 1 30); do
      curl -sf "http://127.0.0.1:$OL_PORT/api/version" >/dev/null 2>&1 && break
      sleep 1
    done
    if ! curl -sf "http://127.0.0.1:$OL_PORT/api/version" >/dev/null 2>&1; then
      echo "[WARN] Ollama did not start (see data/ollama.log). Cloud mode."
      LOCAL_MODEL=0
      MODEL_PRIMARY="openai/gpt-5.6-sol"
    fi
  fi
  if [ "$LOCAL_MODEL" = "1" ]; then
    if "$OLLAMA_BIN" list 2>/dev/null | grep -q "$MODEL_ID"; then
      echo "[OK]   Model $MODEL_ID already imported"
    else
      # assemble split parts (package may be on read-only media)
      GGUF="$DATA_DIR/$MODEL_FILE.Q4_K_M.gguf"
      if [ -f "$SCRIPT_DIR/models/$MODEL_FILE.Q4_K_M.gguf.part1" ]; then
        echo "[INFO] Assembling model from split parts..."
        cat "$SCRIPT_DIR/models/$MODEL_FILE.Q4_K_M.gguf.part1" >"$GGUF"
        PN=2
        while [ -f "$SCRIPT_DIR/models/$MODEL_FILE.Q4_K_M.gguf.part$PN" ]; do
          cat "$SCRIPT_DIR/models/$MODEL_FILE.Q4_K_M.gguf.part$PN" >>"$GGUF"
          PN=$((PN+1))
        done
      elif [ -f "$SCRIPT_DIR/models/$MODEL_FILE.Q4_K_M.gguf" ]; then
        GGUF="$SCRIPT_DIR/models/$MODEL_FILE.Q4_K_M.gguf"
      else
        echo "[WARN] Model files not found (models/$MODEL_FILE.Q4_K_M.gguf[.part1/.part2])."
        echo "       You have the CORE package only - download the model package too,"
        echo "       or configure a cloud API key."
        LOCAL_MODEL=0
        MODEL_PRIMARY="openai/gpt-5.6-sol"
      fi
      if [ "$LOCAL_MODEL" = "1" ]; then
        echo "[INFO] Importing model (one-time, a few seconds, no download)..."
        if ! "$NODE" "$SCRIPT_DIR/scripts/import-model.js" "$OLLAMA_BIN" \
              "$SCRIPT_DIR/models/Modelfile.qwen3-1.7b" "$GGUF" "$MODEL_ID"; then
          echo "[WARN] Model import failed. Cloud mode."
          LOCAL_MODEL=0
          MODEL_PRIMARY="openai/gpt-5.6-sol"
        fi
      fi
    fi
    if [ "$LOCAL_MODEL" = "1" ]; then
      echo "[OK]   Local model ready: $MODEL_ID (fully offline)"
    fi
  fi
fi

echo "[3/6] Generating gateway token (random per boot, never written to disk)..."
GW_TOKEN=$("$NODE" -e "console.log(require('crypto').randomBytes(24).toString('hex'))")
[ -n "$GW_TOKEN" ] || { echo "[ERROR] Could not generate a gateway token."; exit 1; }

echo "[4/6] Writing config..."
"$NODE" "$SCRIPT_DIR/scripts/set-portable-config.js" "$TEMPLATE" "$STATE_DIR" "$GW_PORT" "$OL_PORT" "$MODEL_PRIMARY" \
  || { echo "[ERROR] Config generation failed."; exit 1; }

echo "[5/6] Starting OpenClaw gateway on port $GW_PORT ..."
export OPENCLAW_STATE_DIR="$STATE_DIR"
nohup "$NODE" "$OPENCLAW_MJS" gateway run \
  --port "$GW_PORT" --allow-unconfigured --bind loopback --token "$GW_TOKEN" \
  >"$DATA_DIR/gateway.log" 2>&1 &

for _ in $(seq 1 60); do
  if curl -sf "http://127.0.0.1:$GW_PORT/health" >/dev/null 2>&1; then break; fi
  sleep 1
done
if ! curl -sf "http://127.0.0.1:$GW_PORT/health" >/dev/null 2>&1; then
  echo "[ERROR] Gateway did not become healthy in 60s. Last log lines:"
  tail -10 "$DATA_DIR/gateway.log" 2>/dev/null
  exit 1
fi
echo "[OK]   Gateway is live (health check passed)"

echo "[6/6] Open the dashboard in your browser:"
echo
echo "=========================================="
echo "  OpenClaw is ready."
echo "=========================================="
if [ "$LOCAL_MODEL" = "1" ]; then
  echo "  Mode:  Local offline model ($MODEL_ID)"
else
  echo "  Mode:  Cloud API (configure key with apply-config.bat / config.html)"
fi
echo "  UI:    http://localhost:$GW_PORT/?token=$GW_TOKEN"
echo "  Stop:  ./stop.sh"
echo "=========================================="
echo

# keep the script in the foreground; the gateway itself is a background child
trap 'echo; echo "[start] Ctrl+C - stopping (or run ./stop.sh)"; exec "$NODE" "$SCRIPT_DIR/scripts/stop.js" "$SCRIPT_DIR"' INT
while port_in_use "$GW_PORT"; do sleep 5; done
echo "[ERROR] Gateway stopped unexpectedly. Last log lines:"
tail -15 "$DATA_DIR/gateway.log" 2>/dev/null
exit 1
