#!/usr/bin/env node
/**
 * OpenClaw Portable v7 — config materializer.
 *
 * Reads the committed template (config/openclaw.json) and writes the live
 * config to <stateDir>/openclaw.json, substituting the placeholders:
 *   __GATEWAY_PORT__   gateway port
 *   __OLLAMA_PORT__    ollama port
 *   __MODEL_PRIMARY__  agents.defaults.model.primary (e.g. "ollama/qwen3:1.7b"
 *                      or a cloud model id such as "openai/gpt-5.6-sol")
 *
 * The gateway token is intentionally NOT written to disk: the start scripts
 * pass it on the command line (`gateway run --token ...`) and only surface
 * it in the browser URL they open. Keeps tokens out of openclaw.json so
 * cleanup.bat/sh has less sensitive material and cloud-API keys (added later
 * via apply-config) can coexist without a token file.
 *
 * Usage:
 *   node set-portable-config.js <templatePath> <stateDir> <gatewayPort> <ollamaPort> <modelPrimary>
 *
 * Exit codes: 0 ok, 1 usage/IO error.
 */


const fs = require('fs');
const path = require('path');

function die(msg) {
  console.error('[set-portable-config] ' + msg);
  process.exit(1);
}

const [templatePath, stateDir, gatewayPort, ollamaPort, modelPrimary] = process.argv.slice(2);
if (stateDir === undefined || gatewayPort === undefined || ollamaPort === undefined || modelPrimary === undefined) {
  die('usage: set-portable-config.js <templatePath> <stateDir> <gatewayPort> <ollamaPort> <modelPrimary>');
}
if (!/^\d+$/.test(gatewayPort) || !/^\d+$/.test(ollamaPort)) {
  die('ports must be numeric (gateway=' + gatewayPort + ', ollama=' + ollamaPort + ')');
}

let raw;
try {
  raw = fs.readFileSync(templatePath, 'utf8');
} catch (err) {
  die('cannot read template ' + templatePath + ': ' + err.message);
}

const substituted = raw
  .replace(/__GATEWAY_PORT__/g, gatewayPort)
  .replace(/__OLLAMA_PORT__/g, ollamaPort)
  .replace(/__MODEL_PRIMARY__/g, modelPrimary);

// Fail closed on any unrendered placeholder (e.g. template drifted).
if (substituted.includes('__GATEWAY_PORT__') || substituted.includes('__OLLAMA_PORT__') || substituted.includes('__MODEL_PRIMARY__')) {
  die('placeholder(s) left unrendered in generated config');
}

// Validate it is actually JSON before writing.
try {
  JSON.parse(substituted);
} catch (err) {
  die('generated config is not valid JSON: ' + err.message);
}

try {
  fs.mkdirSync(stateDir, { recursive: true });
  const outPath = path.join(stateDir, 'openclaw.json');
  fs.writeFileSync(outPath, substituted + '\n', 'utf8');
  console.log('[set-portable-config] wrote ' + outPath);
} catch (err) {
  die('cannot write ' + stateDir + '/openclaw.json: ' + err.message);
}
