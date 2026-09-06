# Bundled model (v7)

## What is bundled

| field | value |
| --- | --- |
| model | **qwen3:1.7b** (Qwen 3, 2.0B params) |
| quant | Q4_K_M |
| file | `qwen3-1.7b.Q4_K_M.gguf` (1,359,279,776 bytes = 1.26 GB) |
| sha256 | `3d0b790534fe4b79525fc3692950408dca41171676ed7e21db57af5c65ef6ab6` |
| provenance | byte-identical to `registry.ollama.ai/v2/library/qwen3/manifests/1.7b` model layer |
| license | Apache-2.0 (`models/LICENSE.qwen3`) |
| capabilities | completion, **tools**, thinking (measured via `ollama show`) |
| context | 40 960 tokens (well above openclaw's 16 384 hard gate) |

Why qwen3:1.7b: it is the smallest model that passes openclaw's
tool-calling gate (`supportsTools + contextWindow ≥ 16384`,
`extensions/ollama/src/setup-model-selection.ts`) while staying in the
"fits on a USB stick, loads in RAM on most laptops" class.

## How it runs (v7)

1. `start.*` finds `models/qwen3-1.7b.Q4_K_M.gguf` (or split parts
   `qwen3-1.7b.Q4_K_M.gguf.part1/2` — assembled into `data/` on first run).
2. `scripts/import-model.js` runs `ollama create qwen3:1.7b -f
   models/Modelfile.qwen3-1.7b` (FROM-only Modelfile → one-time, no download).
3. openclaw talks to Ollama's **native** API (`api: "ollama"`, baseUrl
   `http://127.0.0.1:11434` — **no** `/v1`; the OpenAI-compatible path has
   unreliable tool calling) with `params: { jinja: true, num_ctx: 32768,
   keep_alive: "30m" }`.
   - `jinja: true` (request-level) activates the tool-aware Jinja template
     embedded in the GGUF. Note: `PARAMETER jinja` in a Modelfile is **not
     valid** in Ollama 0.33.3 — tool calling is enabled per request only.
4. Agent turns then run fully offline: tool calls (shell, file ops) execute
   on the local machine.

## Honest performance expectations (CPU)

Measured 2026-09-06, 16-core workstation, 46 GB RAM, Ollama 0.33.3:

| workload | time |
| --- | --- |
| bare completion ("reply pong") | ~15 s (18.6 tok/s generation) |
| prompt processing | ~100 tok/s |
| **one full openclaw agent turn with 1 tool call** | **~19 min** |

openclaw's agent prompt (system + tool schemas + skills) is ~29 K tokens, so
every turn re-prefills a large context. Local mode is an **air-gap/emergency
mode**: expect minutes per agent turn on CPU. For interactive speed use the
cloud API mode (config.html).

## Using a different local model

1. Put its GGUF in `models/` (name it `my-model.gguf` — no `:` in file names
   on Windows; the Ollama *tag* may keep colons).
2. Write a Modelfile:

   ```
   FROM /absolute/path/my-model.gguf
   ```

3. In `config/openclaw.json` change the provider model entry's `id` (e.g.
   `my-model`), keep `params.jinja: true` **only if the GGUF embeds a
   tool-aware Jinja template** (check with `ollama show my-model` →
   Capabilities must include `tools`), and set
   `agents.defaults.model.primary` to `ollama/my-model`.
4. Requirements: `supportsTools=true` and ≥16 384 context, otherwise openclaw
   will reject it for agent use.

Bigger/safer alternatives that pass the gate: `qwen3:4b`, `gemma4:e4b`
(openclaw's own onboarding default), `qwen2.5:7b`.
