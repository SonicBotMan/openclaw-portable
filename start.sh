#!/bin/bash
# OpenClaw Portable - 智能启动脚本（修复版 v5.0.1）
# 使用方法：./start.sh

# ✅ Fix 1: 立即定义 SCRIPT_DIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ✅ Fix 4: 去掉 set -e，改为手动错误处理
# set -e  # 已删除

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║    OpenClaw Portable v5.0.1            ║${NC}"
echo -e "${GREEN}║        Smart Launcher (Fixed)          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

# ============================================
# 1. 检测所有 U盘
# ============================================
echo -e "${BLUE}[1/5] 检测 U盘...${NC}"
echo ""

USB_LIST=()
USB_COUNT=0

# 检测 Linux 挂载点
if [ -d "/media" ]; then
    for user_dir in /media/*; do
        if [ -d "$user_dir" ]; then
            for usb in "$user_dir"/*; do
                if [ -d "$usb/openclaw-portable" ]; then
                    USB_COUNT=$((USB_COUNT + 1))
                    USB_LIST+=("$usb/openclaw-portable")
                    echo -e "  ${GREEN}[$USB_COUNT]${NC} $usb (检测到 OpenClaw Portable)"
                fi
            done
        fi
    done
fi

# 检测 macOS 挂载点
if [ -d "/Volumes" ]; then
    for usb in /Volumes/*; do
        if [ -d "$usb/openclaw-portable" ]; then
            USB_COUNT=$((USB_COUNT + 1))
            USB_LIST+=("$usb/openclaw-portable")
            echo -e "  ${GREEN}[$USB_COUNT]${NC} $usb (检测到 OpenClaw Portable)"
        fi
    done
fi

# ✅ Fix 1: 检测当前目录（SCRIPT_DIR 已正确定义）
if [ -f "$SCRIPT_DIR/start.sh" ] && [ -d "$SCRIPT_DIR/node" ]; then
    CURRENT_USB=$(dirname "$SCRIPT_DIR")
    
    # 检查是否已经在列表中
    FOUND=0
    for usb in "${USB_LIST[@]}"; do
        if [ "$usb" == "$SCRIPT_DIR" ]; then
            FOUND=1
            break
        fi
    done
    
    if [ $FOUND -eq 0 ]; then
        USB_COUNT=$((USB_COUNT + 1))
        USB_LIST+=("$SCRIPT_DIR")
        echo -e "  ${GREEN}[$USB_COUNT]${NC} $CURRENT_USB (当前目录)"
    fi
fi

# ============================================
# 2. 选择 U盘（如果找到多个）
# ============================================
if [ "$USB_COUNT" -eq 0 ]; then
    echo -e "${RED}❌ 未检测到 U盘！${NC}"
    echo ""
    echo "请确保："
    echo "1. U盘已插入电脑"
    echo "2. U盘包含 openclaw-portable 目录"
    echo "3. 有读取权限"
    exit 1
elif [ "$USB_COUNT" -eq 1 ]; then
    USB_PATH="${USB_LIST[0]}"
    echo ""
    echo -e "${GREEN}✅ 自动选择: $(dirname "$USB_PATH")${NC}"
else
    echo ""
    echo -e "${YELLOW}[提示] 检测到多个 U盘，请选择：${NC}"
    echo ""
    read -p "请输入序号 (1-$USB_COUNT): " CHOICE
    
    # 验证输入
    if ! [[ "$CHOICE" =~ ^[0-9]+$ ]] || [ "$CHOICE" -lt 1 ] || [ "$CHOICE" -gt "$USB_COUNT" ]; then
        echo -e "${RED}❌ 无效选择${NC}"
        exit 1
    fi
    
    USB_PATH="${USB_LIST[$((CHOICE - 1))]}"
fi

# ============================================
# 3. 设置环境变量
# ============================================
echo ""
echo -e "${BLUE}[2/5] 设置环境...${NC}"
echo ""

CONFIG_DIR="$USB_PATH/config"
WORKSPACE_DIR="$USB_PATH/workspace"
DATA_DIR="$USB_PATH/data"
TEMP_DIR="$HOME/.openclaw-portable-temp"
NODE_DIR="$USB_PATH/node"
NPM_GLOBAL="$USB_PATH/npm-global"

# 设置 Node.js
if [ -d "$NODE_DIR" ] && [ -x "$NODE_DIR/bin/node" ]; then
    export PATH="$NODE_DIR/bin:$PATH"
    NODE_VERSION=$("$NODE_DIR/bin/node" --version)
    echo -e "${GREEN}✅ Node.js: $NODE_VERSION${NC}"
else
    echo -e "${RED}❌ Node.js 未找到！${NC}"
    exit 1
fi

# 设置 OpenClaw
if [ -d "$NPM_GLOBAL" ] && [ -x "$NPM_GLOBAL/bin/openclaw" ]; then
    export PATH="$NPM_GLOBAL/bin:$PATH"
    OPENCLAW_VERSION=$(openclaw --version 2>/dev/null || echo "未知")
    echo -e "${GREEN}✅ OpenClaw: $OPENCLAW_VERSION${NC}"
else
    echo -e "${RED}❌ OpenClaw 未找到！${NC}"
    exit 1
fi

# ✅ Fix 3: Git 检测（多平台 + 优雅失败）
if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}⚠️  Git 未安装，尝试自动安装...${NC}"
    
    if command -v apt-get &> /dev/null; then
        sudo apt-get install -y git 2>/dev/null || true
    elif command -v yum &> /dev/null; then
        sudo yum install -y git 2>/dev/null || true
    elif command -v brew &> /dev/null; then
        brew install git 2>/dev/null || true
    fi
    
    # 再检查一次，如果还没有就告诉用户手动装
    if ! command -v git &> /dev/null; then
        echo -e "${YELLOW}⚠️  Git 自动安装失败，部分功能可能受限${NC}"
        echo -e "${YELLOW}    请手动安装 Git: https://git-scm.com/downloads${NC}"
        echo -e "${YELLOW}    基本 AI 对话功能不受影响，继续启动...${NC}"
    else
        echo -e "${GREEN}✅ Git: $(git --version | cut -d' ' -f3)${NC}"
    fi
else
    echo -e "${GREEN}✅ Git: $(git --version | cut -d' ' -f3)${NC}"
fi

# ============================================
# 4. 保存上次使用的路径
# ============================================
echo ""
echo -e "${BLUE}[3/5] 保存路径记录...${NC}"

mkdir -p "$DATA_DIR"
echo "$USB_PATH" > "$DATA_DIR/.last_usb"
echo -e "${GREEN}✅ 路径已保存到: $DATA_DIR/.last_usb${NC}"

# ============================================
# 5. 初始化工作目录
# ============================================
echo ""
echo -e "${BLUE}[4/5] 初始化工作目录...${NC}"

mkdir -p "$CONFIG_DIR"
mkdir -p "$WORKSPACE_DIR"
mkdir -p "$DATA_DIR"
mkdir -p "$TEMP_DIR"

# 从 U盘加载配置到本地
if [ -d "$DATA_DIR/.openclaw" ]; then
    # 使用 rsync 进行增量同步（如果可用）
    if command -v rsync &> /dev/null; then
        rsync -av --update "$DATA_DIR/.openclaw/" "$TEMP_DIR/" 2>/dev/null || true
    else
        cp -r "$DATA_DIR/.openclaw/"* "$TEMP_DIR/" 2>/dev/null || true
        echo -e "${YELLOW}⚠️  rsync 不可用，使用基础复制模式${NC}"
    fi
    echo -e "${GREEN}✅ 配置已从 U盘加载${NC}"
else
    mkdir -p "$TEMP_DIR"
    cat > "$TEMP_DIR/openclaw.json" << 'EOF'
{
  "gateway": {
    "port": 18789,
    "mode": "local"
  }
}
EOF
    echo -e "${GREEN}✅ 默认配置已创建${NC}"
fi

# 设置配置文件权限（仅所有者可读写，保护敏感信息）
if [ -f "$TEMP_DIR/openclaw.json" ]; then
    chmod 600 "$TEMP_DIR/openclaw.json"
fi

# ============================================
# 6. 启动 OpenClaw
# ============================================
echo ""
echo -e "${BLUE}[5/5] 启动 OpenClaw Gateway...${NC}"

# ✅ Fix 2: 使用专属环境变量，不修改 HOME
export OPENCLAW_WORKSPACE="$WORKSPACE_DIR"
export OPENCLAW_CONFIG_DIR="$TEMP_DIR"
export XDG_CONFIG_HOME="$TEMP_DIR/.config"
export XDG_DATA_HOME="$TEMP_DIR/.local/share"
# ❌ 删除这行: export HOME="$TEMP_DIR"

# 检查是否已在运行
STATUS=$(openclaw gateway status 2>/dev/null || true)
if echo "$STATUS" | grep -q "running"; then
    echo -e "${YELLOW}⚠️  OpenClaw 已在运行，跳过启动${NC}"
else
    if ! openclaw gateway start; then
        echo -e "${RED}❌ OpenClaw 启动失败！${NC}"
        exit 1
    fi
    sleep 2
fi

# 验证启动（使用正确的端口）
GATEWAY_PORT=${GATEWAY_PORT:-18789}
if curl -s "http://localhost:$GATEWAY_PORT/health" &>/dev/null; then
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          ✅ 启动成功！                 ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${BLUE}访问地址:${NC} http://localhost:$GATEWAY_PORT"
    echo -e "  ${BLUE}U盘路径:${NC}   $(dirname $USB_PATH)"
    echo ""
    echo -e "  ${GREEN}运行环境离线，AI 服务需要网络连接${NC}"
    echo ""
    echo -e "  ${YELLOW}使用完毕后运行 stop.sh 一键关闭${NC}"
else
    echo -e "${RED}❌ 启动失败，请检查日志${NC}"
    echo -e "${YELLOW}   常见原因：${NC}"
    echo -e "${YELLOW}   1. 端口 $GATEWAY_PORT 被占用${NC}"
    echo -e "${YELLOW}   2. 杀毒软件拦截${NC}"
    exit 1
fi
