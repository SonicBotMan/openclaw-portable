@echo off
setlocal enabledelayedexpansion
title OpenClaw Portable v6.0.0

echo.
echo ==========================================
echo   OpenClaw Portable v6.0.0 - Offline Edition
echo   Built-in Local Model Support
echo ==========================================
echo.

rem === Resolve script directory ===
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

rem === Path configuration ===
set "NODE_EXE=%SCRIPT_DIR%\node\node.exe"
set "OPENCLAW_ENTRY_LINUX=%SCRIPT_DIR%\openclaw-pkg\lib\node_modules\openclaw\openclaw.mjs"
set "OPENCLAW_ENTRY_WINDOWS=%SCRIPT_DIR%\openclaw-pkg\node_modules\openclaw\openclaw.mjs"

if exist "%OPENCLAW_ENTRY_LINUX%" (
    set "OPENCLAW_ENTRY=%OPENCLAW_ENTRY_LINUX%"
    echo [INFO] Using Linux npm path
) else if exist "%OPENCLAW_ENTRY_WINDOWS%" (
    set "OPENCLAW_ENTRY=%OPENCLAW_ENTRY_WINDOWS%"
    echo [INFO] Using Windows npm path
) else (
    set "OPENCLAW_ENTRY=%OPENCLAW_ENTRY_LINUX%"
)

set "OPENCLAW_HOME=%SCRIPT_DIR%\data"
set "GATEWAY_PORT=18789"
set "LLM_PORT=18080"
set "PATH=%SCRIPT_DIR%\node;%PATH%"

echo [INFO] Script dir : %SCRIPT_DIR%
echo [INFO] Node dir   : %SCRIPT_DIR%\node
echo [INFO] Data dir   : %OPENCLAW_HOME%
echo.

rem ============================================
rem [0/6] 权限和端口检测（Issue #43）
rem ============================================
echo [0/6] Checking permissions and ports...
echo.

rem === 检测管理员权限（Windows） ===
net session >nul 2>&1
if errorlevel 1 (
    echo [WARN] Not running as Administrator
    echo        Some features may be limited
    echo        Recommend: Right-click ^> Run as Administrator
    echo.
    set /p "Continue? (y/N): " CONTINUE
    if /i not "!CONTINUE!"=="y" (
        echo [ABORT] Cancelled by user
        exit /b 0
    )
) else (
    echo [OK] Running with Administrator privileges
)
echo.

rem === 检测端口冲突 ===
set PORT_CONFLICT=0

echo Checking port %GATEWAY_PORT% (Gateway)...
netstat -ano | findstr ":%GATEWAY_PORT%" | findstr "LISTENING" >nul 2>&1
if errorlevel 0 (
    echo [ERROR] Port %GATEWAY_PORT% is already in use
    set PORT_CONFLICT=1
) else (
    echo [OK] Port %GATEWAY_PORT% is available
)

if exist "%LLM_BIN%" if exist "%LLM_MODEL%" (
    echo Checking port %LLM_PORT% (LLM)...
    netstat -ano | findstr ":%LLM_PORT%" | findstr "LISTENING" >nul 2>&1
    if errorlevel 0 (
        echo [ERROR] Port %LLM_PORT% is already in use
        set PORT_CONFLICT=1
    ) else (
        echo [OK] Port %LLM_PORT% is available
    )
)

if !PORT_CONFLICT!==0 (
    echo.
    echo [WARN] Port conflicts detected!
    echo        1. Stop the processes using these ports
    echo        2. Or change port numbers in configuration
    echo.
    set /p "Continue anyway? (y/N): " CONTINUE
    if /i not "!CONTINUE!"=="y" (
        echo [ABORT] Cancelled by user
        exit /b 0
    )
)
echo.

rem ============================================
rem [1/6] Check Node.js
rem ============================================
echo [1/6] Checking Node.js...

if not exist "%NODE_EXE%" (
    echo.
    echo [ERROR] node\node.exe not found!
    echo.
    echo This is an OFFLINE package. Node.js should be pre-bundled.
    echo Please verify you downloaded the correct offline package.
    echo.
    echo If you want to use online bootstrap mode, use: start-online.bat
    echo.
    pause
    exit /b 1
)

