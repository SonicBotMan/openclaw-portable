# AI Maintenance Protocol

This project is maintained by AI agents (Pi + subagents). Humans review
releases; day-to-day triage, fixing, replying, and publishing run without
human prompting. This file is the operating manual — follow it, and update
it when the operating model changes.

## Mission

Keep **OpenClaw Portable** working: a USB-portable, no-install, optionally
fully-offline build of [openclaw/openclaw](https://github.com/openclaw/openclaw)
for Windows (primary) and Linux (secondary).

Non-goals: do not turn this into a fork of openclaw. It is a **packaging +
launching** project — every upstream feature improvement belongs upstream;
our value is pinning, bundling, scripts, and honest docs.

## The three invariants (never break these)

1. **The offline package is actually offline.** CI content gates
   (`.github/workflows/build-dual-release.yml`, GATE 1–6) must stay green.
   If a new CI step makes a gate slower or weaker, justify it in the PR;
   never delete a gate to make a build pass.
2. **Everything is pinned in `VERSIONS`.** No `@latest`, no floating
   versions anywhere (npm install, downloads, model files). Bump pins only
   via the procedure below.
3. **Nothing outside the package is touched at runtime** — no admin, no
   global installs, no writing outside the portable tree (state lives in
   `data/`). If a change requires breaking this, escalate to the human
   owner before merging.

## Watchlist (check when triaging upstream)

| watch item | where | action when it changes |
| --- | --- | --- |
| `engine` field in openclaw `package.json` | upstream main | if Node floor moves, bump `NODE_VERSION` in VERSIONS + re-release |
| openclaw issues #138488 (Windows OpenSSL-on-restart) | upstream | **when closed**: bump `OPENCLAW_VERSION` to current stable, verify `smoke-windows` GATE 6 passes, release |
| Ollama CLI surface (`save`/`create`/`show --modelfile`, `PARAMETER jinja`) | ollama releases | our offline import flow depends on it; test with a fresh store before bumping `OLLAMA_VERSION` |
| `extensions/ollama/src/setup-model-selection.ts` hard gate (supportsTools + ≥16384 ctx) | upstream | if the bundled model no longer passes, swap the model in VERSIONS + Modelfile + BUNDLED_MODEL.md |
| openclaw `gateway run` flags / `--allow-unconfigured` semantics | upstream | our start scripts encode the 2026-09 invocation; re-verify before bumping |

## Pin-bump procedure (the only supported version change)

1. Update `VERSIONS` (new openclaw / Node / Ollama / model pins).
2. Test locally (see "Verification" below) — especially: gateway start,
   gateway **restart** (the #138488 pattern), model import in a fresh
   store, one agent turn with a tool call, `stop.js` releasing ports.
3. Commit to `main` directly (small, well-described commits) or via PR —
   either is fine; PRs must be self-reviewed (see review rules).
4. Trigger the release workflow, watch all six gates, verify the release
   on a clean machine (RELEASE_CHECKLIST.md).

## Verification (minimum before any release)

- `check.*` passes on a freshly extracted package tree.
- `start.*` → gateway `/health` ok → one agent turn with a shell tool call
  completes (local model: expect minutes on CPU; see BUNDLED_MODEL.md).
- `stop.*` → all ports released, external processes untouched.
- Windows: the `smoke-windows` CI job (start → health → restart → health)
  is the authoritative Windows gate; a manual Windows machine check is
  required for releases (checklist step 7).

## Issue triage protocol

- Reply to user issues in the reporter's language (mostly Chinese).
- **Close only what is fixed and shipped.** A fix is "shipped" when the
  release containing it is on the release page; until then leave the issue
  open and reference the pending release.
- Star-integrity or reputation issues: do not argue; point to the shipped
  fix and the CI gates.
- Upstream bugs (e.g. #138488-class): keep a tracking note in the release
  - this file's watchlist; do not open our own upstream issue unless the
  maintainer asked us to.
- Feature requests: answer with the current design + honest cost; merge
  only if it serves the mission (portable, pinned, offline-capable).

## Review rules (for PRs opened by AI or humans)

- Every PR gets one self-review pass (fresh eyes: re-read the diff top to
  bottom, run the relevant checks) before merge.
- Batch scripts (.bat): pure ASCII, LF-in-git → CRLF-on-checkout handled by
  .gitattributes; never put CJK text inside `if (...)` blocks.
- File names: no `:` (NTFS), model *tags* may keep colons.
- No system-wide process kills; stop logic is port-based + ownership-verified
  (see scripts/stop.js — the gateway re-execs its process title, cmdline
  matching alone is not enough).
- Config: `config/openclaw.json` is a valid-JSON template; port values are
  rendered as numbers (openclaw's schema rejects strings).

## Escalate to the human owner

- Anything that spends money, publishes to a channel other than this repo,
  deletes releases, changes repo visibility, or touches other repos.
- Upstream licensing changes affecting the bundled model.
- A pin bump that the verification suite cannot pass after two attempts.

## Maintenance cadence (suggested, when no human asks)

- Weekly: skim openclaw releases + watchlist; no action if nothing relevant.
- On upstream stable release: evaluate pin bump (usually wait — 2026.8.2
  is intentionally one line behind latest until #138488 closes).
- After each release: update CHANGELOG, close shipped issues, post release
  notes.
