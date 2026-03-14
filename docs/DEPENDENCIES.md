# 依赖清单

OpenClaw Portable 需要以下组件才能正常运行。

## 📦 必需组件

| 组件 | 版本 | 大小 | 用途 | 自动安装 |
|------|------|------|------|----------|
| **Node.js** | v22.22.0 | ~60MB | JavaScript 运行时 | ✅ 是 |
| **OpenClaw** | 2026.3.12 | ~30MB | 核心程序 | ✅ 是 |
| **npm 依赖** | - | ~50MB | 运行时依赖 | ✅ 是 |

**总计：约 140MB**

---

## 🚀 自动安装

### Windows
```bash
双击 scripts/install-all.bat
```

### Linux/Mac
```bash
chmod +x scripts/install-all.sh
./scripts/install-all.sh
```

---

## 📋 手动安装

如果自动安装失败，可以手动安装：

### 1. Node.js 便携版

**Windows (x64):**
```bash
# 下载
curl -LO https://nodejs.org/dist/v22.22.0/node-v22.22.0-win-x64.zip

# 解压到 node-portable/windows/
unzip node-v22.22.0-win-x64.zip -d node-portable/windows/
```

**Linux (x64):**
```bash
curl -LO https://nodejs.org/dist/v22.22.0/node-v22.22.0-linux-x64.tar.gz
tar -xzf node-v22.22.0-linux-x64.tar.gz -C node-portable/linux/ --strip-components=1
```

**macOS (x64):**
```bash
curl -LO https://nodejs.org/dist/v22.22.0/node-v22.22.0-darwin-x64.tar.gz
tar -xzf node-v22.22.0-darwin-x64.tar.gz -C node-portable/darwin/ --strip-components=1
```

### 2. OpenClaw

**使用 Git:**
```bash
git clone --depth 1 --branch v2026.3.12 \
  https://github.com/openclaw/openclaw.git
```

**下载压缩包:**
- GitHub: https://github.com/openclaw/openclaw/archive/refs/tags/v2026.3.12.zip

### 3. npm 依赖

```bash
cd openclaw
../node-portable/*/bin/npm install --production
```

---

## ⚙️ 配置文件

首次运行会自动创建配置文件：

**位置：** `data/config/openclaw.json`

**默认配置：**
```json
{
  "port": 3000,
  "model": {
    "default": "zai/glm-5"
  },
  "cacheTTL": 3600000,
  "workspace": "./data/workspace",
  "memory": {
    "dir": "./data/memory"
  }
}
```

---

## 🔍 验证安装

运行以下命令验证：

```bash
# Windows
node-portable\windows\node.exe --version
node-portable\windows\npm.cmd --version

# Linux/Mac
node-portable/*/bin/node --version
node-portable/*/bin/npm --version
```

---

## 🌐 网络要求

安装过程中需要访问：

| 域名 | 用途 | 频率 |
|------|------|------|
| `nodejs.org` | 下载 Node.js | 一次 |
| `github.com` | 下载 OpenClaw | 一次 |
| `registry.npmjs.org` | 下载依赖 | 一次 |

**离线安装：**
1. 在有网络的电脑上运行 `install-all.*`
2. 将整个目录复制到 U 盘
3. 在离线电脑上直接使用

---

## 💾 磁盘占用详情

| 目录 | 大小 | 说明 |
|------|------|------|
| `node-portable/windows/` | ~60MB | Windows 版 Node.js |
| `node-portable/linux/` | ~60MB | Linux 版 Node.js |
| `node-portable/darwin/` | ~60MB | macOS 版 Node.js |
| `openclaw/` | ~30MB | OpenClaw 核心 |
| `openclaw/node_modules/` | ~50MB | 运行时依赖 |
| `data/` | 可变 | 用户数据 |

**单平台最小安装：** ~140MB
**全平台完整安装：** ~260MB

---

## 🔄 更新

### 更新 Node.js
```bash
# 修改 scripts/setup-node.sh 中的 NODE_VERSION
# 重新运行
./scripts/setup-node.sh
```

### 更新 OpenClaw
```bash
cd openclaw
git pull origin master
../node-portable/*/bin/npm install --production
```

---

Made with 💕 by 小茹
