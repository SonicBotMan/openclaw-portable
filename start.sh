#!/bin/bash
set -e

# 获取脚本所在目录（U盘根目录）
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
USB_ROOT="${SCRIPT_DIR}"
NODE_DIR="${USB_ROOT}/node-portable/$(uname -s | tr '[:upper:]' '[:lower:]')"
OPENCLAW_DIR="${USB_ROOT}/openclaw"
DATA_DIR="${USB_ROOT}/data"

# 检测操作系统
OS=$(uname -s)
case $OS in
    Linux) NODE_DIR="${USB_ROOT}/node-portable/linux" ;;
    Darwin) NODE_DIR="${USB_ROOT}/node-portable/darwin" ;;
    *) echo "不支持的操作系统: $OS"; exit 1 ;;
esac

# 检查 Node.js 是否存在
if [ ! -f "${NODE_DIR}/bin/node" ]; then
    echo "正在下载 Node.js 便携版..."
    mkdir -p "${NODE_DIR}"
    case $OS in
        Linux)
            curl -L https://nodejs.org/dist/v22.12.0/node-v22.12.0-linux-x64.tar.gz | tar xz -C "${NODE_DIR}" --strip-components=1
            ;;
        Darwin)
            curl -L https://nodejs.org/dist/v22.12.0/node-v22.12.0-darwin-x64.tar.gz | tar xz -C "${NODE_DIR}" --strip-components=1
            ;;
    esac
fi

# 设置环境变量
export OPENCLAW_CONFIG_DIR="${DATA_DIR}/config"
export OPENCLAW_WORKSPACE="${DATA_DIR}/workspace"

# 启动 Gateway
echo "启动 OpenClaw Gateway..."
cd "${OPENCLAW_DIR}"
"${NODE_DIR}/bin/node" "${OPENCLAW_DIR}/bin/openclaw" gateway start &

# 等待 Gateway 启动
sleep 3

# 打开浏览器
echo "打开浏览器..."
if command -v xdg-open > /dev/null; then
    xdg-open http://localhost:3000
elif command -v open > /dev/null; then
    open http://localhost:3000
fi

echo "OpenClaw Portable 已启动！"
