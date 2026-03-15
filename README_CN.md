# 🚀 OpenClaw 便携版

### 首次联网，后续离线 - 即插即用的 AI 助手

**中文** | [English](README.md) | [日本語](README_JP.md)

---

## 🎯 解决的问题

**传统 AI 助手的痛点：**
- ❌ 安装耗时 10-30 分钟
- ❌ 每台电脑都需要安装
- ❌ 换电脑需要重新安装
- ❌ 数据分散在各个设备

**结果？** 浪费时间、配置繁琐、隐私担忧。

---

## 💡 我们的方案：OpenClaw 便携版

**核心优势：**
- ✅ **首次联网自动安装** - 首次运行自动下载依赖（~60MB）
- ✅ **后续完全离线** - 安装后无需网络即可运行
- ✅ **60 秒极速启动** - 解压即用
- ✅ **U盘即插即用** - AI 随身，数据随身
- ✅ **零痕迹运行** - 完美适配公司/公共电脑
- ✅ **自动同步** - 数据跟随你，而不是机器

**一个 U盘。一次点击。零烦恼。**

---

## 🌟 核心价值

| 特性 | 传统安装 | 便携版 |
|------|---------|-------|
| **安装时间** | 10-30 分钟 | **60 秒** |
| **首次需要网络** | ✅ 是 | ✅ **是（~60MB）** |
| **后续需要网络** | ✅ 是 | ❌ **不需要** |
| **下载大小** | ~500MB | **~60MB（首次）** |
| **换电脑** | ❌ 重装 | ✅ **即插即用** |
| **数据同步** | ❌ 手动 | ✅ **自动** |
| **隐私保护** | ❌ 有痕迹 | ✅ **零痕迹** |
| **国内体验** | 需要翻墙 | **完美** |

---

## 📊 对比：便携版 vs 传统安装

### 传统 OpenClaw 安装方式

**痛点：**
```bash
# 步骤 1：安装 Node.js（10-15 分钟）
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

# 步骤 2：安装 OpenClaw（5-10 分钟）
npm install -g openclaw

# 步骤 3：配置（5-10 分钟）
openclaw config init
# 编辑配置文件...

# 步骤 4：换电脑重来一遍！
```

**问题：**
- ❌ 需要稳定网络（下载 500MB+）
- ❌ 国内需要翻墙或镜像
- ❌ 每台电脑都要重新安装
- ❌ 数据分散在各个设备
- ❌ 共享电脑留下痕迹
- ❌ 安装耗时 10-30 分钟

### OpenClaw 便携版

**解决方案：**
```bash
# 步骤 1：解压（1 分钟）
unzip OpenClaw-Portable-v5.0.1.zip

# 步骤 2：首次运行（首次需联网，30 秒）
./start.sh

# 完成！🎉
```

**优势：**
- ✅ 首次自动下载依赖（~60MB）
- ✅ 后续完全离线可用
- ✅ U盘随身带（AI 走哪跟哪）
- ✅ 数据自动同步
- ✅ 退出零痕迹
- ✅ 60 秒启动

### 详细对比

| 特性 | 传统安装 | 便携版 |
|------|---------|-------|
| **安装时间** | 10-30 分钟 | **60 秒** |
| **首次需要网络** | ✅ 是（下载 500MB+） | ✅ **是（~60MB）** |
| **后续需要网络** | ✅ 是 | ❌ **不需要** |
| **需要翻墙（国内）** | ✅ 是 | ❌ **不需要** |
| **换电脑** | ❌ 每次重装 | ✅ **USB 即用** |
| **数据同步** | ❌ 手动 | ✅ **自动** |
| **隐私保护（共享电脑）** | ❌ 有痕迹 | ✅ **零痕迹** |
| **配置保存** | ❌ 每台机器单独配置 | ✅ **USB 随身带** |
| **Node.js 安装** | ✅ 需要 | ❌ **自动下载** |
| **OpenClaw 安装** | ✅ 需要 | ❌ **自动下载** |
| **离线使用** | ❌ 不能 | ✅ **后续完全离线** |

**结论：** OpenClaw 便携版消除了传统安装的所有痛点，同时增加了便携性和隐私保护。

---

## 🎯 适用场景

### ✅ 完美适配

| 场景 | 为什么完美 |
|------|-----------|
| **公司电脑** | 零痕迹，数据在 U盘 |
| **网吧/公共电脑** | 即插即用，关闭即清 |
| **多设备切换** | 数据自动同步，无缝切换 |
| **国内网络** | 无需翻墙，无需镜像 |

### ⚠️ 注意事项

- **首次运行** - 需要网络连接（自动下载 Node.js + OpenClaw，约 60MB）
- **Git 功能** - 使用 Git 相关功能需要网络
- **AI 对话** - 需要网络连接到 AI 服务（这是 AI 网关的本质）
- **大小** - 完整安装后约 679MB
- **更新** - 在有网络环境中运行 `npm install -g openclaw@latest`

---

## 🚀 快速开始

### Windows 用户

**1 分钟快速启动：**
```batch
# 1. 解压到 U盘（1 分钟）
解压 OpenClaw-Portable-v5.0.1.zip

# 2. 双击启动（首次需联网，30 秒）
双击 start.bat

# 3. 访问
打开浏览器 → http://localhost:18789

# 4. 关闭
双击 stop.bat
```

