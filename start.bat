@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

title OpenClaw Portable

:: ========================================
:: OpenClaw Portable - Windows 启动器
:: ========================================

:: 获取脚本所在目录（U盘根目录）
set "USB_ROOT=%~dp0"
set "USB_ROOT=%USB_ROOT:~0,-1%"
set "NODE_DIR=%USB_ROOT%\node-portable\windows"
set "OPENCLAW_DIR=%USB_ROOT%\openclaw"
set "DATA_DIR=%USB_ROOT%\data"
set "LOG_FILE=%DATA_DIR%\logs\startup.log"

:: 创建必要的目录
if not exist "%DATA_DIR%\logs" mkdir "%DATA_DIR%\logs"
if not exist "%DATA_DIR%\config" mkdir "%DATA_DIR%\config"
if not exist "%DATA_DIR%\workspace" mkdir "%DATA_DIR%\workspace"

:: 记录日志
echo [%date% %time%] OpenClaw Portable 启动中... > "%LOG_FILE%"

:: 检查 Node.js 是否存在
if not exist "%NODE_DIR%\node.exe" (
    echo.
    echo ========================================
    echo   首次运行，正在准备环境...
    echo ========================================
    echo.
    
    :: 创建目录
    if not exist "%NODE_DIR%" mkdir "%NODE_DIR%"
    
    :: 检查 PowerShell 是否可用
    where powershell >nul 2>&1
    if errorlevel 1 (
        echo [错误] 需要 PowerShell 来下载 Node.js
        echo 请手动下载 Node.js 便携版到:
        echo %NODE_DIR%
        echo.
        pause
        exit /b 1
    )
    
    :: 下载 Node.js
    echo [1/3] 下载 Node.js 便携版（约 60MB）...
    powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://nodejs.org/dist/v22.22.0/node-v22.22.0-win-x64.zip' -OutFile '%TEMP%\node.zip' -UseBasicParsing }"
    if errorlevel 1 (
        echo [错误] 下载 Node.js 失败
        pause
        exit /b 1
    )
    
    :: 解压
    echo [2/3] 解压 Node.js...
    powershell -Command "& { Expand-Archive -Path '%TEMP%\node.zip' -DestinationPath '%TEMP%\node-extract' -Force }"
    if errorlevel 1 (
        echo [错误] 解压 Node.js 失败
        pause
        exit /b 1
    )
    
    :: 移动文件
    echo [3/3] 安装 Node.js...
    xcopy "%TEMP%\node-extract\node-v22.22.0-win-x64\*" "%NODE_DIR%\" /E /I /Y /Q
    
    :: 清理临时文件
    del "%TEMP%\node.zip" >nul 2>&1
    rmdir /s /q "%TEMP%\node-extract" >nul 2>&1
    
    echo.
    echo [完成] Node.js 已安装
    echo.
)

:: 检查 OpenClaw 是否存在
if not exist "%OPENCLAW_DIR%\bin\openclaw.cmd" (
    echo.
    echo ========================================
    echo   安装 OpenClaw...
    echo ========================================
    echo.
    
    if not exist "%OPENCLAW_DIR%" mkdir "%OPENCLAW_DIR%"
    
    :: 使用 npm 安装 OpenClaw
    echo 正在安装 OpenClaw（约 30MB）...
    set "PATH=%NODE_DIR%;%PATH%"
    call "%NODE_DIR%\npm.cmd" install -g openclaw --prefix "%OPENCLAW_DIR%"
    if errorlevel 1 (
        echo [错误] 安装 OpenClaw 失败
        pause
        exit /b 1
    )
    
    echo [完成] OpenClaw 已安装
    echo.
)

:: 设置环境变量
set "OPENCLAW_CONFIG_DIR=%DATA_DIR%\config"
set "OPENCLAW_WORKSPACE=%DATA_DIR%\workspace"
set "PATH=%NODE_DIR%;%PATH%"

:: 检查是否已有配置文件
if not exist "%DATA_DIR%\config\openclaw.json" (
    echo [%date% %time%] 创建默认配置 >> "%LOG_FILE%"
    (
        echo {
        echo   "port": 3000,
        echo   "model": {
        echo     "default": "zai/glm-5"
        echo   },
        echo   "cacheTTL": 3600000
        echo }
    ) > "%DATA_DIR%\config\openclaw.json"
)

:: 启动 Gateway
echo.
echo ========================================
echo   启动 OpenClaw Gateway...
echo ========================================
echo.

cd /d "%USB_ROOT%"
start "OpenClaw Gateway" "%NODE_DIR%\node.exe" "%OPENCLAW_DIR%\bin\openclaw" gateway start

:: 等待 Gateway 启动
echo 等待 Gateway 启动...
timeout /t 5 /nobreak >nul

:: 检查 Gateway 是否成功启动
powershell -Command "& { try { $r = Invoke-WebRequest -Uri 'http://localhost:3000' -TimeoutSec 5 -UseBasicParsing; exit 0 } catch { exit 1 } }"
if errorlevel 1 (
    echo [警告] Gateway 可能未成功启动
    echo 请检查日志: %LOG_FILE%
    echo.
) else (
    echo [成功] Gateway 已启动
    echo.
)

:: 打开浏览器
echo 打开浏览器...
start http://localhost:3000

echo.
echo ========================================
echo   OpenClaw Portable 已启动！
echo ========================================
echo.
echo 数据目录: %DATA_DIR%
echo 日志文件: %LOG_FILE%
echo.
echo 关闭此窗口不会停止 Gateway
echo 要停止 Gateway，请运行: stop.bat
echo.

pause
