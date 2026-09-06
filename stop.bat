@echo off
setlocal
title OpenClaw Portable v7 - Stop
chcp 65001 >nul

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "NODE=%SCRIPT_DIR%\node\node.exe"

echo.
echo ==========================================
echo   OpenClaw Portable v7 - Stopping
echo ==========================================
echo.

if not exist "%NODE%" (
  echo [WARN] node\node.exe not found - cannot run the stop helper.
  echo        Make sure nothing is still running, then close all windows.
  pause & exit /b 1
)

echo [1/2] Stopping gateway + Ollama (only processes from this folder)...
"%NODE%" "%SCRIPT_DIR%\scripts\stop.js" "%SCRIPT_DIR%"
if errorlevel 1 (
  echo [WARN] stop helper reported an error - checking ports anyway...
)

echo [2/2] Verifying ports are released...
set "VERIFY_FAIL=0"
for %%p in (18789 18790 11434 11435) do (
  netstat -aon 2>nul | findstr /r "LISTENING" | findstr /r /c:":%%p " >nul
  if not errorlevel 1 (
    echo [WARN] Port %%p is still in use.
    set "VERIFY_FAIL=1"
  )
)
if "%VERIFY_FAIL%"=="1" (
  echo.
  echo Some ports are still busy. If you started OpenClaw manually,
  echo end the related node/ollama processes in Task Manager.
) else (
  echo [OK]   All ports released.
)

echo.
echo ==========================================
echo   OpenClaw stopped.
echo   data\ (config, sessions, model store) preserved.
echo   Use cleanup.bat to remove API keys / zero-trace before
echo   removing the USB drive.
echo ==========================================
echo.
pause
