#!/bin/bash
# OpenClaw Portable - 敏感文件清理脚本
# Issue #43 修复：零痕迹设计

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="$SCRIPT_DIR/data/.openclaw"

echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   OpenClaw Portable - 清理工具      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""

# ============================================
# 1. 检测敏感文件
# ============================================
echo -e "${BLUE}[检测] 扫描敏感文件...${NC}"
echo ""

SENSITIVE_FILES=()

# 检测配置文件
if [ -f "$DATA_DIR/openclaw.json" ]; then
    SENSITIVE_FILES+=("$DATA_DIR/openclaw.json")
    echo -e "  ${YELLOW}•${NC} openclaw.json (包含 API Key)"
fi

# 检测备份文件
if [ -d "$DATA_DIR/backups" ]; then
    SENSITIVE_FILES+=("$DATA_DIR/backups")
    echo -e "  ${YELLOW}•${NC} backups/ (配置备份)"
fi

# 检测 token 文件
if [ -f "$DATA_DIR/.gateway_token" ]; then
    SENSITIVE_FILES+=("$DATA_DIR/.gateway_token")
    echo -e "  ${YELLOW}•${NC} .gateway_token (访问令牌)"
fi

# 检测日志文件
if [ -f "$SCRIPT_DIR/llm/server.log" ]; then
    SENSITIVE_FILES+=("$SCRIPT_DIR/llm/server.log")
    echo -e "  ${YELLOW}•${NC} llm/server.log (运行日志)"
fi

# 检测 PID 文件
if [ -f "$SCRIPT_DIR/llm/server.pid" ]; then
    SENSITIVE_FILES+=("$SCRIPT_DIR/llm/server.pid")
    echo -e "  ${YELLOW}•${NC} llm/server.pid (进程 ID)"
fi

# ============================================
# 2. 显示清理选项
# ============================================
if [ ${#SENSITIVE_FILES[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ 未发现敏感文件${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}[选项] 请选择清理级别：${NC}"
echo ""
echo "  [1] 轻度清理 - 仅清理日志和 PID 文件"
echo "  [2] 深度清理 - 清理所有敏感文件（⚠️  需重新配置）"
echo "  [3] 取消"
echo ""

read -p "请选择 (1-3): " CHOICE

case "$CHOICE" in
    1)
        echo ""
        echo -e "${BLUE}[清理] 轻度清理...${NC}"
        
        # 清理日志
        if [ -f "$SCRIPT_DIR/llm/server.log" ]; then
            rm -f "$SCRIPT_DIR/llm/server.log"
            echo -e "${GREEN}  ✓ 已删除 llm/server.log${NC}"
        fi
        
        # 清理 PID
        if [ -f "$SCRIPT_DIR/llm/server.pid" ]; then
            rm -f "$SCRIPT_DIR/llm/server.pid"
            echo -e "${GREEN}  ✓ 已删除 llm/server.pid${NC}"
        fi
        
        echo ""
        echo -e "${GREEN}✅ 轻度清理完成${NC}"
        echo -e "${YELLOW}  配置文件已保留，可直接重新启动${NC}"
        ;;
        
    2)
        echo ""
        echo -e "${RED}[警告] 深度清理将删除所有敏感文件！${NC}"
        echo -e "${YELLOW}  包括：API Key、配置备份、访问令牌等${NC}"
        echo ""
        read -p "确认深度清理？(yes/N): " CONFIRM
        
        if [ "$CONFIRM" != "yes" ]; then
            echo -e "${YELLOW}已取消${NC}"
            exit 0
        fi
        
        echo ""
        echo -e "${BLUE}[清理] 深度清理...${NC}"
        
        # 清理所有敏感文件
        for file in "${SENSITIVE_FILES[@]}"; do
            if [ -e "$file" ]; then
                rm -rf "$file"
                echo -e "${GREEN}  ✓ 已删除 $(basename $file)${NC}"
            fi
        done
        
        echo ""
        echo -e "${GREEN}✅ 深度清理完成${NC}"
        echo -e "${YELLOW}  下次启动需要重新配置 API Key${NC}"
        ;;
        
    3|*)
        echo -e "${YELLOW}已取消${NC}"
        exit 0
        ;;
esac

echo ""
echo -e "${GREEN}✅ 清理完成，可安全拔出 U盘${NC}"
