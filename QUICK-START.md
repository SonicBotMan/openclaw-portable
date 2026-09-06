# Quick Start

> 🇨🇳 中文说明见 [README_CN.md](README_CN.md)

## Windows (2 minutes)

1. Download **both** release assets from the latest release:
   - `OpenClaw-Portable-<ver>-windows-core.tar`
   - `OpenClaw-Portable-<ver>-windows-model.tar`
2. Extract the **core** tar to a folder, e.g. `D:\OpenClaw\`.
3. Extract the **model** tar into the **same** folder — its `models/`
   split parts merge into the core's `models/` directory.
4. Double-click **`start.bat`**.
   - First run imports the model locally (seconds, no download).
   - The dashboard opens at `http://localhost:18789/?token=...`
5. To stop: `stop.bat`. Before removing a USB drive: `cleanup.bat`.

## Linux (1 minute)

```bash
tar xf OpenClaw-Portable-<ver>-linux-core.tar
tar xf OpenClaw-Portable-<ver>-linux-model.tar
./start.sh
# dashboard: http://localhost:18789/?token=<shown in the terminal>
./stop.sh
```

## No internet needed

With both packages present the whole flow works offline: no npm install, no
model download, no telemetry. The only network access you may want is cloud
API mode (`config.html`) — optional.

## First agent message

Open the dashboard URL (token in the address bar) and send a message like:

> Use the shell to run `echo hello from openclaw` and tell me the output.

The local model will call the tool and report the result. On CPU this takes
a few minutes (see [BUNDLED_MODEL.md](BUNDLED_MODEL.md) for measured
numbers).
