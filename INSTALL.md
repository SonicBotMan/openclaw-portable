# Install (v7)

## Prerequisites

None for users. No Node, no npm, no admin rights, no GPU — everything is
bundled (see `VERSIONS` for exact pinned versions).

## Windows

1. Extract `OpenClaw-Portable-<ver>-windows-core.tar` (e.g. with 7-Zip or
   Windows' built-in Tar support) into a folder with enough free space:
   ~1.2 GB for core + 1.3 GB for model files + ~2 GB runtime headroom in
   `data/` (assembled model + Ollama model store).
2. Extract `OpenClaw-Portable-<ver>-windows-model.tar` into the SAME folder
   (its `models/` split parts merge in).
3. Run `start.bat`.

USB tips:

- Use exFAT or NTFS if the stick is >4 GB and you plan to store session
  data; FAT32 works for the shipped files (all parts < 4 GB) but keeps
  `data/` small.
- After a session on a shared machine: run `cleanup.bat` before unmounting.

## Linux

```bash
tar xf OpenClaw-Portable-<ver>-linux-core.tar
tar xf OpenClaw-Portable-<ver>-linux-model.tar
chmod +x start.sh stop.sh check.sh cleanup.sh   # already set by CI, harmless
./start.sh
```

Works from any folder or filesystem — no USB mount point required
(issue #40). Requires an x86-64 CPU; for arm64 Linux see the roadmap.

## Cloud-only install (no local model)

Core package alone = cloud mode. `start.*` detects the missing model and
boots with a cloud default; then open `config.html` (or
`apply-config.bat`) to set your API key.

## Uninstall

Stop with `stop.bat` / `stop.sh`, then delete the folder. Everything the
portable touches lives inside it (state under `data/`), so nothing else is
left on the machine.
