@echo off
rem OpenClaw Portable - 敏感文件清理工具
rem Issue #43 修复：零痕迹设计

setlocal enabledelayedexpansion
title OpenClaw Portable - 清理工具

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
set "DATA_DIR=%SCRIPT_DIR%\data\.openclaw"

echo.
echo ==========================================
echo   OpenClaw Portable - 清理工具
echo ==========================================
echo.

rem ============================================
rem 1. 检测敏感文件
rem ============================================
echo [检测] 扫描敏感文件...
echo.

set FILE_COUNT=0

rem 检测配置文件
if exist "%DATA_DIR%\openclaw.json" (
    set /a FILE_COUNT+=1
    echo   [!] openclaw.json (包含 API Key^)
)

rem 检测备份目录
if exist "%DATA_DIR%\backups\" (
    set /a FILE_COUNT+=1
    echo   [!] backups\ (配置备份^)
)

rem 检测 token 文件
if exist "%DATA_DIR%\.gateway_token" (
    set /a FILE_COUNT+=1
    echo   [!] .gateway_token (访问令牌^)
)

rem 检测日志文件
if exist "%SCRIPT_DIR%\llm\server.log" (
    set /a FILE_COUNT+=1
    echo   [!] llm\server.log (运行日志^)
)

rem 检测 PID 文件
if exist "%SCRIPT_DIR%\llm\server.pid" (
    set /a FILE_COUNT+=1
    echo   [!] llm\server.pid (进程 ID^)
)

if !FILE_COUNT!==0 (
    echo.
    echo [OK] 未发现敏感文件
    echo.
    pause
    exit /b 0
)

echo.
echo [选项] 请选择清理级别：
echo.
echo   [1] 轻度清理 - 仅清理日志和 PID 文件
echo   [2] 深度清理 - 清理所有敏感文件（需重新配置）
echo   [3] 取消
echo.

set /p "请选择 (1-3): " CHOICE

if "!CHOICE!"=="1" goto LIGHT_CLEANUP
if "!CHOICE!"=="2" goto DEEP_CLEANUP
if "!CHOICE!"=="3" goto CANCEL
echo.
echo [错误] 无效选择
goto CANCEL

:LIGHT_CLEANUP
echo.
echo [清理] 轻度清理...

if exist "%SCRIPT_DIR%\llm\server.log" (
    del /f /q "%SCRIPT_DIR%\llm\server.log" 2>nul
    echo   [OK] 已删除 llm\server.log
)

if exist "%SCRIPT_DIR%\llm\server.pid" (
    del /f /q "%SCRIPT_DIR%\llm\server.pid" 2>nul
    echo   [OK] 已删除 llm\server.pid
)

echo.
echo [完成] 轻度清理完成
echo   配置文件已保留，可安全拔出 U盘
goto END

:DEEP_CLEANUP
echo.
echo [警告] 深度清理将删除所有敏感文件！
echo   包括：API Key、配置备份、访问令牌等
echo.
set /p "确认深度清理？(yes/N): " CONFIRM

if not "!CONFIRM!"=="yes" goto CANCEL

echo.
echo [清理] 深度清理...

if exist "%DATA_DIR%\openclaw.json" (
    del /f /q "%DATA_DIR%\openclaw.json" 2>nul
    echo   [OK] 已删除 openclaw.json
)

if exist "%DATA_DIR%\backups\" (
    rd /s /q "%DATA_DIR%\backups\" 2>nul
    echo   [OK] 已删除 backups\
)

if exist "%DATA_DIR%\.gateway_token" (
    del /f /q "%DATA_DIR%\.gateway_token" 2>nul
    echo   [OK] 已删除 .gateway_token
)

if exist "%SCRIPT_DIR%\llm\server.log" (
    del /f /q "%SCRIPT_DIR%\llm\server.log" 2>nul
    echo   [OK] 已删除 llm\server.log
)

if exist "%SCRIPT_DIR%\llm\server.pid" (
    del /f /q "%SCRIPT_DIR%\llm\server.pid" 2>nul
    echo   [OK] 已删除 llm\server.pid
)

echo.
echo [完成] 深度清理完成
echo   下次启动需要重新配置 API Key
goto END

:CANCEL
echo 已取消
goto END

:END
echo.
echo [完成] 清理完成，可安全拔出 U盘
echo.
pause
