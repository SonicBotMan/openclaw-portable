@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title OpenClaw Portable v7

rem ============================================
rem  OpenClaw Portable v7 - one-click start
rem  Output is English on purpose: this file stays
rem  pure ASCII so it never breaks on Chinese
rem  Windows code pages (root cause pattern of #57).
rem
rem  Layout (shipped by CI, see VERSIONS):
rem    node\                 Node.js (bundled)
rem    openclaw-pkg\         openclaw (pinned, offline install verified)
rem    ollama\               Ollama (bundled, CPU-only)
rem    models\               qwen3:1.7b GGUF + Modelfile (model package)
rem    data\                 created at runtime (state, logs, model store)
rem ============================================

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "NODE=%SCRIPT_DIR%\node\node.exe"
set "OPENCLAW_MJS=%SCRIPT_DIR%\openclaw-pkg\node_modules\openclaw\openclaw.mjs"
set "OLLAMA_EXE=%SCRIPT_DIR%\ollama\ollama.exe"
set "DATA_DIR=%SCRIPT_DIR%\data"
set "STATE_DIR=%DATA_DIR%\.openclaw"
set "MODEL_STORE=%DATA_DIR%\ollama-models"
set "TEMPLATE=%SCRIPT_DIR%\config\openclaw.json"
set "MODEL_ID=qwen3:1.7b"
rem NOTE: file names use a dash (NTFS forbids ':') - Ollama TAGS keep the colon
set "MODEL_FILE=qwen3-1.7b"
set "MODEL_PRIMARY=ollama/qwen3:1.7b"
set "LOCAL_MODEL=1"
set "GW_PORT=18789"
set "OL_PORT=11434"

echo.
echo ==========================================
echo   OpenClaw Portable v7 - Starting
echo ==========================================
echo.

if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"
if not exist "%STATE_DIR%" mkdir "%STATE_DIR%"
if not exist "%DATA_DIR%\workspace" mkdir "%DATA_DIR%\workspace"

rem ---- [0/6] locate free ports (corrected logic, issue #56) ----
call :port_in_use %GW_PORT%
if not errorlevel 1 (
  echo [INFO] Gateway port %GW_PORT% is busy, using 18790 instead
  set "GW_PORT=18790"
)
call :port_in_use %OL_PORT%
if not errorlevel 1 (
  echo [INFO] Ollama port %OL_PORT% is busy, using 11435 instead
  set "OL_PORT=11435"
)

rem ---- [1/6] core files + install smoke test ----
echo [1/6] Checking core files...
if not exist "%NODE%" (
  echo [ERROR] node\node.exe not found - this package is incomplete.
  echo         Re-download the core package from the GitHub releases.
  pause & exit /b 1
)
if not exist "%OPENCLAW_MJS%" (
  echo [ERROR] openclaw entry not found at openclaw-pkg\node_modules\openclaw\openclaw.mjs
  echo         Re-download the core package from the GitHub releases.
  pause & exit /b 1
)
"%NODE%" "%OPENCLAW_MJS%" --version >nul 2>&1
if errorlevel 1 (
  echo [ERROR] "openclaw --version" failed. The package is incomplete or the
  echo         install scripts did not run (see issue #58, P0). Re-download
  echo         the core package from the GitHub releases.
  pause & exit /b 1
)
for /f "tokens=*" %%v in ('"%NODE%" "%OPENCLAW_MJS%" --version 2^>nul') do echo [OK]   OpenClaw %%v (pinned version, offline install verified)

rem ---- [2/6] ollama server + bundled model ----
echo [2/6] Local model backend (Ollama)...
if not exist "%OLLAMA_EXE%" goto :no_local_model
if not exist "%MODEL_STORE%" mkdir "%MODEL_STORE%"
set "OLLAMA_MODELS=%MODEL_STORE%"
set "OLLAMA_HOST=http://127.0.0.1:%OL_PORT%"
call :port_in_use %OL_PORT%
if errorlevel 1 (
  echo [INFO] Starting bundled Ollama on port %OL_PORT% ...
  start "Ollama" /b "%OLLAMA_EXE%" serve >"%DATA_DIR%\ollama.log" 2>&1
  call :poll_http %OL_PORT% /api/version 30
  if errorlevel 1 (
    echo [WARN] Ollama did not start (see data\ollama.log). Falling back to cloud mode.
    goto :no_local_model
  )
)
"%OLLAMA_EXE%" list 2>nul | findstr /i "%MODEL_ID%" >nul
if not errorlevel 1 (
  echo [OK]   Model %MODEL_ID% already imported
  goto :model_ready
)
rem Assemble split GGUF parts (part1..partN) into data\ (package may be read-only)
set "GGUF=%DATA_DIR%\%MODEL_FILE%.Q4_K_M.gguf"
if exist "%SCRIPT_DIR%\models\%MODEL_FILE%.Q4_K_M.gguf.part1" (
  echo [INFO] Assembling model from split parts...
  set "PARTS=""%SCRIPT_DIR%\models\%MODEL_FILE%.Q4_K_M.gguf.part1"""
  for /l %%p in (2,1,32) do (
    if exist "%SCRIPT_DIR%\models\%MODEL_FILE%.Q4_K_M.gguf.part%%p" set "PARTS=!PART! "%SCRIPT_DIR%\models\%MODEL_FILE%.Q4_K_M.gguf.part%%p"""
  )
  "%NODE%" "%SCRIPT_DIR%\scripts\assemble.js" "%GGUF%" !PARTS!
)
if not exist "%GGUF%" (
  if exist "%SCRIPT_DIR%\models\%MODEL_FILE%.Q4_K_M.gguf" set "GGUF=%SCRIPT_DIR%\models\%MODEL_FILE%.Q4_K_M.gguf"
)
if not exist "%GGUF%" (
  echo [WARN] Model files not found (models\%MODEL_FILE%.Q4_K_M.gguf[.part1/.part2]).
  echo        You have the CORE package only. Download the model package too,
  echo        or configure a cloud API key with apply-config.bat.
  goto :no_local_model
)
echo [INFO] Importing model (one-time, a few seconds, no download)...
"%NODE%" "%SCRIPT_DIR%\scripts\import-model.js" "%OLLAMA_EXE%" "%SCRIPT_DIR%\models\Modelfile.qwen3-1.7b" "%GGUF%" "%MODEL_ID%"
if errorlevel 1 (
  echo [WARN] Model import failed (see messages above). Falling back to cloud mode.
  goto :no_local_model
)
:model_ready
echo [OK]   Local model ready: %MODEL_ID% (fully offline)
goto :local_done

:no_local_model
set "LOCAL_MODEL=0"
set "MODEL_PRIMARY=openai/gpt-5.6-sol"
echo [INFO] Running in CLOUD mode - configure your API key with apply-config.bat
:local_done

rem ---- [3/6] gateway token (random per boot, never written to disk) ----
echo [3/6] Generating gateway token...
set "GW_TOKEN="
for /f "tokens=*" %%t in ('"%NODE%" -e "console.log(require('crypto').randomBytes(24).toString('hex'))"') do set "GW_TOKEN=%%t"
if not defined GW_TOKEN (
  echo [ERROR] Could not generate a gateway token.
  pause & exit /b 1
)

rem ---- [4/6] materialize config from template ----
echo [4/6] Writing config...
"%NODE%" "%SCRIPT_DIR%\scripts\set-portable-config.js" "%TEMPLATE%" "%STATE_DIR%" "%GW_PORT%" "%OL_PORT%" "%MODEL_PRIMARY%"
if errorlevel 1 (
  echo [ERROR] Config generation failed.
  pause & exit /b 1
)

rem ---- [5/6] gateway ----
echo [5/6] Starting OpenClaw gateway on port %GW_PORT% ...
start "OpenClaw Gateway" /b "%NODE%" "%OPENCLAW_MJS%" gateway run --port %GW_PORT% --allow-unconfigured --bind loopback --token %GW_TOKEN% >> "%DATA_DIR%\gateway.log" 2>&1
call :poll_http %GW_PORT% /health 60
if errorlevel 1 (
  echo [ERROR] Gateway did not become healthy in 60s. Last log lines:
  powershell -NoProfile -Command "Get-Content '%DATA_DIR%\gateway.log' -Tail 10 -ErrorAction SilentlyContinue"
  pause & exit /b 1
)
echo [OK]   Gateway is live (health check passed)

rem ---- [6/6] open UI ----
echo [6/6] Opening dashboard...
echo.
echo ==========================================
echo   OpenClaw is ready.
echo ==========================================
if "%LOCAL_MODEL%"=="1" goto :print_mode_local
echo   Mode:  Cloud API (configure key with apply-config.bat)
goto :print_done
:print_mode_local
echo   Mode:  Local offline model (%MODEL_ID%)
:print_done
echo   UI:    http://localhost:%GW_PORT%/?token=%GW_TOKEN%
echo   Stop:  stop.bat  (or just close this window)
echo ==========================================
echo.
start "" "http://localhost:%GW_PORT%/?token=%GW_TOKEN%"

:keep_running
timeout /t 5 /nobreak >nul
call :port_in_use %GW_PORT%
if errorlevel 1 (
  echo [ERROR] Gateway stopped unexpectedly. Last log lines:
  powershell -NoProfile -Command "Get-Content '%DATA_DIR%\gateway.log' -Tail 15 -ErrorAction SilentlyContinue"
  pause
  exit /b 1
)
goto keep_running

rem ============================================
rem  helpers
rem ============================================
rem :port_in_use <port> - returns 0 if something is LISTENING on <port>
:port_in_use
set "PI_PORT=%~1"
netstat -aon 2>nul | findstr /r "LISTENING" | findstr /r /c:":%PI_PORT% " >nul
exit /b %errorlevel%

rem :poll_http <port> <path> <tries> - poll http://127.0.0.1:<port><path>, once per second
:poll_http
set "PH_PORT=%~1"
set "PH_PATH=%~2"
set "PH_TRIES=%~3"
if "%PH_TRIES%"=="" set "PH_TRIES=30"
set /a PH_I=0
:ph_loop
curl.exe -sf "http://127.0.0.1:!PH_PORT!!PH_PATH!" >nul 2>&1
if not errorlevel 1 exit /b 0
set /a PH_I+=1
if !PH_I! geq !PH_TRIES! exit /b 1
timeout /t 1 /nobreak >nul
goto ph_loop
