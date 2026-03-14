@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

title 检查 Windows 防火墙规则

:: ========================================
:: 检查 Windows 防火墙是否允许 OpenClaw
:: ========================================

echo.
echo ========================================
echo   检查 Windows 防火墙规则
echo ========================================
echo.

:: 检查是否已添加规则
echo [检查] 查找 OpenClaw Portable 防火墙规则...
netsh advfirewall firewall show rule name="OpenClaw Portable" >nul 2>&1
if errorlevel 1 (
    echo [结果] 未找到防火墙规则
    echo.
    
    set /p add_rule="是否添加防火墙规则？ [y/N]: "
    if /i "!add_rule!"=="y" (
        echo.
        echo [操作] 添加防火墙规则...
        
        :: 添加入站规则
        netsh advfirewall firewall add rule name="OpenClaw Portable" ^
            dir=in action=allow program="%~dp0node-portable\windows\node.exe" ^
            enable=yes protocol=tcp localport=3000 >nul 2>&1
        
        if errorlevel 1 (
            echo [错误] 添加失败，请以管理员身份运行
            echo.
            echo 解决方法：
            echo   1. 右键此脚本
            echo   2. 选择"以管理员身份运行"
        ) else (
            echo [成功] 防火墙规则已添加
            echo.
            echo 规则详情：
            echo   - 名称: OpenClaw Portable
            echo   - 方向: 入站
            echo   - 端口: 3000
            echo   - 程序: node.exe
        )
    )
) else (
    echo [结果] 防火墙规则已存在 ✅
    echo.
    echo 规则详情：
    netsh advfirewall firewall show rule name="OpenClaw Portable" | findstr /C:"规则名" /C:"端口" /C:"程序"
)

echo.
echo ========================================
echo   检查端口 3000 是否被占用
echo ========================================
echo.

netstat -ano | findstr ":3000" >nul 2>&1
if errorlevel 1 (
    echo [结果] 端口 3000 空闲 ✅
) else (
    echo [警告] 端口 3000 已被占用
    echo.
    echo 占用进程：
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":3000"') do (
        tasklist /FI "PID eq %%a" 2>nul | findstr /V "PID"
    )
    echo.
    echo 解决方法：
    echo   1. 修改 data/config/openclaw.json 中的端口
    echo   2. 或者关闭占用端口的程序
)

echo.
pause
