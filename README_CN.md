# OpenClaw Portable（v7）

**把 OpenClaw（openclaw/openclaw）做成 U 盘级便携应用**——不安装、不需要管理员
权限、可选完全离线。拷到任何一台 Windows / Linux 机器上，双击即可用；在办公室、
飞机上、甚至断网的房间里，你的 AI 助理都能工作。

> 🇬🇧 English: [README.md](README.md)

---

## 里面装了什么

每个平台两个包（离线使用需要**两个都下**）：

| 包 | 内容 | 大小（Windows） |
| --- | --- | --- |
| `...-core.tar` | Node.js 26、openclaw 2026.8.2、Ollama 0.33.3（CPU 版）、全部脚本、配置模板 | ~0.8–1.1 GB |
| `...-model.tar` | qwen3-1.7b GGUF（Q4_K_M，sha256 校验钉死）+ Modelfile，切成 <900 MB 的分片 | ~1.3 GB |

所有版本钉在 [`VERSIONS`](VERSIONS) 里。**v7 的 CI 会强制校验包内容**——
缺模型、缺 openclaw 的包根本发不出来（这就是 [#58](../../issues/58) 的根治：
v6.0.2 那个"离线包"159 MB 里压根没有模型）。

## 快速上手（Windows）

1. 把 **core 包**和 **model 包**都解压到同一个文件夹（model 包的 `models/`
   分片会自动并入 core 的 `models/` 目录）：

   ```
   OpenClaw-Portable\
   ├─ node\  openclaw-pkg\  ollama\        ← core 包
   ├─ models\
   │  ├─ Modelfile.qwen3-1.7b             ← core 包
   │  ├─ qwen3-1.7b.Q4_K_M.gguf.part1     ← model 包
   │  └─ qwen3-1.7b.Q4_K_M.gguf.part2
   └─ start.bat ...
   ```

2. 双击 **`start.bat`**：
   - 首次运行会把模型导入 `data\ollama-models`（几秒，纯本地，零下载）
   - Gateway 起在 **18789** 端口（被占用自动换 18790）
   - 浏览器自动打开面板：`http://localhost:18789/?token=...`
     （token 每次启动随机生成，只显示在 URL，不落盘）

3. 停止：双击 **`stop.bat`**（只停本目录的进程，不误伤系统里的其他 node）。
   拔出 U 盘之前：双击 **`cleanup.bat`** 做零痕迹清理（API key、会话、日志，
   见 [#43](../../issues/43)）。

## 快速上手（Linux）

```bash
tar xf OpenClaw-Portable-v7.0.0-linux-core.tar
tar xf OpenClaw-Portable-v7.0.0-linux-model.tar   # models/ 分片并入
./start.sh
# 面板: http://localhost:18789/?token=<终端里显示>
```text

`start.sh` 在任意目录/文件系统都能跑——**不再强制要求 U 盘挂载点**
（[#40](../../issues/40)）。

## 离线 vs 云端

- **离线（本地模型，默认）**：模型包里带 qwen3-1.7b，走 Ollama 原生 API，
  完整支持工具调用（agent 能执行命令、读写文件）。
  ⚠️ 诚实的预期：纯 CPU 上**一个 agent 回合要几分钟**（实测：16 核工作站 +
  46GB 内存，单工具任务约 19 分钟）。本地模式是应急/无网模式，不是快模式。
- **云端（API key）**：只有 core 包时自动进入此模式。用 `config.html`
  （或 `apply-config.bat` + `models.json`）填入 OpenAI/Anthropic 等 key，
  agent 即改用云端模型（默认 `openai/gpt-5.6-sol`）。

## 端口

| 服务 | 默认 | 备用 |
| --- | --- | --- |
| OpenClaw gateway / 面板 | **18789** | 18790 |
| Ollama | **11434** | 11435 |

## 文件清单

```text
start.bat / start.sh      一键启动（检查、导入模型、起 gateway、开面板）
stop.bat  / stop.sh       只停本便携包的 gateway + Ollama
check.bat / check.sh      环境自检（node、openclaw、ollama、模型、端口）
cleanup.bat / cleanup.sh  拔盘前零痕迹清理
restart.bat               重启 gateway（Linux 用 ./stop.sh && ./start.sh）
config.html + apply-config.bat   云端 API key 配置面板
scripts/                  set-portable-config.js / import-model.js / stop.js
VERSIONS                  钉死的版本清单（CI 的单一事实源）
data/                     运行时状态（配置、会话、模型库、日志），首次运行生成
```text

## 安全说明

- gateway token 每次启动用 `crypto.randomBytes(24)` 生成，**只出现在启动器
  打开的 URL 里，从不写入磁盘**。
- gateway 只绑定 **loopback**（`--bind loopback`）。
- 一切都在这个目录内：Node、openclaw、Ollama 均内置，运行时状态全在 `data/`，
  拔盘即走。

## 上游兼容说明（改 pin 版本之前必读）

- **openclaw 钉在 2026.8.2**：上游 2026.9.1 引入
  [#138488](https://github.com/openclaw/openclaw/issues/138488)——Windows 上
  gateway **重启**需要独立 OpenSSL 装在 `C:\Program Files` 下，便携场景
  （无管理员）无法安装。CI 的 `smoke-windows` job 每次都做
  启动→健康检查→**重启**→健康检查 的回归测试。上游修好后改 `VERSIONS` 重新发版。
- **Node 钉在 26.8.1**：openclaw 的 engine 要求
  `>=22.22.3 <23 || >=24.15.0 <25 || >=25.9.0`（v6.0.2 带的 22.16.0
  已经启动不了新版 openclaw 了）。
- **npm ≥12 默认阻断 lifecycle scripts**：CI 安装 openclaw 必须带
  `--allow-scripts=openclaw`，并且装完立刻跑 `openclaw --version` 冒烟门
  （openclaw 的入口在安装脚本没跑时会拒绝启动）。

## 许可

本仓库代码 MIT（见 LICENSE）。OpenClaw 版权归上游项目（见其自身许可）。
捆绑模型 qwen3-1.7b 为 Apache-2.0（`models/LICENSE.qwen3`）。
