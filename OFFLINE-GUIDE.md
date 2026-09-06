# Offline Guide (v7)

Fully air-gapped usage of OpenClaw Portable.

## What "offline" means here

- **Offline LLM mode** (needs core + model package): the agent runs on the
  bundled qwen3:1.7b via Ollama. No network is contacted at all — the
  gateway binds loopback, Ollama runs locally, model import is local.
- **Offline install**: after extracting the packages there is no npm
  install, no model download, no telemetry. (v6's "offline package" failed
  this promise — see issue #58 and the CHANGELOG.)

## Prepare (on a machine WITH internet)

1. From GitHub releases download, per platform:
   - `OpenClaw-Portable-<ver>-<platform>-core.tar`
   - `OpenClaw-Portable-<ver>-<platform>-model.tar`
2. Copy both onto the USB stick (FAT32 exFAT NTFS all fine — the parts are
   each < 900 MB, under FAT32's 4 GB limit).

## First run (on the air-gapped machine)

1. Extract the **core** tar, then the **model** tar into the same folder.
2. `start.bat` / `start.sh`.
   - Model import happens automatically (seconds — it just registers the
     local GGUF with Ollama's model store under `data/ollama-models`).
3. Use the agent. Expect **minutes per agent turn on CPU**
   (see BUNDLED_MODEL.md for measured numbers).

## Verify the offline chain works (optional)

```bash
# inside the extracted package:
./check.sh                      # or check.bat
ollama show qwen3:1.7b | grep -A3 Capabilities   # must list "tools"
curl http://127.0.0.1:18789/health                # {"ok":true,"status":"live"}
```

## Gotchas

- **Do not** point Ollama's config at an OpenAI-compatible base URL with
  `/v1` for local tool calling — upstream documents that path as unreliable
  for tools. The bundled config uses the native API; keep it that way.
- **Do not** add `PARAMETER jinja true` to the Modelfile (invalid in Ollama
  0.33.3 — "unknown parameter 'jinja'"). Jinja is a request-level option,
  carried in `config/openclaw.json`.
- Windows file names cannot contain `:` — model parts are named
  `qwen3-1.7b...` (dash). The Ollama tag is `qwen3:1.7b` (colon) and that is
  fine because tags are not file names.
- If the model package is lost, re-downloading just the model package is
  enough — the core package is unchanged.