for /f "tokens=*" %%v in ('"%NODE_EXE%" --version 2^>^&1') do set NODE_VER=%%v
echo [OK]  Node.js !NODE_VER! is ready

rem ============================================
rem [2/6] Check OpenClaw
rem ============================================
echo.
echo [2/6] Checking OpenClaw...

if not exist "%OPENCLAW_ENTRY%" (
    echo.
    echo [ERROR] openclaw.mjs not found!
    echo.
    echo This is an OFFLINE package. OpenClaw should be pre-bundled.
    echo Please verify you downloaded the correct offline package.
    echo.
    pause
    exit /b 1
)

echo [OK]  OpenClaw is ready

rem ============================================
rem [NEW 3/6] Start bundled llama-server
rem ============================================
echo.
echo [3/6] Starting bundled local model...

set "LLM_BIN=%SCRIPT_DIR%\llm\bin\llama-server-win32-avx2.exe"
set "LLM_MODEL=%SCRIPT_DIR%\llm\models\qwen2.5-1.5b-instruct-q4_k_m.gguf"
set "LLM_LOG=%SCRIPT_DIR%\llm\server.log"
set LLM_BUNDLED_READY=0

if exist "%LLM_BIN%" if exist "%LLM_MODEL%" (
    rem Check if port is already in use
    netstat -ano 2>nul | findstr ":%LLM_PORT%" | findstr "LISTENING" >nul
    if errorlevel 1 (
        rem Calculate threads (logical processors - 1, min 1)
        for /f "tokens=2" %%i in ('wmic cpu get NumberOfLogicalProcessors /value ^| find "="') do set /a THREADS=%%i-1
        if !THREADS! LSS 1 set THREADS=1
        
        rem Start llama-server in background
        start /b "" "%LLM_BIN%" --model "%LLM_MODEL%" --port %LLM_PORT% --host 127.0.0.1 --ctx-size 32768 --threads !THREADS! --parallel 1 -ngl 0 --log-disable >> "%LLM_LOG%" 2>&1
        
        echo [OK]  llama-server started on port %LLM_PORT% (threads: !THREADS!)
        echo [INFO] Model loading, first response may take 5-15 seconds...
        set LLM_BUNDLED_READY=1
    ) else (
        echo [OK]  Bundled model already running on port %LLM_PORT%
        set LLM_BUNDLED_READY=1
    )
) else (
    echo [WARN] Bundled model not found, skipping (cloud API still available)
    echo [INFO] Model path: %LLM_MODEL%
    echo [INFO] Binary path: %LLM_BIN%
    set LLM_BUNDLED_READY=0
)

rem ============================================
rem [4/6] Check port availability
rem ============================================
echo.
echo [4/6] Checking port...

netstat -aon 2>nul | findstr ":%GATEWAY_PORT%" | findstr "LISTENING" >nul
if not errorlevel 1 (
    echo [WARN] Port %GATEWAY_PORT% is in use, trying backup port 18790...
    set "GATEWAY_PORT=18790"
    netstat -aon 2>nul | findstr ":18790" | findstr "LISTENING" >nul
    if not errorlevel 1 (
        echo [ERROR] Fallback port 18790 is also in use.
        echo         Please edit GATEWAY_PORT in start.bat manually.
        pause
        exit /b 1
    )
)

echo [OK]  Port %GATEWAY_PORT% is available

rem ============================================
rem [5/6] Setup environment
rem ============================================
echo.
echo [5/6] Setting up environment...

if not exist "%SCRIPT_DIR%\data" mkdir "%SCRIPT_DIR%\data"
if not exist "%SCRIPT_DIR%\workspace" mkdir "%SCRIPT_DIR%\workspace"
if not exist "%SCRIPT_DIR%\temp" mkdir "%SCRIPT_DIR%\temp"
if not exist "%SCRIPT_DIR%\llm" mkdir "%SCRIPT_DIR%\llm"

