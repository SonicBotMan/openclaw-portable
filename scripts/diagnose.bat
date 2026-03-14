@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

title OpenClaw Portable - Windows 环境诊断与修复

:: ========================================
:: 自动检测并修复 Windows 环境限制
:: ========================================

set "USB_ROOT=%~dp0"
set "USB_ROOT=%USB_ROOT:~0,-1%"

echo.
echo ========================================
echo   OpenClaw Portable 环境诊断
echo ========================================
echo.

:: ========================================
:: 检查 1: 管理员权限
:: ========================================
echo [1/6] 检查管理员权限...

net session >nul 2>&1
if errorlevel 1 (
    echo      ⚠️  非管理员模式
    echo.
    echo      部分修复功能需要管理员权限
    echo.
    set ADMIN_MODE=0
) else (
    echo      ✅ 管理员模式
    set ADMIN_MODE=1
)

:: ========================================
:: 检查 2: Windows Defender 防火墙
:: ========================================
echo.
echo [2/6] 检查 Windows Defender 防火墙...

:: 检查防火墙是否启用
netsh advfirewall show allprofiles state | findstr "ON" >nul 2>&1
if errorlevel 1 (
    echo      ✅ 防火墙已关闭
) else (
    echo      ⚠️  防火墙已启用
    
    :: 检查是否已有规则
    netsh advfirewall firewall show rule name="OpenClaw Portable" >nul 2>&1
    if errorlevel 1 (
        echo      ❌ 未添加防火墙规则
        
        if "%ADMIN_MODE%"=="1" (
            echo.
            echo      正在添加防火墙规则...
            netsh advfirewall firewall add rule name="OpenClaw Portable" ^
                dir=in action=allow program="%USB_ROOT%\node-portable\windows\node.exe" ^
                enable=yes protocol=tcp localport=3000 >nul 2>&1
            
            if errorlevel 1 (
                echo      ❌ 添加失败
            ) else (
                echo      ✅ 防火墙规则已添加
            )
        ) else (
            echo.
            echo      💡 请以管理员身份运行此脚本来自动添加
        )
    ) else (
        echo      ✅ 防火墙规则已存在
    )
)

:: ========================================
:: 检查 3: SmartScreen 状态
:: ========================================
echo.
echo [3/6] 检查 SmartScreen 状态...

reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableSmartScreen" >nul 2>&1
if errorlevel 1 (
    echo      ℹ️  无法读取 SmartScreen 状态
) else (
    for /f "tokens=3" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableSmartScreen" 2^>nul') do (
        if "%%a"=="0x1" (
            echo      ⚠️  SmartScreen 已启用
            echo      💡 首次运行可能需要点击"更多信息"
        ) else (
            echo      ✅ SmartScreen 已关闭
        )
    )
)

:: ========================================
:: 检查 4: 端口占用
:: ========================================
echo.
echo [4/6] 检查端口 3000 占用情况...

netstat -ano | findstr ":3000" | findstr "LISTENING" >nul 2>&1
if errorlevel 1 (
    echo      ✅ 端口 3000 空闲
) else (
    echo      ❌ 端口 3000 已被占用
    echo.
    echo      占用进程：
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":3000" ^| findstr "LISTENING"') do (
        for /f "tokens=1" %%b in ('tasklist /FI "PID eq %%a" /NH 2^>nul') do (
            echo        - %%b (PID: %%a)
        )
    )
    echo.
    echo      💡 解决方法：
    echo         1. 修改 data/config/openclaw.json 中的端口
    echo         2. 或关闭占用端口的程序
)

:: ========================================
:: 检查 5: U 盘写入权限
:: ========================================
echo.
echo [5/6] 检查 U 盘写入权限...

echo test > "%USB_ROOT%\.write_test" 2>nul
if errorlevel 1 (
    echo      ❌ U 盘只读或无写入权限
    echo      💡 请检查：
    echo         - U 盘是否被写保护
    echo         - 是否有足够的磁盘空间
) else (
    del "%USB_ROOT%\.write_test" >nul 2>&1
    echo      ✅ U 盘可写入
)

:: ========================================
:: 检查 6: 杀毒软件检测
:: ========================================
echo.
echo [6/6] 检查常见杀毒软件...

set AV_FOUND=0

:: Windows Defender
tasklist /FI "IMAGENAME eq MsMpEng.exe" 2>nul | findstr "MsMpEng.exe" >nul 2>&1
if not errorlevel 1 (
    echo      ℹ️  Windows Defender 运行中
    set AV_FOUND=1
)

:: 360
tasklist /FI "IMAGENAME eq 360sd.exe" 2>nul | findstr "360" >nul 2>&1
if not errorlevel 1 (
    echo      ⚠️  360 安全卫士运行中
    set AV_FOUND=1
)

:: 火绒
tasklist /FI "IMAGENAME eq Huorong.exe" 2>nul | findstr "Huorong" >nul 2>&1
if not errorlevel 1 (
    echo      ℹ️  火绒安全运行中
    set AV_FOUND=1
)

if "%AV_FOUND%"=="0" (
    echo      ℹ️  未检测到常见杀毒软件
)

echo.
echo      💡 如果杀毒软件拦截：
echo         1. 添加 U 盘目录到排除列表
echo         2. 或临时关闭实时保护

:: ========================================
:: 总结
:: ========================================
echo.
echo ========================================
echo   诊断完成
echo ========================================
echo.

echo 📋 检查结果：
echo.
echo   ✅ 环境基本可用
echo.
echo 如遇到问题：
echo   1. 以管理员身份运行此脚本
echo   2. 检查杀毒软件是否拦截
echo   3. 确认端口 3000 未被占用
echo.

pause
