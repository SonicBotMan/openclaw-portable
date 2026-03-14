# 常见问题

## Q: U 盘速度太慢怎么办？

A: 建议使用 SSD U 盘或高速 USB 3.0+ 接口。普通 USB 2.0 U 盘启动时间可能较长。

## Q: 换电脑后盘符变了怎么办？

A: 启动脚本会自动检测当前路径，无需手动配置。

## Q: 如何备份我的数据？

A: 直接复制 `data/` 目录到其他位置即可。建议定期备份到云盘。

## Q: 可以同时在多台电脑上使用吗？

A: 不可以。OpenClaw 会锁定数据文件，同时使用可能导致数据损坏。请在一个设备上使用后再切换。

## Q: 如何更新 OpenClaw？

A: 
```bash
./node-portable/*/bin/npm update -g openclaw
```

## Q: Node.js 便携版太大怎么办？

A: 可以只保留你使用的平台版本，删除其他平台的 Node.js：
- Windows: 删除 `node-portable/linux/` 和 `node-portable/darwin/`
- Linux: 删除 `node-portable/windows/` 和 `node-portable/darwin/`
- macOS: 删除 `node-portable/windows/` 和 `node-portable/linux/`

## Q: 浏览器窗口没有自动打开？

A: 检查浏览器是否已安装。启动脚本支持：
- Windows: Chrome, Edge, Firefox
- Linux: Chrome, Firefox, Chromium
- macOS: Chrome, Safari, Firefox
