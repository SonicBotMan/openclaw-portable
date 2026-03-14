@echo off
chcp 65001 >nul
setlocal

:: ========================================
:: OpenClaw Portable - 停止脚本
:: ========================================

set "USB_ROOT=%~dp0"
set "USB_ROOT=%USB_ROOT:~0,-1%"
set "NODE_DIR=%USB_ROOT%\node-portable\windows"
set "OPENCLAW_DIR=%USB_ROOT%\openclaw"

echo.
echo ========================================
echo   停止 OpenClaw Gateway...
echo ========================================
echo.

cd /d "%USB_ROOT%"

:: 停止 Gateway
if exist "%NODE_DIR%\node.exe" (
    "%NODE_DIR%\node.exe" "%OPENCLAW_DIR%\bin\openclaw" gateway stop
    echo Gateway 已停止
) else (
    echo 错误: 未找到 Node.js
)

echo.
pause
