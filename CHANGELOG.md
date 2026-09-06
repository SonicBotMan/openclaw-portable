# Changelog

## v7.0.0 (2026-09-06)

### The offline package is actually offline now (issue #58, P0)

- v6.0.2's "offline" Windows package was 159 MB and contained **no model at
  all** — the offline build step of the CI never downloaded or packed the
  Qwen model, and nothing asserted package contents before release.
- v7 splits the distribution into a **core package** (Node + openclaw +
  Ollama + scripts, ~700 MB–1 GB) and a **model package** (qwen3:1.7b Q4_K_M
  GGUF, ~1.26 GB, split into <900 MB parts), with CI **content-assertion
  gates**: the release job cannot publish a core package missing
  `node/openclaw.mjs/ollama`, or a model package whose parts don't total
  ≥1 GB with the pinned GGUF sha256.

### Pinned versions, no more `openclaw @latest` (issue #58 P0 root cause)

See `VERSIONS` — the single source of truth:

| component | v6.0.2 | v7.0.0 |
| --- | --- | --- |
| openclaw | `@latest` (unpinned) | **2026.8.2** (before upstream #138488) |
| Node.js | 22.16.0 | **26.8.1** (22.16.0 no longer satisfies the openclaw engine: `>=22.22.3 <23`) |
| LLM runtime | llama.cpp (built at package time, missing from the offline build) | **Ollama 0.33.3** (CPU-only, bundled) |
| model | Qwen2.5-1.5B-Instruct GGUF | **qwen3:1.7b Q4_K_M** (sha256-pinned, verified byte-identical to the official registry model) |

openclaw 2026.8.2 is chosen deliberately: upstream 2026.9.1 introduced a
Windows regression (#138488) where a gateway **restart** requires a
standalone OpenSSL under `C:\Program Files` — impossible for an unattended
portable install. Re-pin once that issue is closed. The CI `smoke-windows`
job regression-tests start → health → **restart** → health on
`windows-latest`.

### Local LLM stack: llama.cpp → Ollama native API (issue #52)

- Ollama 0.33 removed `ollama save`, so the package imports the raw GGUF via
  a committed Modelfile (`models/Modelfile.qwen3-1.7b`, FROM-only) on first
  start — one-time, no download.
- `PARAMETER jinja` is **not** a valid Modelfile parameter; tool calling is
  enabled per-request via `options.jinja=true`, which the openclaw config
  template carries (`models.providers.ollama.models[0].params.jinja`).
  Verified end-to-end: openclaw agent → Ollama native API → qwen3:1.7b
  structured `tool_calls`.
- Upstream hard gate respected: the bundled model reports
  `capabilities: [completion, tools, thinking]` and 40 960 context tokens
  (≥ the required 16 384).

### Windows scripts rebuilt (issues #57, #56, #16)

- `start.bat` is now **pure ASCII** (English output) — the v6 crash pattern
  (UTF-8 batch + `chcp` + CJK `rem` inside `if()` blocks) is gone by
  construction.
- Port logic corrected: busy port → fallback (v6 compared the wrong way).
- `restart.bat` no longer runs `taskkill /F /IM node.exe` (which killed
  **every** node process on the machine).
- `stop.bat` stops only processes belonging to this portable tree
  (scripts/stop.js: command-line-scoped kill, PowerShell instead of wmic).
- Gateway token is generated per boot (node crypto) and passed on the
  command line; it is never written to disk.

### Linux

- `start.sh` no longer **hard-requires a USB mount point** (issue #40): it
  works from any folder.
- `OPENCLAW_STATE_DIR`/`OLLAMA_MODELS` keep all state inside `data/`.

### Memory search off by default

- openclaw's memory-core plugin defaults to OpenAI embeddings; fully offline
  that errors. The template sets `memory.search.enabled=false`. Enable it
  (and set an API key) only when you want memory features in cloud mode.

### New / changed files

- `VERSIONS` — pinned version manifest
- `config/openclaw.json` — committed template (no longer gitignored!)
- `models/Modelfile.qwen3-1.7b`, `models/LICENSE.qwen3`, `models/REGISTRY_SOURCES.md`
- `scripts/set-portable-config.js`, `scripts/import-model.js`, `scripts/stop.js`
- `start/stop/check/cleanup/restart` rewritten; `start-online.bat`,
  `start-basic.*`, `create-offline.sh`, `install.sh`, `bin/`,
  `build-offline-package.sh`, llama docs removed.
