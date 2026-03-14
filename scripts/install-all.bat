@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

title OpenClaw Portable 完整安装

:: ========================================
:: 完整安装脚本 - 自动下载所有依赖
:: ========================================

set "USB_ROOT=%~dp0"
set "USB_ROOT=%USB_ROOT:~0,-1%"
set "NODE_VERSION=v22.22.0"
set "OPENCLAW_VERSION=2026.3.12"

echo.
echo ========================================
echo   OpenClaw Portable 完整安装
echo ========================================
echo.

:: 检查列表
echo 📋 将要安装的组件：
echo   1. Node.js %NODE_VERSION% (约 60MB)
echo   2. OpenClaw %OPENCLAW_VERSION% (约 30MB)
echo   3. OpenClaw 依赖包 (约 50MB)
echo.
echo 总计: 约 140MB
echo.

set /p confirm="继续安装？ [y/N]: "
if /i not "%confirm%"=="y" (
    echo [INFO] 已退出
    pause
    exit /b 0
)

echo.

:: ========================================
:: Step 1: 检查 PowerShell 和 Git
:: ========================================
echo [STEP] 检查依赖工具...

where powershell >nul 2>&1
if errorlevel 1 (
    echo [ERROR] 需要 PowerShell
    pause
    exit /b 1
)

where git >nul 2>&1
if errorlevel 1 (
    echo [WARN] Git 未安装，OpenClaw 将从压缩包下载
    set USE_GIT=0
) else (
    set USE_GIT=1
)

echo [INFO] 工具检查通过

:: ========================================
:: Step 2: 安装 Node.js
:: ========================================
echo.
echo [STEP] 安装 Node.js...

set "NODE_DIR=%USB_ROOT%\node-portable\windows"
set "NODE_BIN=%NODE_DIR%\node.exe"

if exist "%NODE_BIN%" (
    echo [WARN] Node.js 已存在，跳过下载
) else (
    echo [INFO] 下载 Node.js %NODE_VERSION%...
    mkdir "%NODE_DIR%"
    
    set URL=https://nodejs.org/dist/%NODE_VERSION%/node-%NODE_VERSION%-win-x64.zip
    
    powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '!URL!' -OutFile '%TEMP%\node.zip' -UseBasicParsing }"
    
    if errorlevel 1 (
        echo [ERROR] 下载失败
        pause
        exit /b 1
    )
    
    echo [INFO] 解压中...
    powershell -Command "& { Expand-Archive -Path '%TEMP%\node.zip' -DestinationPath '%TEMP%\node-extract' -Force }"
    xcopy "%TEMP%\node-extract\node-%NODE_VERSION%-win-x64\*" "%NODE_DIR%\" /E /I /Y /Q
    
    del "%TEMP%\node.zip" >nul 2>&1
    rmdir /s /q "%TEMP%\node-extract" >nul 2>&1
    
    echo [INFO] Node.js 安装完成
)

for /f "tokens=*" %%v in ('"%NODE_BIN%" --version 2^>nul') do set NODE_VERSION_INSTALLED=%%v
echo [CHECK] Node.js 版本: %NODE_VERSION_INSTALLED%

:: ========================================
:: Step 3: 克隆 OpenClaw
:: ========================================
echo.
echo [STEP] 安装 OpenClaw...

set "OPENCLAW_DIR=%USB_ROOT%\openclaw"

if exist "%OPENCLAW_DIR%" (
    echo [WARN] OpenClaw 已存在，跳过克隆
) else (
    if "%USE_GIT%"=="1" (
        echo [INFO] 克隆 OpenClaw 仓库...
        git clone --depth 1 --branch "v%OPENCLAW_VERSION%" ^
            https://github.com/openclaw/openclaw.git "%OPENCLAW_DIR%"
    ) else (
        echo [INFO] 下载 OpenClaw 压缩包...
        powershell -Command "& { Invoke-WebRequest -Uri 'https://github.com/openclaw/openclaw/archive/refs/tags/v%OPENCLAW_VERSION%.zip' -OutFile '%TEMP%\openclaw.zip' }"
        powershell -Command "& { Expand-Archive -Path '%TEMP%\openclaw.zip' -DestinationPath '%TEMP%\openclaw-extract' -Force }"
        move "%TEMP%\openclaw-extract\openclaw-%OPENCLAW_VERSION%" "%OPENCLAW_DIR%"
        del "%TEMP%\openclaw.zip" >nul 2>&1
    )
    echo [INFO] OpenClaw 安装完成
)

