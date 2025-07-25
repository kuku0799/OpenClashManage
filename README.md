# OpenClash 节点管理面板

一个基于Web的OpenClash节点管理工具，提供可视化的节点管理和自动化同步功能。

## 🚀 功能特性

### 核心功能
- **节点管理**: 支持多种协议（ss:// vmess:// vless:// trojan://）
- **自动同步**: 守护进程监控节点文件变化，自动同步到OpenClash
- **状态监控**: 实时监控守护进程和OpenClash运行状态
- **日志管理**: 查看和管理运行日志
- **系统信息**: 显示系统资源使用情况

### 界面特性
- **现代化UI**: 基于Bootstrap 5的响应式设计
- **实时更新**: 自动刷新状态和日志信息
- **操作反馈**: Toast通知系统
- **移动友好**: 支持移动设备访问

## 📁 项目结构

```
OpenClashManage/
├── app.py                 # Flask应用主文件
├── requirements.txt       # Python依赖
├── README.md             # 项目说明
├── templates/
│   └── index.html        # 主页模板
├── jk.sh                 # 守护进程脚本
├── jx.py                 # 节点解析器
├── log.py                # 日志模块
├── zc.py                 # 策略组注入器
├── zr.py                 # 主同步脚本
├── zw.py                 # 代理节点注入器
└── wangluo/
    ├── nodes.txt         # 节点文件
    └── log.txt           # 日志文件
```

## 🛠️ 安装和运行

### 🚀 一键安装（推荐）

#### 通用一键安装命令
```bash
curl -sSL https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/install.sh | bash
```

#### 如果curl有问题，使用wget
```bash
wget -qO- https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/install.sh | bash
```

### OpenWrt 系统专用安装

#### 方法一：标准安装
```bash
curl -sSL https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/install_openwrt_robust.sh | bash
```

#### 方法二：wget安装（curl有问题时使用）
```bash
wget -qO- https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/install_openwrt_wget.sh | bash
```

#### 方法三：修复curl依赖后安装
如果遇到curl库依赖问题，先运行修复脚本：
```bash
wget -qO- https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/fix_curl_deps.sh | bash
```
然后重新运行标准安装。

### 通用安装（其他系统）

#### 1. 安装依赖
```bash
pip3 install -r requirements.txt
```

#### 2. 启动Web面板
```bash
python3 app.py
```

#### 3. 访问面板
打开浏览器访问: `http://your-ip:8080`

## 📋 使用说明

### 节点管理
1. 在"节点管理"区域粘贴节点链接（一行一个）
2. 支持协议：ss:// vmess:// vless:// trojan://
3. 点击"保存节点"按钮保存

### 守护进程
- **启动**: 点击"启动守护进程"开始自动监控
- **停止**: 点击"停止守护进程"停止自动监控
- **状态**: 实时显示守护进程运行状态

### 手动操作
- **手动同步**: 立即执行节点同步操作
- **重启OpenClash**: 重启OpenClash服务
- **清空日志**: 清空运行日志
- **刷新日志**: 手动刷新日志显示

### 系统监控
- **内存使用**: 显示系统内存使用情况
- **磁盘使用**: 显示磁盘空间使用情况
- **CPU负载**: 显示系统CPU负载

## 🔧 配置说明

### 路径配置
在 `app.py` 中可以修改以下路径：
```python
ROOT_DIR = "/root/OpenClashManage"        # 项目根目录
NODES_FILE = f"{ROOT_DIR}/wangluo/nodes.txt"  # 节点文件路径
LOG_FILE = f"{ROOT_DIR}/wangluo/log.txt"      # 日志文件路径
CONFIG_FILE = "/etc/openclash/config.yaml"    # OpenClash配置文件
PID_FILE = "/tmp/openclash_watchdog.pid"      # 守护进程PID文件
```

### 端口配置
默认端口为8080，可在 `app.py` 底部修改：
```python
app.run(host='0.0.0.0', port=8080, debug=False)
```

## 🔄 工作流程

1. **监控**: 守护进程监控 `nodes.txt` 文件变化
2. **解析**: `jx.py` 解析各种协议的节点链接
3. **注入**: `zw.py` 将节点注入配置，`zc.py` 更新策略组
4. **验证**: 验证配置有效性并备份
5. **重启**: 重启OpenClash服务应用新配置

## 🛡️ 安全特性

- **进程保护**: 防止重复启动守护进程
- **配置备份**: 自动备份和回滚机制
- **错误处理**: 完善的错误处理和日志记录
- **权限检查**: 文件读写权限验证

## 📊 状态指示

- 🟢 **绿色脉冲**: 服务运行中
- 🔴 **红色圆点**: 服务已停止
- ⚠️ **黄色警告**: 操作需要确认
- ✅ **成功操作**: 操作执行成功
- ❌ **失败操作**: 操作执行失败

## 🔍 故障排除

### OpenWrt 安装问题

#### 1. 存储空间不足
**错误信息**: `Only have 0kb available on filesystem /overlay`
**解决方案**:
```bash
# 清理opkg缓存
opkg clean

# 删除不需要的软件包
opkg list-installed | grep -v "openclash\|python3\|wget" | xargs opkg remove

# 重启系统释放临时文件
reboot
```

#### 2. curl库依赖问题
**错误信息**: `Error loading shared library libmbedtls.so.21`
**解决方案**:
```bash
# 运行修复脚本
wget -qO- https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/fix_curl_deps.sh | bash

# 或使用wget安装
wget -qO- https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/install_openwrt_wget.sh | bash
```

#### 3. Python包安装失败
**解决方案**:
```bash
# 使用opkg安装Python包
opkg install python3-light python3-yaml python3-flask

# 或降级到稳定版本
opkg install --force-downgrade python3=3.10.13-2
```

### 通用问题

1. **守护进程无法启动**
   - 检查 `jk.sh` 文件权限
   - 确认Python3已安装
   - 查看日志文件错误信息

2. **节点同步失败**
   - 检查节点链接格式
   - 确认OpenClash配置文件路径
   - 验证节点解析器工作正常

3. **Web面板无法访问**
   - 检查防火墙设置
   - 确认端口8080未被占用
   - 验证Flask应用正常启动

### 日志查看
```bash
# 查看运行日志
tail -f /root/OpenClashManage/wangluo/log.txt

# 查看系统日志
logread | grep openclash
```

## 📝 更新日志

### v1.0.0
- 初始版本发布
- 支持多种代理协议
- 实现自动化节点同步
- 提供Web管理界面

## 🤝 贡献

欢迎提交Issue和Pull Request来改进这个项目。

## 📄 许可证

本项目采用MIT许可证。 