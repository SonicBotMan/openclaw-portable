@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title OpenClaw Portable v7 - Restart Gateway
rem ASCII output on purpose (code-page safe).

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "NODE=%SCRIPT_DIR%\node\node.exe"
set "OPENCLAW_MJS=%SCRIPT_DIR%\openclaw-pkg\node_modules\openclaw\openclaw.mjs"
set "DATA_DIR=%SCRIPT_DIR%\data"
set "STATE_DIR=%DATA_DIR%\.openclaw"
set "GW_PORT=18789"

echo.
echo ==========================================
echo   OpenClaw Portable v7 - Restart
echo ==========================================
echo.

rem [1/3] stop only THIS portable tree's processes (never a system-wide taskkill)
echo [1/3] Stopping gateway + Ollama (this portable only)...
"%NODE%" "%SCRIPT_DIR%\scripts\stop.js" "%SCRIPT_DIR%"
timeout /t 2 /nobreak >nul

rem [2/3] port
echo [2/3] Checking ports...
netstat -aon 2>nul | findstr /r "LISTENING" | findstr /r /c:":%GW_PORT% " >nul
if not errorlevel 1 (
  set "GW_PORT=18790"
)

rem [3/3] start with a fresh token (same flow as start.bat)
echo [3/3] Starting gateway on port %GW_PORT% ...
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"
set "GW_TOKEN="
for /f "tokens=*" %%t in ('"%NODE%" -e "console.log(require('crypto').randomBytes(24).toString('hex'))"') do set "GW_TOKEN=%%t"
start "OpenClaw Gateway" /b "%NODE%" "%OPENCLAW_MJS%" gateway run --port %GW_PORT% --allow-unconfigured --bind loopback --token %GW_TOKEN% >> "%DATA_DIR%\gateway.log" 2>&1

echo.
echo Waiting for gateway...
for /l %%i in (1,1,30) do (
  curl.exe -sf "http://127.0.0.1:%GW_PORT%/health" >nul 2>&1 && goto :healthy
  timeout /t 1 /nobreak >nul
)
echo [ERROR] Gateway not healthy in 30s - check data\gateway.log
pause
exit /b 1

:healthy
echo.
echo [OK]   Gateway restarted.
echo       UI: http://localhost:%GW_PORT%/?token=%GW_TOKEN%
start "" "http://localhost:%GW_PORT%/?token=%GW_TOKEN%"
pause
