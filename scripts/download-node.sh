#!/bin/bash
set -e

# ========================================
# 下载 Node.js 便携版
# ========================================

NODE_VERSION="v22.22.0"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
USB_ROOT="${SCRIPT_DIR}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检测操作系统
OS=$(uname -s)
ARCH=$(uname -m)

case $OS in
    Linux)
        NODE_DIR="${USB_ROOT}/node-portable/linux"
        NODE_URL="https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.gz"
        ;;
    Darwin)
        NODE_DIR="${USB_ROOT}/node-portable/darwin"
        NODE_URL="https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-darwin-x64.tar.gz"
        ;;
    *)
        log_error "不支持的操作系统: $OS"
        exit 1
        ;;
esac

echo "========================================"
echo "  下载 Node.js 便携版"
echo "========================================"
echo ""
log_info "版本: ${NODE_VERSION}"
log_info "平台: ${OS} ${ARCH}"
log_info "目录: ${NODE_DIR}"
echo ""

# 检查是否已存在
if [ -f "${NODE_DIR}/bin/node" ]; then
    log_info "Node.js 已存在，跳过下载"
    exit 0
fi

# 创建目录
mkdir -p "${NODE_DIR}"

# 下载
log_info "正在下载..."
echo "URL: ${NODE_URL}"
echo ""

if curl -L --progress-bar -o /tmp/node.tar.gz "${NODE_URL}"; then
    log_info "下载完成"
else
    log_error "下载失败"
    exit 1
fi

# 解压
log_info "正在解压..."
if tar -xzf /tmp/node.tar.gz -C "${NODE_DIR}" --strip-components=1; then
    log_info "解压完成"
else
    log_error "解压失败"
    exit 1
fi

# 清理
rm -f /tmp/node.tar.gz

# 验证
if [ -f "${NODE_DIR}/bin/node" ]; then
    log_info "安装成功！"
    echo ""
    "${NODE_DIR}/bin/node" --version
else
    log_error "安装失败"
    exit 1
fi