:: ========================================
:: Step 4: 安装 OpenClaw 依赖
:: ========================================
echo.
echo [STEP] 安装 OpenClaw 依赖...

cd /d "%OPENCLAW_DIR%"

if exist "node_modules" (
    echo [WARN] 依赖已存在，跳过安装
) else (
    echo [INFO] 安装 npm 依赖...
    call "%NODE_DIR%\npm.cmd" install --production
    echo [INFO] 依赖安装完成
)

:: ========================================
:: Step 5: 创建配置文件
:: ========================================
echo.
echo [STEP] 创建配置文件...

set "CONFIG_DIR=%USB_ROOT%\data\config"
mkdir "%CONFIG_DIR%" >nul 2>&1

if not exist "%CONFIG_DIR%\openclaw.json" (
    (
        echo {
        echo   "port": 3000,
        echo   "model": {
        echo     "default": "zai/glm-5"
        echo   },
        echo   "cacheTTL": 3600000,
        echo   "workspace": "%USB_ROOT:\=\\%\\data\\workspace",
        echo   "memory": {
        echo     "dir": "%USB_ROOT:\=\\%\\data\\memory"
        echo   }
        echo }
    ) > "%CONFIG_DIR%\openclaw.json"
    echo [INFO] 配置文件已创建
) else (
    echo [WARN] 配置文件已存在，跳过
)

:: ========================================
:: Step 6: 验证安装
:: ========================================
echo.
echo [STEP] 验证安装...

set ERRORS=0

:: 检查 Node.js
if exist "%NODE_BIN%" (
    echo [CHECK] ✅ Node.js: %NODE_VERSION_INSTALLED%
) else (
    echo [ERROR] ❌ Node.js 未安装
    set /a ERRORS+=1
)

:: 检查 OpenClaw
if exist "%OPENCLAW_DIR%\bin\openclaw.cmd" (
    echo [CHECK] ✅ OpenClaw: 已安装
) else (
    echo [ERROR] ❌ OpenClaw 未安装
    set /a ERRORS+=1
)

:: 检查配置
if exist "%CONFIG_DIR%\openclaw.json" (
    echo [CHECK] ✅ 配置文件: 已创建
) else (
    echo [ERROR] ❌ 配置文件未创建
    set /a ERRORS+=1
)

:: 检查依赖
if exist "%OPENCLAW_DIR%\node_modules" (
    for /f %%i in ('dir /b /a:d "%OPENCLAW_DIR%\node_modules" 2^>nul ^| find /c /v ""') do set DEP_COUNT=%%i
    echo [CHECK] ✅ 依赖包: %DEP_COUNT% 个
) else (
    echo [ERROR] ❌ 依赖未安装
    set /a ERRORS+=1
)

:: ========================================
:: 完成
:: ========================================
echo.
if %ERRORS% equ 0 (
    echo ========================================
    echo   ✅ 安装完成！
    echo ========================================
    echo.
    echo 磁盘占用：
    dir /s "%USB_ROOT%\node-portable" 2>nul | find "File(s)"
    dir /s "%USB_ROOT%\openclaw" 2>nul | find "File(s)"
    echo.
    echo [INFO] 现在可以双击 start.bat 启动 OpenClaw
) else (
    echo ========================================
    echo   ⚠️  安装完成，但有 %ERRORS% 个错误
    echo ========================================
    echo.
    echo [WARN] 请检查上面的错误信息
)

echo.
pause
