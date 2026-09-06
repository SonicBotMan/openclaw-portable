@echo off
rem ============================================
rem  OpenClaw Portable v7 - zero-trace cleanup
rem  (issue #43: safe to remove USB drive)
rem  English output on purpose (ASCII-safe file).
rem ============================================
setlocal enabledelayedexpansion
title OpenClaw Portable v7 - Cleanup
chcp 65001 >nul

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "DATA_DIR=%SCRIPT_DIR%\data"
set "STATE_DIR=%DATA_DIR%\.openclaw"

echo.
echo ==========================================
echo   OpenClaw Portable v7 - Cleanup
echo ==========================================
echo.

echo [Scan] Checking for user data and sensitive files...
set "HAS=0"
if exist "%STATE_DIR%" (
    set "HAS=1"
    echo   [!] data\.openclaw (config incl. API keys, sessions, auth)
)
if exist "%DATA_DIR%\workspace" (
    set "HAS=1"
    echo   [!] data\workspace (agent workspace files)
)
for %%f in ("%DATA_DIR%\gateway.log" "%DATA_DIR%\ollama.log") do (
    if exist "%%f" (
        set "HAS=1"
        echo   [!] %%~f (runtime log)
    )
)
if exist "%DATA_DIR%\qwen3:1.7b.Q4_K_M.gguf" echo   [info] data\qwen3:1.7b.Q4_K_M.gguf (assembled model - public data, kept by default)

if "%HAS%"=="0" (
    echo.
    echo [OK] No user data found. Safe to remove the drive.
    echo.
    pause
    exit /b 0
)

echo.
echo Choose cleanup level:
echo.
echo   [1] Light  - logs only
echo   [2] Deep   - ALL user data (API keys, sessions, workspace)
echo   [3] Cancel
echo.
set /p "Choice (1-3): " CHOICE

if "%CHOICE%"=="1" goto LIGHT
if "%CHOICE%"=="2" goto DEEP
goto END

:LIGHT
echo [Cleaning] Logs...
if exist "%DATA_DIR%\gateway.log" del /f /q "%DATA_DIR%\gateway.log"
if exist "%DATA_DIR%\ollama.log" del /f /q "%DATA_DIR%\ollama.log"
echo [Done] Light cleanup - config and sessions preserved.
goto END

:DEEP
echo.
set /p "Deep cleanup removes ALL config incl. API keys. Confirm? (yes/N): " CONFIRM
if /i not "%CONFIRM%"=="yes" goto END
echo [Cleaning] All user data...
if exist "%STATE_DIR%" rd /s /q "%STATE_DIR%"
if exist "%DATA_DIR%\workspace" rd /s /q "%DATA_DIR%\workspace"
if exist "%DATA_DIR%\gateway.log" del /f /q "%DATA_DIR%\gateway.log"
if exist "%DATA_DIR%\ollama.log" del /f /q "%DATA_DIR%\ollama.log"
echo [Done] Deep cleanup - next start regenerates config fresh.

:END
echo.
echo [OK] Cleanup complete. Safe to remove the drive.
echo     (data\ollama-models and the bundled model are public model files - kept.)
echo.
pause
exit /b 0