echo [OK]  Environment is ready

rem [NEW] Inject bundled model config
if !LLM_BUNDLED_READY! EQU 1 (
    echo.
    echo [5.5/6] Configuring bundled model...
    
    rem Check if user has configured a primary model
    "%NODE_EXE%" -e "try{const cfg=JSON.parse(require('fs').readFileSync('%OPENCLAW_HOME%\.openclaw\openclaw.json','utf8'));console.log(cfg?.agents?.defaults?.model?.primary?'yes':'no')}catch(e){console.log('no')}" >nul 2>&1
    if errorlevel 1 (
        set HAS_PRIMARY=no
    ) else (
        for /f "tokens=*" %%i in ('"%NODE_EXE%" -e "try{const cfg=JSON.parse(require('fs').readFileSync('%OPENCLAW_HOME%\.openclaw\openclaw.json','utf8'));console.log(cfg?.agents?.defaults?.model?.primary?'yes':'no')}catch(e){console.log('no')}" 2^>^&1') do set HAS_PRIMARY=%%i
    )
    
    rem Inject bundled model configuration
    "%NODE_EXE%" -e "const fs=require('fs');const cfg=fs.existsSync('%OPENCLAW_HOME%\.openclaw\openclaw.json')?JSON.parse(fs.readFileSync('%OPENCLAW_HOME%\.openclaw\openclaw.json','utf8')):{};cfg.models=cfg.models||{};cfg.models.providers=cfg.models.providers||{};cfg.models.providers['bundled-local']={baseUrl:'http://127.0.0.1:18080/v1',apiKey:'bundled-no-key',api:'openai-completions',models:[{id:'qwen2.5-1.5b',name:'Qwen2.5 1.5B (Bundled CPU)',contextWindow:32768,maxTokens:4096,cost:{input:0,output:0}}]};cfg.agents=cfg.agents||{};cfg.agents.defaults=cfg.agents.defaults||{};cfg.agents.defaults.model=cfg.agents.defaults.model||{};if('%HAS_PRIMARY%'==='no'){cfg.agents.defaults.model.primary='bundled-local/qwen2.5-1.5b';console.log('default')}else{console.log('fallback')};fs.writeFileSync('%OPENCLAW_HOME%\.openclaw\openclaw.json',JSON.stringify(cfg,null,2))" 2>nul
    
    if "!HAS_PRIMARY!"=="no" (
        echo [OK]  bundled-local/qwen2.5-1.5b set as default model
    ) else (
        echo [INFO] Primary model already configured, bundled model as fallback
    )
)

rem ============================================
rem [6/6] Start OpenClaw Gateway
rem ============================================
echo.
echo [6/6] Starting OpenClaw Gateway...
echo.

rem Start OpenClaw Gateway (background)
start /b "" "%NODE_EXE%" "%OPENCLAW_ENTRY%" gateway run --port %GATEWAY_PORT% --allow-unconfigured

rem Wait for startup (max 60 seconds)
echo [INFO] Waiting for Gateway to start...
echo [INFO] This may take up to 60 seconds on first run...
echo.

set "CONFIG_FILE=%OPENCLAW_HOME%\.openclaw\openclaw.json"
set GATEWAY_TOKEN=
set GATEWAY_READY=0
set WAIT_COUNT=0

:wait_loop
timeout /t 1 /nobreak >nul
set /a WAIT_COUNT+=1

rem Check if port is listening
netstat -aon 2>nul | findstr ":%GATEWAY_PORT%" | findstr "LISTENING" >nul
if not errorlevel 1 (
    set GATEWAY_READY=1
)

rem Try to extract token if config file exists
if exist "%CONFIG_FILE%" (
    if not defined GATEWAY_TOKEN (
        for /f "tokens=2 delims=:" %%a in ('findstr /C:"\"token\"" "%CONFIG_FILE%" 2^>nul') do (
            set "TOKEN_LINE=%%a"
            set "TOKEN_LINE=!TOKEN_LINE:"=!"
            set "TOKEN_LINE=!TOKEN_LINE:,=!"
            set "TOKEN_LINE=!TOKEN_LINE: =!"
            set "GATEWAY_TOKEN=!TOKEN_LINE!"
        )
    )
)

