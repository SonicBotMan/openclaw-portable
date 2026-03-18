#!/bin/bash
# OpenClaw Portable v6.0.0 - 智能启动脚本
# 支持：内置本地模型 (llama.cpp + Qwen2.5-1.5B)

# ✅ 立即定义 SCRIPT_DIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║    OpenClaw Portable v6.0.0            ║${NC}"
echo -e "${GREEN}║   🚀 Built-in Local Model Support      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

# ============================================
# 1/6 检测 U盘
# ============================================
echo -e "${BLUE}[1/6] 检测 U盘...${NC}"
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

# 检测当前目录
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

# 选择 U盘
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
# 2/6 设置环境
# ============================================
echo ""
echo -e "${BLUE}[2/6] 设置环境...${NC}"
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

# Git 检测（可选）
if command -v git &> /dev/null; then
    echo -e "${GREEN}✅ Git: $(git --version | cut -d' ' -f3)${NC}"
else
    echo -e "${YELLOW}⚠️  Git 未安装，部分功能可能受限${NC}"
fi

# ============================================
# 3/6 启动内置本地模型 (llama-server)
# ============================================
echo ""
echo -e "${BLUE}[3/6] 启动内置本地模型...${NC}"

LLM_DIR="$USB_PATH/llm"
LLM_PORT=18080
LLM_PID_FILE="$LLM_DIR/server.pid"
LLM_LOG="$LLM_DIR/server.log"

# 检测平台二进制
OS_TYPE="$(uname -s)"
ARCH_TYPE="$(uname -m)"

case "$OS_TYPE" in
  Linux*)  LLM_BIN="$LLM_DIR/bin/llama-server-linux-x86_64" ;;
  Darwin*)
    if [ "$ARCH_TYPE" = "arm64" ]; then
      LLM_BIN="$LLM_DIR/bin/llama-server-macos-arm64"
    else
      LLM_BIN="$LLM_DIR/bin/llama-server-macos-x86_64"
    fi ;;
  *) LLM_BIN="" ;;
esac

LLM_MODEL="$LLM_DIR/models/qwen2.5-1.5b-instruct-q4_k_m.gguf"
LLM_BUNDLED_READY=0

if [ -x "$LLM_BIN" ] && [ -f "$LLM_MODEL" ]; then
  # 检查端口是否已被占用
  if ! lsof -i :$LLM_PORT -sTCP:LISTEN -t &>/dev/null 2>&1; then
    # 计算线程数（总核心数 - 1，最小为 1）
    THREADS=$(( $(nproc 2>/dev/null || sysctl -n hw.logicalcpu 2>/dev/null || echo 2) - 1 ))
    THREADS=$(( THREADS < 1 ? 1 : THREADS ))
    
    chmod +x "$LLM_BIN"
    nohup "$LLM_BIN" \
      --model "$LLM_MODEL" \
      --port $LLM_PORT \
      --host 127.0.0.1 \
      --ctx-size 32768 \
      --threads $THREADS \
      --parallel 1 \
      -ngl 0 \
      --log-disable \
      >> "$LLM_LOG" 2>&1 &
    echo $! > "$LLM_PID_FILE"
    echo -e "${GREEN}✅ llama-server 已启动 (PID: $!, port: $LLM_PORT, threads: $THREADS)${NC}"
    echo -e "${YELLOW}   模型加载中，首次响应约需 5-15 秒...${NC}"
    LLM_BUNDLED_READY=1
  else
    echo -e "${GREEN}✅ 内置模型已在运行 (port: $LLM_PORT)${NC}"
    LLM_BUNDLED_READY=1
  fi
else
  echo -e "${YELLOW}⚠️  内置模型未找到，跳过 (仍可使用云端 API)${NC}"
  echo -e "${YELLOW}   模型路径: $LLM_MODEL${NC}"
  echo -e "${YELLOW}   二进制路径: $LLM_BIN${NC}"
fi

# ============================================
# 4/6 初始化工作目录
# ============================================
echo ""
echo -e "${BLUE}[4/6] 初始化工作目录...${NC}"

