#!/usr/bin/env node
/**
 * OpenClaw Portable v7 — offline model importer.
 *
 * Rewrites the committed Modelfile's FROM line to point at the local GGUF
 * and runs `ollama create <modelId> -f <rewrittenModelfile>` against the
 * running ollama server (model store taken from OLLAMA_MODELS).
 *
 * Verified 2026-09-06: Ollama v0.33.3, qwen3:1.7b Q4_K_M GGUF (1.26 GB) in a
 * fresh empty store -> model with capabilities [completion, tools, thinking].
 * Tool calling additionally requires the CLIENT to pass options.jinja=true
 * (openclaw config: models[0].params.jinja — see config/openclaw.json); the
 * Modelfile itself must stay FROM-only (`PARAMETER jinja` is rejected by
 * 0.33.3's parser).
 *
 * Usage:
 *   node import-model.js <ollamaBin> <modelfilePath> <ggufPath> <modelId>
 *
 * Environment: OLLAMA_MODELS (model store dir) and OLLAMA_HOST (server URL)
 * are inherited by the `ollama` subprocess.
 *
 * Exit codes: 0 ok (model created), 1 error.
 */


const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');

function die(msg) {
  console.error('[import-model] ' + msg);
  process.exit(1);
}

const [ollamaBin, modelfilePath, ggufPath, modelId] = process.argv.slice(2);
if (modelId === undefined) {
  die('usage: import-model.js <ollamaBin> <modelfilePath> <ggufPath> <modelId>');
}
for (const [label, p] of [['ollamaBin', ollamaBin], ['modelfile', modelfilePath], ['gguf', ggufPath]]) {
  if (!fs.existsSync(p)) die(`${label} not found: ${p}`);
}

let mf = fs.readFileSync(modelfilePath, 'utf8');
const fromLine = 'FROM ' + path.resolve(ggufPath);
if (!/^FROM \S+/m.test(mf)) die('Modelfile has no FROM line');
mf = mf.replace(/^FROM .*/m, fromLine);

const tmpMf = path.join(os.tmpdir(), `openclaw-portable-modelfile-${process.pid}`);
fs.writeFileSync(tmpMf, mf, 'utf8');

console.log(`[import-model] creating ${modelId} from ${path.resolve(ggufPath)} (this takes a few seconds, no download)`);
let r;
try {
  r = spawnSync(ollamaBin, ['create', modelId, '-f', tmpMf], { stdio: 'inherit', shell: false });
} finally {
  try { fs.unlinkSync(tmpMf); } catch { /* best effort */ }
}
if (r.status !== 0) die(`ollama create exited with ${r.status}`);

const show = spawnSync(ollamaBin, ['show', modelId], { encoding: 'utf8' });
if (show.status === 0) {
  const caps = (show.stdout.match(/Capabilities[\s\S]*?$/) || [''])[0].slice(0, 300);
  if (caps) console.log('[import-model] model info:\n' + caps);
}
console.log(`[import-model] OK: ${modelId} is ready`);
