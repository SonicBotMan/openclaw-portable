#!/usr/bin/env bash
# OpenClaw Portable v7 - environment check
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE="$SCRIPT_DIR/node/node"
OPENCLAW_MJS="$SCRIPT_DIR/openclaw-pkg/node_modules/openclaw/openclaw.mjs"
OLLAMA_BIN="$SCRIPT_DIR/ollama/ollama"
MODEL_FILE="qwen3-1.7b"
PASS=0; FAIL=0

ok()   { echo "  [OK]   $1"; PASS=$((PASS+1)); }
bad()  { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }
info() { echo "  [INFO] $1"; }

echo
echo "=========================================="
echo "  OpenClaw Portable v7 - Environment Check"
echo "=========================================="
echo

echo "[Check 1/5] Node.js ..."
if [ -x "$NODE" ]; then
  ok "node $( "$NODE" --version )"
  "$NODE" -e "const [a,b]=process.versions.node.split('.').map(Number); process.exit(a>22||(a===22&&b>=22)||(a>=24)?0:1)" \
    && ok "meets OpenClaw engine requirement (>=22.22.3)" \
    || bad "OpenClaw requires Node >=22.22.3 (or >=24.15 / >=25.9)"
else
  bad "node/node not found - download the CORE package"
fi

echo "[Check 2/5] OpenClaw ..."
if [ -f "$OPENCLAW_MJS" ]; then
  if out=$("$NODE" "$OPENCLAW_MJS" --version 2>&1); then
    ok "OpenClaw $out (install verified)"
  else
    bad "openclaw --version failed (install scripts did not run? re-download the core package)"
  fi
else
  bad "openclaw entry not found at openclaw-pkg/node_modules/openclaw/openclaw.mjs"
fi

echo "[Check 3/5] Ollama ..."
if [ -x "$OLLAMA_BIN" ]; then
  ok "ollama $($("$OLLAMA_BIN" --version 2>&1 | grep -o '0\.[0-9.]*' | head -1 || echo 'version unknown'))"
else
  info "ollama/ not bundled - CLOUD mode only (download the model package or set an API key)"
fi

echo "[Check 4/5] Bundled model ..."
if [ -f "$SCRIPT_DIR/models/$MODEL_FILE.Q4_K_M.gguf" ] \
   || [ -f "$SCRIPT_DIR/models/$MODEL_FILE.Q4_K_M.gguf.part1" ]; then
  ok "models/ contains $MODEL_FILE GGUF (or split parts)"
elif [ -f "$SCRIPT_DIR/data/$MODEL_FILE.Q4_K_M.gguf" ]; then
  ok "model already assembled in data/"
else
  info "no local model files - CLOUD mode (apply-config to set an API key)"
fi

echo "[Check 5/5] Ports ..."
for p in 18789 11434; do
  if (exec 3<>/dev/tcp/127.0.0.1/"$p") 2>/dev/null; then
    exec 3>&- 2>/dev/null || true
    info "port $p in use (start will fall back to 18790/11435)"
  else
    ok "port $p free"
  fi
done

echo
echo "-------------------------------------------"
echo "  Result: $PASS OK, $FAIL FAIL"
echo "-------------------------------------------"
exit "$FAIL"