mkdir -p "$CONFIG_DIR"
mkdir -p "$WORKSPACE_DIR"
mkdir -p "$DATA_DIR"
mkdir -p "$TEMP_DIR"
mkdir -p "$LLM_DIR"

# 从 U盘加载配置到本地
if [ -d "$DATA_DIR/.openclaw" ]; then
  if command -v rsync &> /dev/null; then
    rsync -av --update "$DATA_DIR/.openclaw/" "$TEMP_DIR/" 2>/dev/null || true
  else
    cp -r "$DATA_DIR/.openclaw/"* "$TEMP_DIR/" 2>/dev/null || true
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

# 设置配置文件权限
if [ -f "$TEMP_DIR/openclaw.json" ]; then
    chmod 600 "$TEMP_DIR/openclaw.json"
fi

# ============================================
# [NEW] 自动注入内置模型配置
# ============================================
if [ $LLM_BUNDLED_READY -eq 1 ]; then
  echo ""
  echo -e "${BLUE}[4.5/6] 配置内置模型...${NC}"
  
  # 检查用户是否已配置主模型
  HAS_PRIMARY=$("$NODE_DIR/bin/node" -e "
    try {
      const cfg = JSON.parse(require('fs').readFileSync('$TEMP_DIR/openclaw.json','utf8'));
      console.log(cfg?.agents?.defaults?.model?.primary ? 'yes' : 'no');
    } catch(e) { console.log('no'); }
  " 2>/dev/null || echo "no")
  
  # 注入内置模型配置
  "$NODE_DIR/bin/node" -e "
    const fs = require('fs');
    const cfgPath = '$TEMP_DIR/openclaw.json';
    const cfg = fs.existsSync(cfgPath) ? JSON.parse(fs.readFileSync(cfgPath,'utf8')) : {};
    
    // 添加内置模型提供者
    cfg.models = cfg.models || {};
    cfg.models.providers = cfg.models.providers || {};
    cfg.models.providers['bundled-local'] = {
      baseUrl: 'http://127.0.0.1:18080/v1',
      apiKey: 'bundled-no-key',
      api: 'openai-completions',
      models: [
        {
          id: 'qwen2.5-1.5b',
          name: 'Qwen2.5 1.5B (Bundled CPU)',
          contextWindow: 32768,
          maxTokens: 4096,
          cost: { input: 0, output: 0 },
          capabilities: { tools: false }
        }
      ]
    };
    
    // 设置为默认模型（仅在用户未配置时）
    cfg.agents = cfg.agents || {};
    cfg.agents.defaults = cfg.agents.defaults || {};
    cfg.agents.defaults.model = cfg.agents.defaults.model || {};
    
    if ('$HAS_PRIMARY' === 'no') {
      cfg.agents.defaults.model.primary = 'bundled-local/qwen2.5-1.5b';
      console.log('default');
    } else {
      console.log('fallback');
    }
    
    fs.writeFileSync(cfgPath, JSON.stringify(cfg, null, 2));
  " 2>/dev/null
  
  if [ "$HAS_PRIMARY" = "no" ]; then
    echo -e "${GREEN}   ✅ bundled-local/qwen2.5-1.5b 已设为默认模型${NC}"
  else
    echo -e "${CYAN}   ℹ️  检测到已配置主模型，内置模型作为备用${NC}"
  fi
fi

# ============================================
# 5/6 保存路径记录
# ============================================
echo ""
echo -e "${BLUE}[5/6] 保存路径记录...${NC}"

echo "$USB_PATH" > "$DATA_DIR/.last_usb"
echo -e "${GREEN}✅ 路径已保存到: $DATA_DIR/.last_usb${NC}"

# ============================================
# 6/6 启动 OpenClaw Gateway
# ============================================
echo ""
echo -e "${BLUE}[6/6] 启动 OpenClaw Gateway...${NC}"

# 设置环境变量
export OPENCLAW_WORKSPACE="$WORKSPACE_DIR"
export OPENCLAW_CONFIG_DIR="$TEMP_DIR"
export XDG_CONFIG_HOME="$TEMP_DIR/.config"
export XDG_DATA_HOME="$TEMP_DIR/.local/share"

GATEWAY_PORT=${GATEWAY_PORT:-18789}

# 检查是否已在运行
STATUS=$(openclaw gateway status 2>/dev/null || true)
if echo "$STATUS" | grep -q "running"; then
    echo -e "${YELLOW}⚠️  OpenClaw 已在运行，跳过启动${NC}"
else
    if ! openclaw gateway start --port $GATEWAY_PORT; then
        echo -e "${RED}❌ OpenClaw 启动失败！${NC}"
        exit 1
    fi
    sleep 2
fi

# 验证启动
HEALTH_CHECK_OK=0

if command -v curl &>/dev/null; then
    if curl -s "http://localhost:$GATEWAY_PORT/health" &>/dev/null; then
        HEALTH_CHECK_OK=1
    fi
elif command -v wget &>/dev/null; then
    if wget -q -O- "http://localhost:$GATEWAY_PORT/health" &>/dev/null; then
        HEALTH_CHECK_OK=1
    fi
fi

if [ $HEALTH_CHECK_OK -eq 1 ]; then
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          ✅ 启动成功！                 ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    
    # 提取 token
    CONFIG_FILE="$TEMP_DIR/openclaw.json"
    GATEWAY_TOKEN=""
    
    if [ -f "$CONFIG_FILE" ]; then
        GATEWAY_TOKEN=$(grep -o '"token"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" 2>/dev/null | sed 's/.*"token"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/' || true)
    fi
    
    echo -e "  ${BLUE}访问地址:${NC} http://localhost:$GATEWAY_PORT"
    
    if [ -n "$GATEWAY_TOKEN" ]; then
        echo -e "  ${BLUE}Token:${NC}      $GATEWAY_TOKEN"
        echo ""
        
        # 尝试复制到剪贴板
        if command -v xclip &>/dev/null; then
            echo "$GATEWAY_TOKEN" | xclip -selection clipboard 2>/dev/null && \
                echo -e "  ${GREEN}✅ Token 已复制到剪贴板${NC}"
        elif command -v xsel &>/dev/null; then
            echo "$GATEWAY_TOKEN" | xsel --clipboard --input 2>/dev/null && \
                echo -e "  ${GREEN}✅ Token 已复制到剪贴板${NC}"
        elif command -v pbcopy &>/dev/null; then
            echo "$GATEWAY_TOKEN" | pbcopy 2>/dev/null && \
                echo -e "  ${GREEN}✅ Token 已复制到剪贴板${NC}"
        fi
        
        echo ""
        echo -e "  ${CYAN}直接访问链接（含 Token）:${NC}"
        echo -e "  ${CYAN}http://localhost:$GATEWAY_PORT?token=$GATEWAY_TOKEN${NC}"
        
        # 自动打开浏览器（带 token）
        if command -v xdg-open &>/dev/null; then
            xdg-open "http://localhost:$GATEWAY_PORT?token=$GATEWAY_TOKEN" 2>/dev/null &
        elif command -v open &>/dev/null; then
            open "http://localhost:$GATEWAY_PORT?token=$GATEWAY_TOKEN" 2>/dev/null &
        fi
    else
        echo -e "  ${YELLOW}Token 未找到，可在此查看: $CONFIG_FILE${NC}"
        
        # 自动打开浏览器（不带 token）
        if command -v xdg-open &>/dev/null; then
            xdg-open "http://localhost:$GATEWAY_PORT" 2>/dev/null &
        elif command -v open &>/dev/null; then
            open "http://localhost:$GATEWAY_PORT" 2>/dev/null &
        fi
    fi
    
    echo ""
    
    # 显示模型状态
    if [ $LLM_BUNDLED_READY -eq 1 ]; then
        echo -e "  ${GREEN}🤖 内置模型: qwen2.5-1.5b (端口 $LLM_PORT)${NC}"
    else
        echo -e "  ${YELLOW}☁️  使用云端 API 模型${NC}"
    fi
    
    echo ""
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