**✅ 完成！数据在 U盘，本地零痕迹**

### Linux/macOS 用户

```bash
# 1. 解压
tar -xzf OpenClaw-Portable-v5.0.1.tar.gz

# 2. 启动（首次需联网）
cd OpenClaw-Portable
./start.sh

# 3. 访问
打开浏览器 → http://localhost:18789

# 4. 关闭
./stop.sh
```

---

## 📦 包含内容

首次运行后，目录结构如下：

```
OpenClaw-Portable/
├── node/              ← Node.js 22.x（首次自动下载，~30MB）
├── openclaw-pkg/      ← OpenClaw + 依赖（首次自动下载，~30MB）
├── data/              ← 用户数据（自动创建）
├── workspace/         ← 工作空间（自动创建）
├── start.bat          ← Windows 智能启动
├── stop.bat           ← Windows 智能关闭
├── start.sh           ← Linux/macOS 智能启动
├── stop.sh            ← Linux/macOS 智能关闭
└── config/            ← 配置目录
```

**下载包大小：** ~1MB（脚本）  
**首次安装后：** ~679MB（完整运行环境）

---

## 📋 系统要求

| 平台 | 要求 |
|------|------|
| **Windows** | Windows 10 2004+ / Windows 11 |
| **Linux** | Ubuntu 20.04+ / Debian 11+ |
| **macOS** | macOS 10.15+ |
| **U盘** | 至少 1GB 可用空间 |
| **网络** | 首次运行需要（~60MB） |

---

## ⚠️ 安全提示

**请勿分享以下文件：**
- `data/.openclaw/openclaw.json` - 包含 API keys
- `data/.last_usb` - 包含路径信息

**权限自动设置：**
- 配置文件：`600`（仅所有者可读写）
- 日志文件：`640`（所有者读写，组只读）

**关于安全软件警报：**

本项目**不使用** Base64 编码的 PowerShell 命令（常见的恶意软件特征）。所有下载逻辑使用：
- Windows 10+ 内置 `curl.exe`
- 明文 PowerShell 脚本（可直接审计）

如果安全软件仍报警，可能是因为：
1. 从网络下载可执行文件（Node.js）
2. 脚本修改系统环境变量

**解决方案：**
- 企业用户：将整个目录添加到白名单
- 个人用户：临时禁用实时保护或添加例外

**代码审计：**
所有脚本都是明文，可以直接查看和审计。无混淆，无加密。

---

## 🔄 更新

```bash
# 在有网络环境中
cd OpenClaw-Portable

# 更新 OpenClaw
export PATH="$PWD/node/bin:$PWD/openclaw-pkg/bin:$PATH"
npm install -g openclaw@latest
```

---

## 📥 下载

- **GitHub Release**: https://github.com/SonicBotMan/openclaw-portable/releases
- **镜像下载（国内）**: https://npmmirror.com/mirrors/openclaw-portable/

---

## ❓ 常见问题

<details>
<summary><b>Q: 为什么首次需要网络？</b></summary>

便携版采用"轻量脚本 + 自动下载"模式：
- 下载包只有脚本（~1MB）
- 首次运行时自动下载 Node.js + OpenClaw（~60MB）
- 下载后保存在 U盘，后续完全离线

这样做的好处：
- 下载包小，下载快
- 始终是最新版本
- 支持多平台（脚本自动适配）
</details>

<details>
<summary><b>Q: 后续使用需要网络吗？</b></summary>

**运行环境**：❌ 不需要（已下载）
**AI 对话**：✅ 需要（连接 AI 服务）
**Git 功能**：✅ 需要（克隆仓库等）

简言之：运行环境离线，AI 服务需要网络。
</details>

<details>
<summary><b>Q: 能在公司电脑用吗？</b></summary>

可以！所有数据在 U盘，关闭后本地零痕迹。
</details>

<details>
<summary><b>Q: 国内网络能用吗？</b></summary>

完美适配！自动使用国内镜像，无需翻墙。
</details>

<details>
<summary><b>Q: 如何在完全离线环境使用？</b></summary>

需要提前准备：
1. 在有网络环境首次运行，完成依赖下载
2. 将整个目录复制到离线环境
3. 后续即可完全离线运行（AI 对话除外）
</details>

<details>
<summary><b>Q: 如何更新？</b></summary>

在有网络环境中运行：
```bash
export PATH="$PWD/node/bin:$PWD/openclaw-pkg/bin:$PATH"
npm install -g openclaw@latest
```
</details>

---

## 🤝 贡献

欢迎贡献！查看 [CONTRIBUTING.md](CONTRIBUTING.md)

---

## 📄 许可证

MIT License - 查看 [LICENSE](LICENSE)

---

## 🌟 Star History

如果这个项目帮到你，请 ⭐️ star！

[![Star History Chart](https://api.star-history.com/svg?repos=SonicBotMan/openclaw-portable&type=Date)](https://star-history.com/#SonicBotMan/openclaw-portable&Date)

---

**版本：** 5.0.1 | **发布日期：** 2026-03-15 | **Node.js：** v22.x | **OpenClaw：** Latest

---

<p align="center">
  <b>为全球 AI 社区用 ❤️ 打造</b>
</p>
