#!/usr/bin/env node
/**
 * OpenClaw Portable v7 — stop helper (cross-platform).
 *
 * Stops ONLY the processes that belong to this portable tree:
 *   - the OpenClaw gateway (node re-execs itself with process title
 *     "openclaw" / "openclaw-agent" and its argv gets rewritten, so
 *     command-line matching alone is unreliable — we find it by its
 *     listening port and then verify ownership before killing)
 *   - the bundled Ollama server (bin path <portableDir>/ollama/ollama)
 *
 * A port listener that is NOT ours (e.g. the user's own system Ollama on
 * 11434 that we are reusing) is left untouched.
 *
 * Gateway ports checked: 18789 (default), 18790 (fallback).
 * Ollama ports checked:  11434 (default), 11435 (fallback).
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
const GW_PORTS = [18789, 18790];
const OL_PORTS = [11434, 11435];

function sh(cmd) {
  try {
    return execSync(cmd, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] }).trim();
  } catch {
    return '';
  }
}

function killPid(pid) {
  const p = Number(pid);
  try {
    process.kill(p, 'SIGTERM');
    console.log(`[stop] process ${p} stopped`);
  } catch {
    try {
      process.kill(p, 'SIGKILL');
      console.log(`[stop] process ${p} force-stopped`);
    } catch {
      /* already gone */
    }
  }
}

// ---- listeners -------------------------------------------------------------

function listenersOnPortsLinux(ports) {
  const out = sh('ss -ltnp');
  const byPort = {};
  for (const line of out.split('\n')) {
    for (const p of ports) {
      if (new RegExp(`:${p}\\b`).test(line)) {
        for (const m of line.matchAll(/pid=(\d+)/g)) {
          (byPort[p] = byPort[p] || new Set()).add(m[1]);
        }
      }
    }
  }
  return byPort;
}

function listenersOnPortsWindows(ports) {
  const ps =
    `Get-NetTCPConnection -LocalPort @(${ports.join(',')}) -State Listen -ErrorAction SilentlyContinue |` +
    ` ForEach-Object { "$($_.LocalPort) $($_.OwningProcess)" }`;
  const byPort = {};
  for (const line of sh(`powershell -NoProfile -Command ${JSON.stringify(ps)}`).split('\n')) {
    const [port, pid] = line.trim().split(/\s+/);
    if (pid) (byPort[port] = byPort[port] || new Set()).add(pid);
  }
  return byPort;
}

// ---- ownership checks ------------------------------------------------------

function isOursGatewayLinux(pid) {
  // comm rewritten to openclaw / openclaw-agent, or original cmdline, or cwd inside our tree
  const comm = sh(`cat /proc/${pid}/comm 2>/dev/null`);
  if (comm === 'openclaw' || comm === 'openclaw-agent') return true;
  const cmdline = sh(`tr '\\0' ' ' < /proc/${pid}/cmdline 2>/dev/null`);
  if (cmdline.includes('openclaw.mjs') || cmdline.includes('openclaw-pkg')) return true;
  const cwd = sh(`readlink /proc/${pid}/cwd 2>/dev/null`);
  return Boolean(cwd && cwd.startsWith(portableDir));
}

function isOursGatewayWindows(pid) {
  // after re-exec the command line becomes literally "openclaw" / "openclaw-agent"
  const ps =
    `(Get-CimInstance Win32_Process -Filter "ProcessId=${pid}" -ErrorAction SilentlyContinue).CommandLine`;
  const cmd = sh(`powershell -NoProfile -Command ${JSON.stringify(ps)}`);
  return /openclaw/i.test(cmd);
}

function isOursOllama(pid, portableDirArg) {
  const needle = isWin ? portableDirArg + '\\ollama\\ollama' : portableDirArg + '/ollama/ollama';
  const cmd = isWin
    ? sh(
        `powershell -NoProfile -Command ${JSON.stringify(
          `(Get-CimInstance Win32_Process -Filter "ProcessId=${pid}" -ErrorAction SilentlyContinue).CommandLine`
        )}`
      )
    : sh(`tr '\\0' ' ' < /proc/${pid}/cmdline 2>/dev/null`);
  return cmd.includes(needle);
}

// ---- run -------------------------------------------------------------------

const listeners = isWin ? listenersOnPortsWindows : listenersOnPortsLinux;
const gwListeners = listeners(GW_PORTS);
const olListeners = listeners(OL_PORTS);

// 1) gateway (by port, ownership-verified)
for (const port of GW_PORTS) {
  const pids = gwListeners[port] || [];
  for (const pid of pids) {
    if ((isWin ? isOursGatewayWindows : isOursGatewayLinux)(pid)) killPid(pid);
    else console.log(`[stop] port ${port} listener ${pid} is not from this portable - left running`);
  }
  if (pids.length === 0) console.log(`[stop] gateway port ${port}: no listener`);
}

// 2) safety net: pre-re-exec command lines
{
  const needle = isWin ? portableDir.replace(/\\/g, '\\\\') + '\\openclaw-pkg\\' : portableDir + '/openclaw-pkg';
  const out = isWin
    ? sh(
        `powershell -NoProfile -Command ${JSON.stringify(
          `Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -like '*${needle.replace(/'/g, "''")}*' } | ForEach-Object { Write-Output $_.ProcessId }`
        )}`
      )
    : sh('ps -eo pid,args');
  for (const line of out.split('\n')) {
    if (line.includes(needle)) {
      const pid = isWin ? line.trim() : line.trim().split(/\s+/)[0];
      if (pid) killPid(pid);
    }
  }
}

// 3) ollama (path-scoped; never kill a port listener we don't own)
for (const port of OL_PORTS) {
  const pids = olListeners[port] || [];
  for (const pid of pids) {
    if (isOursOllama(pid, portableDir)) killPid(pid);
    else console.log(`[stop] Ollama port ${port} listener ${pid} is not from this portable - left running`);
  }
}

console.log('[stop] done (data/ preserved)');
