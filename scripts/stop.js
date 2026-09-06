#!/usr/bin/env node
/**
 * OpenClaw Portable v7 — stop helper (cross-platform).
 *
 * Stops ONLY the processes that belong to this portable tree:
 *   - node ... openclaw-pkg/node_modules/openclaw/openclaw.mjs gateway ...
 *   - <portableDir>/ollama/ollama[.exe] (server + spawned llama-server workers
 *     die with the server)
 *
 * Usage: node stop.js <portableDir>
 */


const { execSync } = require('child_process');

const portableDir = process.argv[2];
if (!portableDir) {
  console.error('usage: stop.js <portableDir>');
  process.exit(1);
}
const isWin = process.platform === 'win32';

function killNodesWithOpenClaw() {
  if (isWin) {
    // PowerShell: find node.exe processes whose command line references our openclaw.mjs
    const ps =
      "Get-CimInstance Win32_Process -Filter \"Name='node.exe'\" | " +
      "Where-Object { $_.CommandLine -like '*openclaw.mjs*' -and $_.CommandLine -like '*gateway*' } | " +
      "ForEach-Object { Stop-Process -Id $_.ProcessId -Force; Write-Output $_.ProcessId }";
    let out = '';
    try {
      out = execSync('powershell -NoProfile -Command ' + JSON.stringify(ps), { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] });
    } catch (_) { /* no matching processes */ }
    for (const pid of out.trim().split(/\s+/).filter(Boolean)) console.log(`[stop] gateway node process ${pid} stopped`);
  } else {
    const pat = portableDir + '/openclaw-pkg';
    let out = '';
    try {
      out = execSync(`ps -eo pid,args | grep -F ${JSON.stringify(pat)} | grep gateway | grep -v grep`, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] });
    } catch (_) { /* no matching processes */ }
    for (const line of out.trim().split('\n').filter(Boolean)) {
      const pid = line.trim().split(/\s+/)[0];
      try {
        process.kill(Number(pid), 'SIGTERM');
        console.log(`[stop] gateway node process ${pid} stopped`);
      } catch (_) { /* already gone */ }
    }
  }
}

function killOllama() {
  if (isWin) {
    const ps =
      "Get-Process ollama -ErrorAction SilentlyContinue | " +
      "Where-Object { $_.Path -like '" + portableDir.replace(/\\/g, '\\\\') + "\\ollama\\*' } | " +
      "ForEach-Object { Stop-Process -Id $_.Id -Force; Write-Output $_.Id }";
    let out = '';
    try {
      out = execSync('powershell -NoProfile -Command ' + JSON.stringify(ps), { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] });
    } catch (_) { /* no matching processes */ }
    for (const pid of out.trim().split(/\s+/).filter(Boolean)) console.log(`[stop] ollama process ${pid} stopped`);
  } else {
    const pat = portableDir + '/ollama/ollama';
    let out = '';
    try {
      out = execSync(`ps -eo pid,args | grep -F ${JSON.stringify(pat)} | grep -v grep`, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] });
    } catch (_) { /* no matching processes */ }
    for (const line of out.trim().split('\n').filter(Boolean)) {
      const pid = line.trim().split(/\s+/)[0];
      try {
        process.kill(Number(pid), 'SIGTERM');
        console.log(`[stop] ollama process ${pid} stopped`);
      } catch (_) { /* already gone */ }
    }
  }
}

killNodesWithOpenClaw();
killOllama();
console.log('[stop] done (data\\ preserved)');
