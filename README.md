# OpenClaw Portable

🔌 **即插即用的便携式 OpenClaw**

插在 Windows/Linux/Mac 电脑上，点击启动图标即可运行 OpenClaw 并打开浏览器窗口进行对话。

## 特性

- ✅ **便携式** - 所有数据都在 U 盘，拔掉即带走
- ✅ **跨平台** - 支持 Windows / Linux / macOS
- ✅ **零安装** - 无需预装 Node.js，自带运行时
- ✅ **数据持久化** - 配置、记忆、Skills 都在 U 盘

## 目录结构

\`\`\`
openclaw-portable/
├── node-portable/          # 便携版 Node.js
│   ├── windows/            # Windows 版本
│   ├── linux/              # Linux 版本
│   └── darwin/             # macOS 版本
├── openclaw/               # OpenClaw 核心代码
├── data/                   # 数据目录
│   ├── config/             # 配置文件
│   ├── workspace/          # 工作空间
│   └── memory/             # 记忆文件
├── start.bat               # Windows 启动脚本
├── start.sh                # Linux/Mac 启动脚本
└── README.md               # 本文件
\`\`\`

## 快速开始

### Windows
1. 双击 \`start.bat\`
2. 等待 Gateway 启动
3. 浏览器自动打开

### Linux/Mac
\`\`\`bash
chmod +x start.sh
./start.sh
\`\`\`

## 抄送数据

将现有 OpenClaw 数据复制到 U 盘：
\`\`\`bash
cp -r ~/.openclaw/* data/
\`\`\`

## 预置 Node.js（推荐）

首次运行时需要下载约 60MB 的 Node.js。为避免等待，可以提前预置：

### Windows
```bash
双击 scripts/setup-node.bat
选择要预置的平台
```

### Linux/Mac
```bash
chmod +x scripts/setup-node.sh
./scripts/setup-node.sh
```

预置后，启动时间将大幅缩短。

## 注意事项

- U 盘建议使用 USB 3.0+ 或 SSD U 盘
- 盘符会自动检测，无需手动配置
- 预置 Node.js 可避免首次运行时的下载等待

## 许可证

MIT License

---

*Made with 💕 by 小茹*