rem Ready if port is listening AND (token found OR waited 30+ seconds)
if !GATEWAY_READY! EQU 1 (
    if defined GATEWAY_TOKEN goto :gateway_ready
    if !WAIT_COUNT! GEQ 30 goto :gateway_ready
)

rem Show progress every 5 seconds
set /a MOD=!WAIT_COUNT! %% 5
if !MOD! EQU 0 (
    echo [INFO] Still waiting... (!WAIT_COUNT!/60 seconds^)
)

rem Timeout after 60 seconds
if !WAIT_COUNT! LSS 60 goto :wait_loop

echo.
echo [WARN] Gateway startup timeout (60 seconds^)
echo [INFO] Gateway may still be starting in the background
echo.

:gateway_ready
echo.
if !GATEWAY_READY! EQU 1 (
    echo [OK]  Gateway is running on port %GATEWAY_PORT%
) else (
    echo [INFO] Gateway is still starting...
)
echo.

rem ============================================
rem Display access information
rem ============================================
echo ==========================================
echo   Gateway is ready!
echo ==========================================
echo.
echo   Access URL: http://localhost:%GATEWAY_PORT%
echo.

if defined GATEWAY_TOKEN (
    echo   Token: !GATEWAY_TOKEN!
    echo.
    
    rem Copy token to clipboard using PowerShell (more reliable)
    powershell -NoProfile -Command "Set-Clipboard -Value '!GATEWAY_TOKEN!'" 2>nul
    if not errorlevel 1 (
        echo   [OK] Token copied to clipboard
    ) else (
        echo   [INFO] Copy token manually if needed
    )
    
    echo.
    echo   Direct link with token:
    echo   http://localhost:%GATEWAY_PORT%?token=!GATEWAY_TOKEN!
    echo.
    
    rem Auto-open browser with token
    start http://localhost:%GATEWAY_PORT%?token=!GATEWAY_TOKEN!
) else (
    echo   [INFO] Token not found yet, will retry in 5 seconds...
    echo.
    
    rem Wait a bit more for token
    timeout /t 5 /nobreak >nul
    
    rem Retry token extraction
    if exist "%CONFIG_FILE%" (
        for /f "tokens=2 delims=:" %%a in ('findstr /C:"\"token\"" "%CONFIG_FILE%" 2^>nul') do (
            set "TOKEN_LINE=%%a"
            set "TOKEN_LINE=!TOKEN_LINE:"=!"
            set "TOKEN_LINE=!TOKEN_LINE:,=!"
            set "TOKEN_LINE=!TOKEN_LINE: =!"
            set "GATEWAY_TOKEN=!TOKEN_LINE!"
        )
    )
    
    if defined GATEWAY_TOKEN (
        echo   Token: !GATEWAY_TOKEN!
        echo.
        powershell -NoProfile -Command "Set-Clipboard -Value '!GATEWAY_TOKEN!'" 2>nul
        echo   [OK] Token copied to clipboard
        echo.
        echo   Direct link with token:
        echo   http://localhost:%GATEWAY_PORT%?token=!GATEWAY_TOKEN!
        echo.
        start http://localhost:%GATEWAY_PORT%?token=!GATEWAY_TOKEN!
    ) else (
        echo   [WARN] Token still not found
        echo   Config path: %CONFIG_FILE%
        echo.
        echo   Opening browser without token...
        start http://localhost:%GATEWAY_PORT%
    )
)

echo.

rem Display model status
if !LLM_BUNDLED_READY! EQU 1 (
    echo   Model: qwen2.5-1.5b (port %LLM_PORT%)
) else (
    echo   Model: Using cloud API
)

echo.
echo ==========================================
echo   To stop: Close this window or press Ctrl+C
echo ==========================================
echo.

rem Keep the window open
:keep_running
timeout /t 60 /nobreak >nul
goto :keep_running
