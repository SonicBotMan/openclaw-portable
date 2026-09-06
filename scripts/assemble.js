#!/usr/bin/env node
/**
 * OpenClaw Portable v7 — GGUF part assembler (Windows-safe).
 *
 * Concatenates part1..partN into the destination file using streaming
 * reads (no full-file memory, no copy /b source==destination hazards).
 *
 * Usage: node assemble.js <outFile> <part1> [part2 ...]
 * Exit codes: 0 ok, 1 error.
 */


const fs = require('fs');
const path = require('path');

function die(msg) {
  console.error('[assemble] ' + msg);
  process.exit(1);
}

const [outFile, ...parts] = process.argv.slice(2);
if (outFile === undefined || parts.length === 0) {
  die('usage: assemble.js <outFile> <part1> [part2 ...]');
}
for (const p of parts) {
  if (!fs.existsSync(p)) die('part not found: ' + p);
}

fs.mkdirSync(path.dirname(path.resolve(outFile)), { recursive: true });
const ws = fs.createWriteStream(outFile);

function pump(part) {
  return new Promise((resolve, reject) => {
    const rs = fs.createReadStream(part, { highWaterMark: 64 * 1024 });
    rs.on('data', (chunk) => {
      if (!ws.write(chunk)) rs.pause();
      ws.once('drain', () => rs.resume());
    });
    rs.on('end', resolve);
    rs.on('error', reject);
  });
}

(async () => {
  let total = 0;
  try {
    for (const p of parts) {
      await pump(p);
      total += fs.statSync(p).size;
    }
    await new Promise((resolve, reject) => {
      ws.end(() => resolve());
      ws.on('error', reject);
    });
  } catch (err) {
    die('assembly failed: ' + err.message);
  }
  const got = fs.statSync(outFile).size;
  if (got !== total) die(`size mismatch: expected ${total}, got ${got}`);
  console.log(`[assemble] ${outFile} (${total} bytes, ${parts.length} parts)`);
})();
