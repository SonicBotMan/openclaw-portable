# Release checklist (v7)

v7 releases are driven by the `build-dual-release` workflow
(Actions → *Build and release* → *Run workflow*). The workflow enforces the
gates below automatically — this checklist is for the human around it.

## Before running the workflow

1. [ ] `VERSIONS` says the right target versions (openclaw, Node, Ollama,
      model + sha256).
2. [ ] Any code changes since the last release are tested locally
      (`start.bat`/`start.sh` against a freshly extracted package, or at
      minimum `check.*` + a gateway health poll + one agent turn).
3. [ ] CHANGELOG.md has the entry for the version being released.

## Run the workflow

1. [ ] Set `VERSION` input (e.g. `v7.0.0`) and run.
2. [ ] Watch the jobs. All of these must be green — each is a gate, not a
      formality:
   - **build-windows / GATE 1**: `openclaw --version` after npm install
     (lifecycle guard + `--allow-scripts=openclaw` proven).
   - **build-windows / GATE 2**: core package content + size ≥ 500 MB.
   - **build-* / GATE 3**: GGUF sha256 == pinned digest.
   - **build-* / GATE 4**: model parts total ≥ 1 GB + Modelfile present
     (the exact #58 failure mode: a "model" package without the model).
   - **smoke-windows / GATE 5**: parts reassemble byte-identical; model
     imports in a fresh Ollama store.
   - **smoke-windows / GATE 6**: gateway start → `/health` → **restart** →
     `/health` (regression guard for upstream #138488).
   - **build-linux**: same gates for the linux packages.

## Verify the release

1. [ ] Release page: four assets present, each < 2 GB (parts keep the
      model package under single-part upload limits).
2. [ ] Spot-check on a clean machine (or a second USB stick):
   - extract core + model, run `check.*`, run `start.*`
   - dashboard opens with token URL; health endpoint `{"ok":true}`
   - one agent turn in **offline** mode with a tool call (expect minutes
     on CPU — see BUNDLED_MODEL.md)
   - `stop.*` frees ports 18789/11434; `cleanup.*` leaves no sensitive data
3. [ ] Close/update the tracking issues the release addresses (for v7.0.0:
      #58, #57, #56, #52, #40, #43).

## Post-release

1. [ ] Note the open upstream dependencies in the release:
   - openclaw pinned to 2026.8.2 until upstream #138488 (Windows
     OpenSSL-on-restart) is fixed, then bump `VERSIONS` and re-release.
