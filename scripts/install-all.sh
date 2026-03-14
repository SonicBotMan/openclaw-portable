#!/bin/bash
set -e

# ========================================
# 完整安装脚本 - 自动下载所有依赖
# ========================================

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
USB_ROOT="${SCRIPT_DIR}"
NODE_VERSION="v22.22.0"
OPENCLAW_VERSION="2026.3.12"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $1"; }
log_check() { echo -e "${PURPLE}[CHECK]${NC} $1"; }

echo ""
echo "========================================"
echo "  OpenClaw Portable 完整安装"
echo "========================================"
echo ""

# 检查列表
echo "📋 将要安装的组件："
echo "  1. Node.js ${NODE_VERSION} (约 60MB)"
echo "  2. OpenClaw ${OPENCLAW_VERSION} (约 30MB)"
echo "  3. OpenClaw 依赖包 (约 50MB)"
echo ""
echo "总计: 约 140MB"
echo ""

read -p "继续安装？ [y/N]: " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    log_info "已退出"
    exit 0
fi

echo ""

# ========================================
# Step 1: 检测操作系统
# ========================================
log_step "检测操作系统..."

OS=$(uname -s)
ARCH=$(uname -m)

case $OS in
    Linux)
        NODE_DIR="${USB_ROOT}/node-portable/linux"
        NODE_BIN="${NODE_DIR}/bin/node"
        NODE_URL="https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.gz"
        ;;
    Darwin)
        NODE_DIR="${USB_ROOT}/node-portable/darwin"
        NODE_BIN="${NODE_DIR}/bin/node"
        NODE_URL="https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-darwin-x64.tar.gz"
        ;;
    *)
        log_error "不支持的操作系统: $OS"
        exit 1
        ;;
esac

log_info "平台: ${OS} ${ARCH}"

# ========================================
# Step 2: 安装 Node.js
# ========================================
echo ""
log_step "安装 Node.js..."

if [ -f "${NODE_BIN}" ]; then
    log_warn "Node.js 已存在，跳过下载"
else
    log_info "下载 Node.js ${NODE_VERSION}..."
    mkdir -p "${NODE_DIR}"
    
    if curl -L --progress-bar -o /tmp/node.tar.gz "${NODE_URL}"; then
        log_info "解压中..."
        tar -xzf /tmp/node.tar.gz -C "${NODE_DIR}" --strip-components=1
        rm -f /tmp/node.tar.gz
        log_info "Node.js 安装完成"
    else
        log_error "下载失败"
        exit 1
    fi
fi

NODE_VERSION_INSTALLED=$("${NODE_BIN}" --version)
log_check "Node.js 版本: ${NODE_VERSION_INSTALLED}"

# ========================================
# Step 3: 克隆 OpenClaw
# ========================================
echo ""
log_step "安装 OpenClaw..."

OPENCLAW_DIR="${USB_ROOT}/openclaw"

if [ -d "${OPENCLAW_DIR}" ]; then
    log_warn "OpenClaw 已存在，跳过克隆"
else
    log_info "克隆 OpenClaw 仓库..."
    git clone --depth 1 --branch "v${OPENCLAW_VERSION}" \
        https://github.com/openclaw/openclaw.git "${OPENCLAW_DIR}"
    log_info "OpenClaw 克隆完成"
fi

# ========================================
# Step 4: 安装 OpenClaw 依赖
# ========================================
echo ""
log_step "安装 OpenClaw 依赖..."

cd "${OPENCLAW_DIR}"

if [ -d "node_modules" ]; then
    log_warn "依赖已存在，跳过安装"
else
    log_info "安装 npm 依赖..."
    "${NODE_BIN}" "${NODE_DIR}/bin/npm" install --production
    log_info "依赖安装完成"
fi

# ========================================
# Step 5: 创建配置文件
# ========================================
echo ""
log_step "创建配置文件..."

CONFIG_DIR="${USB_ROOT}/data/config"
mkdir -p "${CONFIG_DIR}"

if [ ! -f "${CONFIG_DIR}/openclaw.json" ]; then
    cat > "${CONFIG_DIR}/openclaw.json" << EOF
{
  "port": 3000,
  "model": {
    "default": "zai/glm-5"
  },
  "cacheTTL": 3600000,
  "workspace": "${USB_ROOT}/data/workspace",
  "memory": {
    "dir": "${USB_ROOT}/data/memory"
  }
}
EOF
    log_info "配置文件已创建"
else
    log_warn "配置文件已存在，跳过"
fi

# ========================================
# Step 6: 验证安装
# ========================================
echo ""
log_step "验证安装..."

ERRORS=0

# 检查 Node.js
if [ -f "${NODE_BIN}" ]; then
    log_check "✅ Node.js: ${NODE_VERSION_INSTALLED}"
else
    log_error "❌ Node.js 未安装"
    ERRORS=$((ERRORS + 1))
fi

# 检查 OpenClaw
if [ -f "${OPENCLAW_DIR}/bin/openclaw" ]; then
    log_check "✅ OpenClaw: 已安装"
else
    log_error "❌ OpenClaw 未安装"
    ERRORS=$((ERRORS + 1))
fi

# 检查配置
if [ -f "${CONFIG_DIR}/openclaw.json" ]; then
    log_check "✅ 配置文件: 已创建"
else
    log_error "❌ 配置文件未创建"
    ERRORS=$((ERRORS + 1))
fi

# 检查依赖
if [ -d "${OPENCLAW_DIR}/node_modules" ]; then
    DEP_COUNT=$(find "${OPENCLAW_DIR}/node_modules" -maxdepth 1 -type d | wc -l)
    log_check "✅ 依赖包: ${DEP_COUNT} 个"
else
    log_error "❌ 依赖未安装"
    ERRORS=$((ERRORS + 1))
fi

# ========================================
# 完成
# ========================================
echo ""
if [ $ERRORS -eq 0 ]; then
    echo "========================================"
    echo "  ✅ 安装完成！"
    echo "========================================"
    echo ""
    echo "磁盘占用："
    du -sh "${USB_ROOT}/node-portable" 2>/dev/null && \
    du -sh "${USB_ROOT}/openclaw" 2>/dev/null
    echo ""
    log_info "现在可以运行 ./start.sh 启动 OpenClaw"
else
    echo "========================================"
    echo "  ⚠️  安装完成，但有 ${ERRORS} 个错误"
    echo "========================================"
    echo ""
    log_warn "请检查上面的错误信息"
fi

echo ""
