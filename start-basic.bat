@echo off
chcp 65001 >nul
title OpenClaw Portable - 一键启动

echo.
echo ========================================
echo    OpenClaw Portable - 一键启动
echo ========================================
echo.

:: 获取当前目录（U盘路径）
set "USB_ROOT=%~dp0"
set "USB_ROOT=%USB_ROOT:~0,-1%"

:: 检查 WSL
wsl --status >nul 2>&1
if errorlevel 1 (
    echo [错误] WSL2 未安装！
    echo.
    echo 正在为您安装 WSL2...
    echo 请在弹出窗口中确认，然后重启电脑。
    echo.
    wsl --install -d Ubuntu
    if errorlevel 1 (
        echo.
        echo [提示] 请手动运行以下命令（以管理员身份）：
        echo wsl --install -d Ubuntu
        echo 然后重启电脑，再运行此脚本。
    )
    pause
    exit /b 1
)

:: 检测 U盘在 WSL 中的路径
for %%i in (c d e f g h i j k l m n o p q r s t u v w x y z) do (
    if exist "%%i:\" (
        wsl test -d /mnt/%%i/openclaw-portable 2>nul
        if not errorlevel 1 (
            set "WSL_USB=/mnt/%%i/openclaw-portable"
            goto :found
        )
    )
)

:: 备用：使用当前脚本所在盘符
set "DRIVE_LETTER=%USB_ROOT:~0,1%"
set "WSL_USB=/mnt/%DRIVE_LETTER%/openclaw-portable"

:found
echo [信息] U盘路径: %USB_ROOT%
echo [信息] WSL路径: %WSL_USB%
echo.

:: 执行 WSL 启动脚本
echo [启动] 正在启动 OpenClaw...
echo.
wsl -e bash -c "cd '%WSL_USB%' && chmod +x *.sh && ./start.sh '%WSL_USB%'"

echo.
echo ========================================
echo   OpenClaw 已启动！
echo   访问地址: http://localhost:18789
echo ========================================
echo.
echo 使用完毕后，运行 stop.bat 一键关闭
echo.
pause
