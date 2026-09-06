#!/usr/bin/env node
/**
 * OpenClaw Portable v7 — config materializer.
 *
 * The committed template (config/openclaw.json) is VALID JSON with sane
 * defaults. This script parses it and programmatically overrides the
 * runtime-dependent values with correctly-typed ones (this is why the
 * template stays valid JSON instead of using string placeholders):
 *   gateway.port                        -> Number (openclaw's schema
 *                                           rejects a string port)
 *   models.providers.ollama.baseUrl     -> http://127.0.0.1:<ollamaPort>
 *   agents.defaults.model.primary       -> modelPrimary
 *
 * The gateway token is intentionally NOT written to disk: the start scripts
 * pass it on the command line (`gateway run --token ...`) and only surface
 * it in the browser URL they open. Keeps openclaw.json free of credentials
 * (cloud API keys added later via apply-config are the only secrets).
 *
 * Usage:
 *   node set-portable-config.js <templatePath> <stateDir> <gatewayPort> <ollamaPort> <modelPrimary>
 *
 * Exit codes: 0 ok, 1 usage/IO/schema error.
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
const gw = Number(gatewayPort);
const ol = Number(ollamaPort);
if (!Number.isInteger(gw) || !Number.isInteger(ol) || gw < 1 || ol < 1) {
  die(`ports must be integers (gateway=${gatewayPort}, ollama=${ollamaPort})`);
}

let template;
try {
  template = JSON.parse(fs.readFileSync(templatePath, 'utf8'));
} catch (err) {
  die(`template ${templatePath} is not valid JSON: ${err.message}`);
}

template.gateway = template.gateway || {};
template.gateway.mode = 'local';
template.gateway.port = gw;
template.memory = template.memory || {};
template.memory.search = template.memory.search || {};
template.memory.search.enabled = false; // offline: no OpenAI embeddings
template.models = template.models || {};
template.models.providers = template.models.providers || {};
template.models.providers.ollama = template.models.providers.ollama || {};
template.models.providers.ollama.apiKey = template.models.providers.ollama.apiKey || 'ollama-local';
template.models.providers.ollama.baseUrl = `http://127.0.0.1:${ol}`;
template.models.providers.ollama.api = 'ollama'; // native API, NOT the /v1 OpenAI-compatible path
template.models.providers.ollama.timeoutSeconds = 900;
template.agents = template.agents || {};
template.agents.defaults = template.agents.defaults || {};
template.agents.defaults.model = template.agents.defaults.model || {};
template.agents.defaults.model.primary = modelPrimary;

const outPath = path.join(stateDir, 'openclaw.json');
try {
  fs.mkdirSync(stateDir, { recursive: true });
  fs.writeFileSync(outPath, JSON.stringify(template, null, 2) + '\n', 'utf8');
} catch (err) {
  die(`cannot write ${outPath}: ${err.message}`);
}
console.log(`[set-portable-config] wrote ${outPath}`);
