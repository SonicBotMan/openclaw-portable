# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-03-14

### Added
- ✨ 初始化项目结构
  - Windows 启动脚本 (`start.bat`)
  - Linux/Mac 启动脚本 (`start.sh`)
  - 停止脚本 (`stop.bat`)
  - Node.js 下载脚本 (`scripts/download-node.sh`)
- 📚 添加详细文档
  - 安装指南 (`docs/SETUP.md`)
  - 开发指南 (`docs/DEVELOPMENT.md`)
  - 常见问题 (`docs/FAQ.md`)
- 📋 添加改进计划 (`.github/IMPROVEMENTS.md`)
- 📦 添加配置示例 (`data/config/openclaw.json.example`)

### Features
- 🔌 即插即用 - 插上 U 盘即可使用
- 🌍 跨平台支持 - Windows / Linux / macOS
- 📦 数据持久化 - 所有数据保存在 U 盘
- 🔧 路径自适应 - 自动检测 U 盘路径

### Technical Details
- 自动检测 Node.js 便携版
- 自动下载缺失的依赖
- 日志记录功能
- 错误处理和友好提示

---

Made with 💕 by 小茹
