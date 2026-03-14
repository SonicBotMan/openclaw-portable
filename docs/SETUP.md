# 安装指南

## 前置要求

- U 盘（建议 8GB 以上，USB 3.0+）
- Windows 10+ / Linux / macOS 10.15+

## 安装步骤

### 1. 下载项目
```bash
git clone https://github.com/SonicBotMan/openclaw-portable.git
cd openclaw-portable
```

### 2. 安装 Node.js 便携版

#### Windows
```bash
curl -L -o node-portable/windows/node.zip https://nodejs.org/dist/v22.22.0/node-v22.22.0-win-x64.zip
```

#### Linux
```bash
curl -L -o node-portable/linux/node.tar.gz https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-x64.tar.gz
```

#### macOS
```bash
curl -L -o node-portable/darwin/node.tar.gz https://nodejs.org/dist/v22.22.0/node-v22.22.0-darwin-x64.tar.gz
```

### 3. 安装 OpenClaw
```bash
./node-portable/*/bin/npm install -g openclaw
```

## 使用

### Windows
双击 `start.bat`

### Linux/macOS
```bash
./start.sh
```

## 数据持久化

所有数据存储在 `data/` 目录，拔出 U 盘即带走。
