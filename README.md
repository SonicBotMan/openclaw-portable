# OpenClaw Portable (v7)

**OpenClaw (openclaw/openclaw) as a USB-stick portable app** — no install, no
admin rights, fully offline LLM option. Bring it to any Windows or Linux
machine, double-click, and your AI agent works — in the office, on a plane,
or in a room with no network at all.

> 🇨🇳 中文用户请看 [README_CN.md](README_CN.md)

---

## What's in the box

Two packages per platform (both required for offline use):

| package | contains | size (win) |
| --- | --- | --- |
| `...-core.tar` | Node.js 26, openclaw 2026.8.2, Ollama 0.33.3 (CPU), all scripts, config template | ~0.8–1.1 GB |
| `...-model.tar` | qwen3:1.7b GGUF (Q4_K_M, sha256-pinned) + Modelfile, split into <900 MB parts | ~1.3 GB |

All versions are pinned in [`VERSIONS`](VERSIONS). **v7's CI refuses to
publish a package whose contents don't match those assertions** (this is the
fix for [issue #58](../../issues/58): v6.0.2's "offline" package contained no
model at all).

## Quick start (Windows)

1. Extract **both** tar files so the model parts end up in `models\`:

   ```
   OpenClaw-Portable\
   ├─ node\  openclaw-pkg\  ollama\          (from core)
   ├─ models\
   │  ├─ Modelfile.qwen3-1.7b                (from core)
   │  ├─ part1                               (from model package)
   │  └─ part2
   └─ start.bat ...
   ```

   Then rename `models\part1` → `models\qwen3:1.7b.Q4_K_M.gguf.part1` and
   `models\part2` → `models\qwen3:1.7b.Q4_K_M.gguf.part2`
   (start.bat assembles them automatically on first run).

   *(Simpler: ask your release notes for the exact extraction layout — the
   release ships a `README` section per package.)*

2. Double-click **`start.bat`**.
   - First run: imports the model into `data\ollama-models` (seconds, no
     download).
   - Gateway starts on **port 18789** (falls back to 18790 if busy).
   - The dashboard opens in your browser with a per-boot token:
     `http://localhost:18789/?token=...`

3. Stop: **`stop.bat`** (stops only this portable's processes).
   Before removing a USB drive: **`cleanup.bat`** (removes API keys,
   sessions, logs — zero trace, [issue #43](../../issues/43)).

## Quick start (Linux)

```bash
tar xf OpenClaw-Portable-v7.0.0-linux-core.tar
tar xf OpenClaw-Portable-v7.0.0-linux-model.tar   # parts land in models/
./start.sh
# dashboard: http://localhost:18789/?token=<shown in terminal>
```text

`start.sh` works from any folder or filesystem — no USB mount point required
([issue #40](../../issues/40)).

## Offline vs cloud mode

- **Offline (local model)** — default when the model package is present.
  Runs qwen3:1.7b through Ollama's native API with full tool calling
  (agent can execute shell commands, read/write workspace files).
  ⚠️ Honest expectations: on CPU, a full agent turn takes **minutes**
  (measured: ~19 min for a one-tool task on a 16-core workstation with
  46 GB RAM). Local mode is an emergency/air-gapped mode, not a fast one.
- **Cloud (API key)** — core package only. Open `config.html` (or
  `apply-config.bat` + `models.json`) to set e.g. an OpenAI/Anthropic key;
  the agent then uses the cloud model (default `openai/gpt-5.6-sol`) and
  local Ollama stays idle.

## Ports

| service | default | fallback |
| --- | --- | --- |
| OpenClaw gateway / dashboard | **18789** | 18790 |
| Ollama | **11434** | 11435 |

## Files

```text
start.bat / start.sh      one-click start (checks, imports model, gateway, opens UI)
stop.bat  / stop.sh       stop this portable's gateway + Ollama only
check.bat / check.sh      environment check (node, openclaw, ollama, model, ports)
cleanup.bat / cleanup.sh  zero-trace cleanup before unmounting
restart.bat               restart gateway (Windows; Linux: ./stop.sh && ./start.sh)
config.html + apply-config.bat   cloud API key setup panel
scripts/                  set-portable-config.js, import-model.js, stop.js
VERSIONS                  pinned versions (source of truth for CI)
data/                     runtime state (config, sessions, model store, logs)
```text

## Security notes

- The gateway token is generated **per boot** with `crypto.randomBytes(24)`
  and only appears in the URL the launcher opens — never written to disk.
- The gateway binds **loopback only** (`--bind loopback`).
- Nothing is installed outside this folder (Node, openclaw, Ollama all live
  inside; all runtime state in `data/`).

## Upstream compatibility (read this before re-pinning)

- openclaw is pinned to **2026.8.2** because of
  [upstream #138488](https://github.com/openclaw/openclaw/issues/138488)
  (2026.9.1: Windows gateway *restart* requires a standalone OpenSSL under
  `C:\Program Files` — impossible for unattended portable installs). The CI
  `smoke-windows` job regression-tests gateway start→restart→health.
- Node is pinned to **26.8.1**: openclaw's engine requires
  `>=22.22.3 <23 || >=24.15.0 <25 || >=25.9.0` (the v6.0.2 package shipped
  22.16.0 and could not start openclaw at all).
- npm ≥12 blocks lifecycle scripts by default; the CI installs openclaw with
  `--allow-scripts=openclaw` and runs an `openclaw --version` smoke gate,
  because openclaw's entry refuses to start when its install lifecycle did
  not run.

## License

This repo's code is MIT (see LICENSE). OpenClaw is © its upstream project
(see its own license). The bundled model qwen3:1.7b is Apache-2.0
(`models/LICENSE.qwen3`).
