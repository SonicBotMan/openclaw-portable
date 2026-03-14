# Changelog

All notable changes to this project will be documented in this file.

## [1.0.2] - 2026-03-14

### Added
- 🛡️ **Windows 环境诊断工具**
  - diagnose.bat - 自动检测环境限制
  - check-firewall.bat - 防火墙规则检查
  - 6 项自动检查（权限/防火墙/端口/U盘/杀毒）

- 📚 **Windows 环境文档**
  - docs/WINDOWS-FAQ.md - 12 个常见问题解答
  - 防火墙/杀毒软件/端口占用/U盘/权限/网络问题

### Improved
- 📝 更新 README.md 添加 Windows 环境限制说明
- 🔧 提供详细的解决方案和手动修复方法

### Fixed
- 🔥 解决 Windows 防火墙首次启动拦截问题
- 🔥 解决 SmartScreen 拦截问题
- 🔥 解决端口占用问题

## [1.0.1] - 2026-03-14

### Added
- ✨ Node.js 预置脚本
  - Windows: `scripts/setup-node.bat`
  - Linux/Mac: `scripts/setup-node.sh`
  - 支持预置多个平台版本
- 📚 详细文档
  - 安装指南 (`docs/SETUP.md`)
  - 开发指南 (`docs/DEVELOPMENT.md`)
  - 常见问题 (`docs/FAQ.md`)
- 📋 改进计划 (`.github/IMPROVEMENTS.md`)
- 📦 配置示例 (`data/config/openclaw.json.example`)

## [1.0.0] - 2026-03-14

### Added
- ✨ 初始化项目结构
  - Windows 启动脚本 (`start.bat`)
  - Linux/Mac 启动脚本 (`start.sh`)
  - 停止脚本 (`stop.bat`)
  - Node.js 下载脚本 (`scripts/download-node.sh`)

### Features
- 🔌 即插即用 - 插上 U 盘即可使用
- 🌍 跨平台支持 - Windows / Linux / macOS
- 📦 数据持久化 - 所有数据保存在 U 盘
- 🔧 路径自适应 - 自动检测 U 盘路径

---

Made with 💕 by 小茹
