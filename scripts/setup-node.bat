@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

title 预置 Node.js 便携版

:: ========================================
:: 预置 Node.js 便携版
:: ========================================

set "USB_ROOT=%~dp0"
set "USB_ROOT=%USB_ROOT:~0,-1%"
set "NODE_VERSION=v22.22.0"

echo.
echo ========================================
echo   预置 Node.js 便携版
echo ========================================
echo.
echo [INFO] 版本: %NODE_VERSION%
echo.

:: 询问要下载哪些平台
echo 请选择要预置的平台：
echo   1) Windows (x64)
echo   2) Linux (x64)
echo   3) macOS (x64)
echo   4) 全部平台
echo   0) 退出
echo.
set /p choice="请输入选项 [0-4]: "

if "%choice%"=="0" (
    echo [INFO] 已退出
    pause
    exit /b 0
)

if "%choice%"=="1" (
    set "PLATFORMS=windows"
    goto :download
)
if "%choice%"=="2" (
    set "PLATFORMS=linux"
    goto :download
)
if "%choice%"=="3" (
    set "PLATFORMS=darwin"
    goto :download
)
if "%choice%"=="4" (
    set "PLATFORMS=windows linux darwin"
    goto :download
)

echo [ERROR] 无效选项
pause
exit /b 1

:download

echo.

:: 检查 PowerShell 是否可用
where powershell >nul 2>&1
if errorlevel 1 (
    echo [ERROR] 需要 PowerShell 来下载 Node.js
    pause
    exit /b 1
)

:: 下载函数
for %%p in (%PLATFORMS%) do (
    call :download_platform %%p
)

:: 显示结果
echo.
echo ========================================
echo   预置完成！
echo ========================================
echo.
echo 已安装平台：
for %%p in (%PLATFORMS%) do (
    if "%%p"=="windows" (
        if exist "%USB_ROOT%\node-portable\%%p\node.exe" (
            echo   ✅ %%p - installed
        )
    ) else (
        if exist "%USB_ROOT%\node-portable\%%p\bin\node" (
            echo   ✅ %%p - installed
        )
    )
)
echo.
echo 磁盘占用：
for /f "tokens=3" %%a in ('dir /s "%USB_ROOT%\node-portable" ^| find "File(s)"') do set SIZE=%%a
echo   %SIZE%
echo.
echo [INFO] 现在可以双击 start.bat 启动 OpenClaw
echo.
pause
exit /b 0

:: ========================================
:: 下载单个平台
:: ========================================
:download_platform

set PLATFORM=%1
set NODE_DIR=%USB_ROOT%\node-portable\%PLATFORM%

echo [STEP] 下载 %PLATFORM% 版本...

if "%PLATFORM%"=="windows" (
    set URL=https://nodejs.org/dist/%NODE_VERSION%/node-%NODE_VERSION%-win-x64.zip
    set EXT=zip
) else if "%PLATFORM%"=="linux" (
    set URL=https://nodejs.org/dist/%NODE_VERSION%/node-%NODE_VERSION%-linux-x64.tar.gz
    set EXT=tar.gz
) else if "%PLATFORM%"=="darwin" (
    set URL=https://nodejs.org/dist/%NODE_VERSION%/node-%NODE_VERSION%-darwin-x64.tar.gz
    set EXT=tar.gz
)

echo   URL: %URL%
echo.

:: 检查是否已存在
if "%PLATFORM%"=="windows" (
    set NODE_BIN=%NODE_DIR%\node.exe
) else (
    set NODE_BIN=%NODE_DIR%\bin\node
)

if exist "%NODE_BIN%" (
    echo [WARN] %PLATFORM% 版本已存在，跳过下载
    echo.
    exit /b 0
)

:: 创建目录
if not exist "%NODE_DIR%" mkdir "%NODE_DIR%"

:: 下载
echo [INFO] 下载中...
powershell -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%URL%' -OutFile '%TEMP%\node-%PLATFORM%.%EXT%' -UseBasicParsing }"
if errorlevel 1 (
    echo [ERROR] 下载失败
    exit /b 1
)

:: 解压
echo [STEP] 解压中...

if "%PLATFORM%"=="windows" (
    powershell -Command "& { Expand-Archive -Path '%TEMP%\node-%PLATFORM%.%EXT%' -DestinationPath '%TEMP%\node-extract-%PLATFORM%' -Force }"
    xcopy "%TEMP%\node-extract-%PLATFORM%\node-%NODE_VERSION%-win-x64\*" "%NODE_DIR%\" /E /I /Y /Q
) else (
    :: Linux/macOS 在 Windows 上解压需要 7-Zip 或 WSL
    echo [WARN] Linux/macOS 版本需要在对应系统上解压
    echo [INFO] 已下载到: %TEMP%\node-%PLATFORM%.%EXT%
    echo [INFO] 请在 Linux/macOS 系统上运行 setup-node.sh
)

:: 清理
del "%TEMP%\node-%PLATFORM%.%EXT%" >nul 2>&1
rmdir /s /q "%TEMP%\node-extract-%PLATFORM%" >nul 2>&1

echo [INFO] %PLATFORM% 版本安装完成
echo.

exit /b 0
