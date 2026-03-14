@echo off
chcp 65001 >nul
title OpenClaw Portable

:: 获取脚本所在目录（U盘根目录）
set "USB_ROOT=%~dp0"
set "NODE_DIR=%USB_ROOT%node-portable\windows"
set "OPENCLAW_DIR=%USB_ROOT%openclaw"
set "DATA_DIR=%USB_ROOT%data"

:: 检查 Node.js 是否存在
if not exist "%NODE_DIR%\node.exe" (
    echo 正在下载 Node.js 便携版...
    powershell -Command "& { Invoke-WebRequest -Uri 'https://nodejs.org/dist/v22.12.0/node-v22.12.0-win-x64.zip' -OutFile '%TEMP%\node.zip'; Expand-Archive -Path '%TEMP%\node.zip' -DestinationPath '%NODE_DIR%' }"
)

:: 设置环境变量
set "OPENCLAW_CONFIG_DIR=%DATA_DIR%\config"
set "OPENCLAW_WORKSPACE=%DATA_DIR%\workspace"

:: 启动 Gateway
echo 启动 OpenClaw Gateway...
cd /d "%OPENCLAW_DIR%"
start ""%NODE_DIR%\node.exe" "%OPENCLAW_DIR%\bin\openclaw" gateway start

:: 等待 Gateway 启动
timeout /t 3 /nobreak >nul 2>&1

:: 打开浏览器
echo 打开浏览器...
start http://localhost:3000

echo OpenClaw Portable 已启动！
pause
