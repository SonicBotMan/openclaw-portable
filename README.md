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

## ⚠️ Windows 环境限制

### 可能遇到的问题

| 问题 | 症状 | 解决方案 |
|------|------|---------|
| **防火墙拦截** | 首次启动弹窗 | 点击"允许访问" |
| **SmartScreen** | "Windows 已保护你的电脑" | 点击"更多信息" → "仍要运行" |
| **端口占用** | 启动失败 | 修改端口或关闭占用程序 |
| **杀毒软件** | 程序被隔离 | 添加 U 盘到排除列表 |
| **U 盘只读** | 无法写入 | 检查写保护开关 |

### 自动诊断

```batch
:: 运行诊断脚本
scripts\diagnose.bat

:: 检查防火墙规则
scripts\check-firewall.bat
```

### 手动修复

#### 1. 添加防火墙规则（管理员权限）
```batch
netsh advfirewall firewall add rule name="OpenClaw Portable" ^
  dir=in action=allow program="U:\node-portable\windows\node.exe" ^
  enable=yes protocol=tcp localport=3000
```

#### 2. 排除杀毒软件扫描
```
Windows Defender:
  设置 → 更新与安全 → Windows 安全 → 病毒和威胁防护 → 管理设置 → 排除项
  添加文件夹：U:\openclaw-portable\
```

#### 3. 修改端口（如 3000 被占用）
```json
// data/config/openclaw.json
{
  "port": 8080,  // 改为其他端口
  ...
}
```

---

## 注意事项

- U 盘建议使用 USB 3.0+ 或 SSD U 盘
- 盘符会自动检测，无需手动配置
- 预置 Node.js 可避免首次运行时的下载等待
- **Windows 首次运行** 可能需要允许防火墙访问

## 许可证

MIT License

---

*Made with 💕 by 小茹*
