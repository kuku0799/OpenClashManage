# OpenClash管理面板 - 一键安装指南

## 🚀 快速开始

### 一键安装

```bash
# 1. 下载项目文件到OpenWrt路由器
# 2. 进入项目目录
cd /path/to/OpenClashManage

# 3. 设置执行权限
chmod +x install_openwrt.sh

# 4. 运行一键安装
./install_openwrt.sh install
```

### 一键卸载

```bash
# 卸载应用
./install_openwrt.sh uninstall
```

## 📋 系统要求

- **系统**: OpenWrt 21.02+ / 22.03+ / 23.05+ / 24.10+
- **架构**: aarch64, x86_64, arm_cortex-a7, mipsel_24kc
- **内存**: 至少 64MB 可用内存
- **存储**: 至少 10MB 可用空间
- **网络**: 需要网络连接下载依赖包

## 🔧 安装过程

安装脚本会自动执行以下步骤：

1. ✅ **环境检查** - 检查root权限、系统架构、OpenWrt版本
2. ✅ **更新软件包** - 更新opkg软件包列表
3. ✅ **安装Python3** - 安装Python3运行环境
4. ✅ **安装pip** - 安装Python包管理器
5. ✅ **安装依赖** - 安装Flask、requests、PyYAML等依赖
6. ✅ **创建目录** - 创建应用目录结构
7. ✅ **复制文件** - 复制应用文件到安装目录
8. ✅ **设置权限** - 设置正确的文件权限
9. ✅ **创建管理脚本** - 创建应用管理脚本
10. ✅ **创建系统服务** - 创建OpenWrt系统服务
11. ✅ **启用自启动** - 设置开机自动启动
12. ✅ **启动应用** - 启动Web管理面板
13. ✅ **测试应用** - 测试应用是否正常运行

## 🌐 访问管理面板

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

## 📁 文件结构

```
/root/OpenClashManage/
├── app.py              # 主应用文件
├── log.py              # 日志模块
├── manage.sh           # 管理脚本
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
   netstat -tlnp | grep :8888
   
   # 检查防火墙
   iptables -L | grep 8888
   
   # 重启应用
   /root/OpenClashManage/manage.sh restart
   ```

4. **节点解析问题**
   ```bash
   # 检查节点文件
   cat /root/OpenClashManage/wangluo/nodes.txt
   
   # 查看应用日志
   /root/OpenClashManage/manage.sh logs
   ```

### 日志查看

```bash
# 查看安装日志
cat /root/OpenClashManage/install.log

# 查看应用日志
tail -f /root/OpenClashManage/wangluo/log.txt

# 查看系统日志
logread | grep openclash
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

---

**注意**: 此脚本仅适用于OpenWrt系统，请确保在正确的环境中运行。 