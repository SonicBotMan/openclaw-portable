# 开发指南

## 目录结构说明

```
openclaw-portable/
├── node-portable/          # Node.js 便携版
│   ├── windows/            # Windows 版本
│   ├── linux/              # Linux 版本
│   └── darwin/             # macOS 版本
├── openclaw/               # OpenClaw 核心（git submodule）
├── data/                   # 数据目录
│   ├── config/             # 配置文件
│   ├── workspace/          # 工作空间
│   └── memory/             # 记忆文件
├── start.bat               # Windows 启动脚本
├── start.sh                # Linux/Mac 启动脚本
└── README.md               # 项目说明
```

## 路径自适应

启动脚本会自动检测当前盘符/路径：

### Windows (start.bat)
```batch
@echo off
set SCRIPT_DIR=%~dp0
set NODE_PATH=%SCRIPT_DIR%node-portable\windows\node-v22.22.0-win-x64
set OPENCLAW_CONFIG=%SCRIPT_DIR%data\config\openclaw.json

%NODE_PATH%\node.exe %NODE_PATH%\npm\bin\npm-cli.js start
```

### Linux/Mac (start.sh)
```bash
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NODE_PATH="$SCRIPT_DIR/node-portable/$(uname -s)/node-v22.22.0-$(uname -m)"
export OPENCLAW_CONFIG="$SCRIPT_DIR/data/config/openclaw.json"

"$NODE_PATH/bin/node" "$NODE_PATH/bin/npm" start
```

## 添加新平台支持

1. 下载对应平台的 Node.js 便携版
2. 放到 `node-portable/<platform>/` 目录
3. 修改启动脚本添加平台检测

## 构建发布版本

```bash
# 打包所有内容
tar -czf openclaw-portable-$(date +%Y%m%d).tar.gz \
  --exclude=node-portable/*/node-* \
  --exclude=data/workspace/* \
  --exclude=data/memory/* \
  .
```
