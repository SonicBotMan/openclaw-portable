# Windows 环境常见问题

## 🔥 防火墙相关

### Q1: 首次启动时弹出"Windows 防火墙已阻止此应用的部分功能"

**原因：** Windows Defender 防火墙默认阻止程序监听网络端口

**解决方案：**
1. ✅ **推荐**：点击"允许访问"
2. 或手动添加规则：
   ```batch
   :: 以管理员身份运行
   netsh advfirewall firewall add rule name="OpenClaw Portable" ^
     dir=in action=allow program="U:\node-portable\windows\node.exe" ^
     enable=yes protocol=tcp localport=3000
   ```

### Q2: 没有弹出防火墙提示，但无法访问

**检查方法：**
```batch
:: 查看防火墙规则
netsh advfirewall firewall show rule name="OpenClaw Portable"

:: 查看端口监听
netstat -ano | findstr ":3000"
```

**解决方案：**
- 运行 `scripts\check-firewall.bat` 自动检查
- 或手动在防火墙设置中添加例外

---

## 🛡️ 杀毒软件相关

### Q3: Windows Defender 提示"检测到潜在威胁"

**原因：** Node.js 便携版未签名，被识别为可疑文件

**解决方案：**
1. 点击"允许" → "在设备上运行"
2. 或添加排除：
   ```
   设置 → 更新与安全 → Windows 安全中心
   → 病毒和威胁防护 → 管理设置
   → 排除项 → 添加排除项
   → 选择文件夹：U:\openclaw-portable\
   ```

### Q4: 360/火绒拦截程序运行

**解决方案：**

**360 安全卫士：**
```
木马查杀 → 信任区 → 添加信任文件
选择：U:\openclaw-portable\ 目录
```

**火绒安全：**
```
信任区 → 添加信任文件
选择：U:\openclaw-portable\ 目录
```

---

## 🚫 端口占用

### Q5: 启动失败，提示端口被占用

**检查端口占用：**
```batch
netstat -ano | findstr ":3000"
```

**输出示例：**
```
TCP    0.0.0.0:3000    0.0.0.0:0    LISTENING    12345
```

**解决方案：**

**方案 1：修改端口**
```json
// data/config/openclaw.json
{
  "port": 8080,  // 改为其他端口
  ...
}
```

**方案 2：关闭占用程序**
```batch
:: 查看占用进程
tasklist /FI "PID eq 12345"

:: 结束进程（谨慎操作）
taskkill /F /PID 12345
```

---

## 💾 U 盘问题

### Q6: 无法写入 U 盘

**检查项：**
1. U 盘是否有物理写保护开关
2. U 盘是否已满
3. 文件系统是否支持（建议 NTFS/exFAT）

**解决方案：**
```batch
:: 检查磁盘空间
wmic logicaldisk get size,freespace,caption

:: 检查文件系统
fsutil fsinfo volumeinfo U:
```

### Q7: U 盘盘符变化导致路径错误

**原因：** 不同电脑可能分配不同盘符

**解决方案：**
- ✅ **自动适应**：启动脚本会自动检测当前盘符
- 无需手动配置路径

---

## 🔐 权限问题

### Q8: 提示"访问被拒绝"

**可能原因：**
1. 需要管理员权限
2. U 盘只读
3. 文件被占用

**解决方案：**
```batch
:: 以管理员身份运行
右键 start.bat → 以管理员身份运行

:: 或使用 diagnose.bat 诊断
scripts\diagnose.bat
```

---

## 🌐 网络问题

### Q9: 浏览器无法打开 http://localhost:3000

**检查项：**
1. OpenClaw 是否正常启动
2. 防火墙是否允许访问
3. 浏览器代理设置

**解决方案：**
```batch
:: 检查 OpenClaw 是否运行
tasklist | findstr "node"

:: 检查端口监听
netstat -ano | findstr ":3000"

:: 尝试其他浏览器
start msedge http://localhost:3000
start chrome http://localhost:3000
```

### Q10: 公司网络环境下无法使用

**可能限制：**
- 组策略禁止 U 盘程序运行
- 端口被封锁
- 网络代理干扰

**解决方案：**
1. 咨询 IT 部门是否允许使用便携式软件
2. 修改端口为常用端口（如 8080）
3. 配置代理设置

---

## 🚀 性能问题

### Q11: 启动速度慢

**原因：**
- U 盘读取速度慢
- 首次运行需要初始化

**优化方案：**
1. 使用 USB 3.0+ 或 SSD U 盘
2. 预置 Node.js 避免首次下载
3. 禁用不必要的杀毒软件实时扫描（临时）

### Q12: 运行卡顿

**检查项：**
```batch
:: 检查内存使用
tasklist /FI "IMAGENAME eq node.exe"

:: 检查 CPU 使用
wmic path Win32_PerfFormattedData_PerfProc_Process get Name,PercentProcessorTime
```

**优化方案：**
- 关闭不必要的后台程序
- 检查是否有杀毒软件扫描 U 盘

---

## 📞 获取帮助

如果以上方案都无法解决问题：

1. 运行诊断脚本：
   ```batch
   scripts\diagnose.bat > diagnostic-report.txt 2>&1
   ```

2. 查看日志：
   ```
   data\logs\startup.log
   ```

3. 提交 Issue：
   https://github.com/SonicBotMan/openclaw-portable/issues

---

Made with 💕 by 小茹
