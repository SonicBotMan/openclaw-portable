@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title OpenClaw Portable v7 - Environment Check

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "NODE=%SCRIPT_DIR%\node\node.exe"
set "OPENCLAW_MJS=%SCRIPT_DIR%\openclaw-pkg\node_modules\openclaw\openclaw.mjs"
set "OLLAMA_EXE=%SCRIPT_DIR%\ollama\ollama.exe"
set "MODEL_ID=qwen3:1.7b"
set "MODEL_FILE=qwen3-1.7b"

set PASS=0
set FAIL=0

echo.
echo ==========================================
echo   OpenClaw Portable v7 - Environment Check
echo ==========================================
echo.

echo [Check 1/5] Node.js...
if exist "%NODE%" (
    for /f "tokens=*" %%v in ('"%NODE%" --version 2^>nul') do echo   [OK]   Node %%v
    "%NODE%" -e "const [a,b]=process.versions.node.split('.').map(Number); process.exit(a>22||(a===22&&b>=22)||(a>=24)?0:1)" >nul 2>&1
    if errorlevel 1 (
        echo   [FAIL] OpenClaw requires Node ^>=22.22.3 - this package is stale
        set /a FAIL+=1
    ) else (
        echo   [OK]   meets OpenClaw engine requirement
        set /a PASS+=1
    )
) else (
    echo   [FAIL] node\node.exe not found - download the CORE package
    set /a FAIL+=1
)

echo [Check 2/5] OpenClaw...
if exist "%OPENCLAW_MJS%" (
    "%NODE%" "%OPENCLAW_MJS%" --version >nul 2>&1
    if errorlevel 1 (
        echo   [FAIL] openclaw --version failed (re-download the core package)
        set /a FAIL+=1
    ) else (
        for /f "tokens=*" %%v in ('"%NODE%" "%OPENCLAW_MJS%" --version 2^>nul') do echo   [OK]   OpenClaw %%v (install verified)
        set /a PASS+=1
    )
) else (
    echo   [FAIL] openclaw entry not found
    set /a FAIL+=1
)

echo [Check 3/5] Ollama...
if exist "%OLLAMA_EXE%" (
    echo   [OK]   ollama bundled
    set /a PASS+=1
) else (
    echo   [INFO] no bundled Ollama - CLOUD mode (set an API key with apply-config.bat)
)

echo [Check 4/5] Bundled model...
if exist "%SCRIPT_DIR%\models\%MODEL_FILE%.Q4_K_M.gguf" (
    echo   [OK]   models\%MODEL_FILE%.Q4_K_M.gguf present
    set /a PASS+=1
) else if exist "%SCRIPT_DIR%\models\%MODEL_FILE%.Q4_K_M.gguf.part1" (
    echo   [OK]   split parts present (assembled on first start)
    set /a PASS+=1
) else (
    echo   [INFO] no local model files - CLOUD mode
)

echo [Check 5/5] Ports...
for %%p in (18789 11434) do (
    netstat -aon 2>nul | findstr /r "LISTENING" | findstr /r /c:":%%p " >nul
    if not errorlevel 1 (
        echo   [INFO] port %%p in use (start will fall back)
    ) else (
        echo   [OK]   port %%p free
        set /a PASS+=1
    )
)

echo.
echo -------------------------------------------
echo   Result: !PASS! OK, !FAIL! FAIL
echo -------------------------------------------
pause
exit /b %FAIL%
