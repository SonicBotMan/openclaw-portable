# OpenClaw ポータブル v7（日本語）

v7 リリースは本 README_JP.md が英語/中国語版を指す方式に変更されました。

- 🇨🇳 中国語（最も詳細）: [README_CN.md](README_CN.md)
- 🇬🇧 English: [README.md](README.md)
- クイックスタート: [QUICK-START.md](QUICK-START.md)
- 変更履歴: [CHANGELOG.md](CHANGELOG.md)

## v7 の要点（速訳）

1. **2つのパッケージ**（両方必要）:
   - `...-core.tar` — Node 26 / openclaw 2026.8.2 / Ollama 0.33.3 / スクリプト
   - `...-model.tar` — qwen3-1.7b GGUF（Q4_K_M）分割ファイル + Modelfile
   両方を同じフォルダに展開してください。
2. **起動**: Windows は `start.bat`、Linux は `./start.sh`。
   ダッシュボード: `http://localhost:18789/?token=...`（token は起動ごとに生成、
   ディスクへ書かれません）。
3. **停止**: `stop.bat` / `./stop.sh`。USB 取り出し前: `cleanup.bat` / `./cleanup.sh`。
4. v6.0.2 の「オフラインパッケージ」にモデルが同梱されていなかった問題
   (#58) は、CI の内容アサーションにより根治されました。
5. 詳細な性能数値は [BUNDLED_MODEL.md](BUNDLED_MODEL.md)（英語）を参照。
