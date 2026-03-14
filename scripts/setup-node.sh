#!/bin/bash
set -e

# ========================================
# 预置 Node.js 便携版
# ========================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
USB_ROOT="${SCRIPT_DIR}"
NODE_VERSION="v22.22.0"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

echo ""
echo "========================================"
echo "  预置 Node.js 便携版"
echo "========================================"
echo ""
log_info "版本: ${NODE_VERSION}"
echo ""

# 询问要下载哪些平台
echo "请选择要预置的平台："
echo "  1) Windows (x64)"
echo "  2) Linux (x64)"
echo "  3) macOS (x64)"
echo "  4) 全部平台"
echo "  0) 退出"
echo ""
read -p "请输入选项 [0-4]: " choice

case $choice in
    1)
        PLATFORMS=("windows")
        ;;
    2)
        PLATFORMS=("linux")
        ;;
    3)
        PLATFORMS=("darwin")
        ;;
    4)
        PLATFORMS=("windows" "linux" "darwin")
        ;;
    0)
        log_info "已退出"
        exit 0
        ;;
    *)
        log_error "无效选项"
        exit 1
        ;;
esac

echo ""

# 下载函数
download_node() {
    local platform=$1
    local node_dir="${USB_ROOT}/node-portable/${platform}"
    local url=""
    local ext=""
    
    case $platform in
        windows)
            url="https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-win-x64.zip"
            ext="zip"
            ;;
        linux)
            url="https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.gz"
            ext="tar.gz"
            ;;
        darwin)
            url="https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-darwin-x64.tar.gz"
            ext="tar.gz"
            ;;
    esac
    
    log_step "下载 ${platform} 版本..."
    echo "  URL: ${url}"
    echo ""
    
    # 检查是否已存在
    local node_bin="${node_dir}/bin/node"
    if [ "${platform}" = "windows" ]; then
        node_bin="${node_dir}/node.exe"
    fi
    
    if [ -f "${node_bin}" ]; then
        log_warn "${platform} 版本已存在，跳过下载"
        return 0
    fi
    
    # 创建目录
    mkdir -p "${node_dir}"
    
    # 下载
    local tmp_file="/tmp/node-${platform}.${ext}"
    
    if curl -L --progress-bar -o "${tmp_file}" "${url}"; then
        log_info "下载完成"
    else
        log_error "下载失败"
        return 1
    fi
    
    # 解压
    log_step "解压中..."
    
    case $platform in
        windows)
            # Windows 使用 unzip
            if command -v unzip > /dev/null; then
                unzip -q "${tmp_file}" -d "/tmp/node-extract-${platform}"
                mv /tmp/node-extract-${platform}/node-${NODE_VERSION}-win-x64/* "${node_dir}/"
            else
                log_error "需要 unzip 工具"
                return 1
            fi
            ;;
        *)
            tar -xzf "${tmp_file}" -C "${node_dir}" --strip-components=1
            ;;
    esac
    
    # 清理
    rm -f "${tmp_file}"
    rm -rf "/tmp/node-extract-${platform}"
    
    log_info "${platform} 版本安装完成"
    echo ""
}

# 下载所选平台
for platform in "${PLATFORMS[@]}"; do
    download_node "${platform}"
done

# 显示结果
echo ""
echo "========================================"
echo "  预置完成！"
echo "========================================"
echo ""
echo "已安装平台："
for platform in "${PLATFORMS[@]}"; do
    node_dir="${USB_ROOT}/node-portable/${platform}"
    if [ "${platform}" = "windows" ]; then
        if [ -f "${node_dir}/node.exe" ]; then
            echo "  ✅ ${platform} - $(${node_dir}/node.exe --version 2>/dev/null || echo 'installed')"
        fi
    else
        if [ -f "${node_dir}/bin/node" ]; then
            echo "  ✅ ${platform} - $(${node_dir}/bin/node --version 2>/dev/null || echo 'installed')"
        fi
    fi
done

echo ""
echo "磁盘占用："
du -sh "${USB_ROOT}/node-portable" 2>/dev/null || echo "  (计算中...)"
echo ""

log_info "现在可以双击 start.bat 或运行 ./start.sh 启动 OpenClaw"
echo ""
