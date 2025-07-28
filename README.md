# OpenClash管理面板

一个基于Flask的OpenClash Web管理面板，支持节点管理、配置同步、速度测试等功能。

## 🚀 快速开始

### 方法一：一键修复（推荐）

如果你的OpenClash管理面板遇到节点同步问题，可以使用一键修复：

```bash
# 快速修复命令
wget -O 快速修复.sh https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/快速修复.sh
chmod +x 快速修复.sh
bash 快速修复.sh
```

### 方法二：一键部署（全新安装）

```bash
# 下载并运行一键部署脚本
wget -O - https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/一键部署.sh | sh
```

### 方法二：手动安装

```bash
# 1. 下载安装脚本
wget https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/install_openwrt.sh

# 2. 设置执行权限
chmod +x install_openwrt.sh

# 3. 运行安装
./install_openwrt.sh install
```

### 方法三：直接下载安装

```bash
# 一键下载并安装
curl -sSL https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/install_openwrt.sh | bash
```

## 📋 系统要求

- **系统**: OpenWrt 21.02+ / 22.03+ / 23.05+ / 24.10+
- **架构**: aarch64, x86_64, arm_cortex-a7, mipsel_24kc
- **内存**: 至少 64MB 可用内存
- **存储**: 至少 10MB 可用空间
- **网络**: 需要网络连接下载依赖包

## 🌐 访问地址

安装完成后，您可以通过以下地址访问：

- **本地访问**: `http://localhost:8888`
- **局域网访问**: `http://192.168.5.1:8888`
- **路由器IP访问**: `http://[路由器IP]:8888`

## 🔧 管理命令

### 系统服务管理

```bash
# 启动服务
/etc/init.d/openclash-manage start

# 停止服务
/etc/init.d/openclash-manage stop

# 重启服务
/etc/init.d/openclash-manage restart

# 查看状态
/etc/init.d/openclash-manage status
```

### 应用管理脚本

```bash
# 查看应用状态
/root/OpenClashManage/manage.sh status

# 查看应用日志
/root/OpenClashManage/manage.sh logs

# 重启应用
/root/OpenClashManage/manage.sh restart
```

## ✨ 主要功能

- 🔄 **节点管理** - 添加、删除、编辑节点
- 📥 **批量导入** - 支持多种格式的节点链接导入
- ⚡ **速度测试** - 测试节点连接速度
- 🔄 **配置同步** - 自动同步到OpenClash配置
- 📊 **实时监控** - 监控OpenClash运行状态
- 📝 **日志查看** - 查看应用和OpenClash日志
- 🎛️ **服务控制** - 启动、停止、重启OpenClash服务

## 📁 文件结构

```
/root/OpenClashManage/
├── app.py              # 主应用文件
├── log.py              # 日志模块
├── manage.sh           # 管理脚本
├── install_openwrt.sh  # 安装脚本
├── wangluo/
│   ├── nodes.txt       # 节点文件
│   └── log.txt         # 应用日志
└── templates/
    └── index.html      # Web界面模板
```

## 🛠️ 故障排除

### 常见问题

1. **安装失败**
   ```bash
   # 检查网络连接
   ping 8.8.8.8
   
   # 更新软件包列表
   opkg update
   
   # 重新安装
   ./install_openwrt.sh install
   ```

2. **应用无法启动**
   ```bash
   # 检查Python3
   python3 --version
   
   # 检查依赖
   python3 -c "import flask; print('Flask OK')"
   python3 -c "import requests; print('Requests OK')"
   python3 -c "import yaml; print('PyYAML OK')"
   
   # 查看日志
   tail -f /root/OpenClashManage/wangluo/log.txt
   ```

3. **无法访问Web界面**
   ```bash
   # 检查端口
ss -tlnp | grep :8888 || netstat -tlnp | grep :8888
   
   # 检查防火墙
   iptables -L | grep 8888
   
   # 重启应用
   /root/OpenClashManage/manage.sh restart
   ```

## 🔄 更新应用

```bash
# 1. 停止应用
/etc/init.d/openclash-manage stop

# 2. 备份配置
cp /root/OpenClashManage/wangluo/nodes.txt /tmp/nodes_backup.txt

# 3. 重新安装
./install_openwrt.sh install

# 4. 恢复配置
cp /tmp/nodes_backup.txt /root/OpenClashManage/wangluo/nodes.txt
```

## 📞 技术支持

如果遇到问题，请提供以下信息：

1. OpenWrt版本和架构
2. 安装日志内容
3. 应用日志内容
4. 具体的错误信息

## 📄 许可证

本项目采用 MIT 许可证。

## 🤝 贡献

欢迎提交Issue和Pull Request！

---

**注意**: 此项目仅适用于OpenWrt系统，请确保在正确的环境中运行。 