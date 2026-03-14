#!/bin/bash
set -e

# ========================================
# OpenClaw Portable - Linux/Mac 启动器
# ========================================

# 获取脚本所在目录（U盘根目录）
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
USB_ROOT="${SCRIPT_DIR}"

# 检测操作系统
OS=$(uname -s)
ARCH=$(uname -m)

case $OS in
    Linux) 
        NODE_DIR="${USB_ROOT}/node-portable/linux"
        NODE_BIN="${NODE_DIR}/bin/node"
        ;;
    Darwin) 
        NODE_DIR="${USB_ROOT}/node-portable/darwin"
        NODE_BIN="${NODE_DIR}/bin/node"
        ;;
    *) 
        echo "不支持的操作系统: $OS"
        exit 1
        ;;
esac

DATA_DIR="${USB_ROOT}/data"
OPENCLAW_DIR="${USB_ROOT}/openclaw"
LOG_file="${DATA_DIR}/logs/startup.log"

# 创建必要的目录
mkdir -p "${DATA_DIR}/logs"
mkdir -p "${DATA_DIR}/config"
mkdir -p "${DATA_DIR}/workspace"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S)] $1" >> "${log_file}"
}

# 检查 Node.js 是否if [ ! -f "${NODE_BIN}" ]; then
    echo ""
    echo "========================================"
    echo "  首次运行，正在准备环境..."
    echo "========================================"
    echo ""
    
    # 调用下载脚本
    if [ -f "${USB_ROOT}/scripts/download-node.sh" ]; then
        "${USB_ROOT}/scripts/download-node.sh"
    else
        echo "错误: 未找到下载脚本"
        exit 1
    fi
fi

# 检查 OpenClaw
if [ ! -d "${OPENCLAW_DIR}" ]; then
    echo "正在克隆 OpenClaw..."
    git clone --depth 1 https://github.com/openclaw/openclaw.git "${OPENCLAW_DIR}"
fi

# 设置环境变量
export OPENCLAW_CONFIG_DIR="${DATA_DIR}/config"
export OPENCLAW_WORKSPACE="${DATA_DIR}/workspace"

# 启动 Gateway
echo ""
echo "========================================"
echo "  启动 OpenClaw Gateway..."
echo "========================================"
echo ""

cd "${OPENCLAW_DIR}"

# 启动 Gateway (后台运行)
"${NODE_BIN}" "${OPENCLAW_DIR}/bin/openclaw" gateway start &
GATEWAY_PID=$!

# 保存 PID
echo "${GATEWAY_PID}" > "${DATA_DIR}/gateway.pid"

# 等待 Gateway 启动
echo "等待 Gateway 启动..."
sleep 5

# 检查是否成功启动
if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo "[成功] Gateway 已启动"
else
    echo "[警告] Gateway 可能未成功启动"
    echo "请检查日志: ${log_file}"
fi

# 打开浏览器
echo ""
echo "打开浏览器..."

if command -v xdg-open > /dev/null; then
    xdg-open http://localhost:3000
elif command -v open > /dev/null; then
    open http://localhost:3000
else
    echo "请手动打开浏览器访问: http://localhost:3000"
fi

echo ""
echo "========================================"
echo "  OpenClaw Portable 已启动！"
echo "========================================"
echo ""
echo "数据目录: ${DATA_DIR}"
echo "日志文件: ${log_file}"
echo ""
echo "关闭此终端不会停止 Gateway"
echo "要停止 Gateway，请运行: ./stop.sh"
echo ""
