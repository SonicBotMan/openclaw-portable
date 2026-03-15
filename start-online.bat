@echo off
setlocal enabledelayedexpansion
title OpenClaw Portable v5.0 (Online)

echo.
echo ==========================================
echo   OpenClaw Portable v5.0 - Online Edition
echo   First run requires internet (~60MB)
echo ==========================================
echo.

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "NODE_EXE=%SCRIPT_DIR%\node\node.exe"
set "NPM_CLI=%SCRIPT_DIR%\node\node_modules\npm\bin\npm-cli.js"
set "OPENCLAW_ENTRY=%SCRIPT_DIR%\openclaw-pkg\node_modules\openclaw\bin\openclaw"
set "GATEWAY_PORT=18789"

rem ============================================
rem [1/4] Download Node.js (if needed)
rem ============================================
echo [1/4] Checking Node.js...

if exist "%NODE_EXE%" (
    for /f "tokens=*" %%v in ('"%NODE_EXE%" --version 2^>^&1') do echo [OK]  Node.js %%v already exists
    goto :check_openclaw
)

echo [INFO] Node.js not found, downloading (~30MB)...
echo [INFO] Using China mirror for faster download...

set "NODE_URL=https://npmmirror.com/mirrors/node/v22.16.0/node-v22.16.0-win-x64.zip"

rem Use Windows 10+ built-in curl.exe
curl -fsSL "%NODE_URL%" -o "%SCRIPT_DIR%\node.zip"

if errorlevel 1 (
    echo [ERROR] Download failed
    echo         Please check your internet connection
    pause
    exit /b 1
)

echo [INFO] Extracting...
powershell -NoProfile -Command "Expand-Archive -Path '%SCRIPT_DIR%\node.zip' -DestinationPath '%SCRIPT_DIR%\node_tmp' -Force"
move "%SCRIPT_DIR%\node_tmp\node-v22.16.0-win-x64" "%SCRIPT_DIR%\node"
del /f /q "%SCRIPT_DIR%\node.zip"
rd /s /q "%SCRIPT_DIR%\node_tmp"

for /f "tokens=*" %%v in ('"%NODE_EXE%" --version 2^>^&1') do echo [OK]  Node.js %%v downloaded

:check_openclaw
rem ============================================
rem [2/4] Install OpenClaw (if needed)
rem ============================================
echo.
echo [2/4] Checking OpenClaw...

if exist "%OPENCLAW_ENTRY%" (
    echo [OK]  OpenClaw already exists
    goto :check_port
)

echo [INFO] OpenClaw not found, installing (~30MB)...
echo [INFO] Using China mirror for faster download...

mkdir "%SCRIPT_DIR%\openclaw-pkg"

"%NODE_EXE%" "%NPM_CLI%" install -g openclaw --prefix "%SCRIPT_DIR%\openclaw-pkg" --registry https://registry.npmmirror.com

if errorlevel 1 (
    echo [ERROR] Installation failed
    echo         Please check your internet connection
    pause
    exit /b 1
)

echo [OK]  OpenClaw installed

:check_port
rem ============================================
rem [3/4] Check port
rem ============================================
echo.
echo [3/4] Checking port...

netstat -aon 2>nul | findstr ":%GATEWAY_PORT%" | findstr "LISTENING" >nul
if not errorlevel 1 (
    echo [WARN] Port %GATEWAY_PORT% is in use, trying backup port...
    set "GATEWAY_PORT=18790"
)

echo [OK]  Using port %GATEWAY_PORT%

rem ============================================
rem [4/4] Start
rem ============================================
echo.
echo [4/4] Starting OpenClaw Gateway...
echo.
echo   Access: http://localhost:%GATEWAY_PORT%
echo   Stop: Run stop.bat
echo.
echo ==========================================
echo.

if not exist "%SCRIPT_DIR%\data" mkdir "%SCRIPT_DIR%\data"

"%NODE_EXE%" "%OPENCLAW_ENTRY%" gateway run --port %GATEWAY_PORT%

echo.
if errorlevel 1 (
    echo [ERROR] Startup failed
) else (
    echo [INFO] Stopped
)
pause
