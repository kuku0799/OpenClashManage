# OpenWrt 安装指南

## 🚀 快速安装

### 方法一：使用安装脚本（推荐）

```bash
# 下载安装脚本
wget https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/install_openwrt.sh

# 给脚本执行权限
chmod +x install_openwrt.sh

# 运行安装脚本
bash install_openwrt.sh
```

### 方法二：手动安装

```bash
# 1. 安装依赖
opkg update
opkg install python3 python3-pip python3-flask python3-yaml python3-requests git wget curl

# 2. 创建项目目录
mkdir -p /root/OpenClashManage
cd /root/OpenClashManage

# 3. 下载项目文件
wget -O app.py https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/app.py
wget -O jx.py https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/jx.py
wget -O zr.py https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/zr.py
wget -O zw.py https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/zw.py
wget -O jk.sh https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/jk.sh
wget -O log.py https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/log.py

# 4. 创建目录结构
mkdir -p templates wangluo

# 5. 下载模板文件
wget -O templates/index.html https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/templates/index.html

# 6. 安装Python依赖
pip3 install flask ruamel.yaml requests

# 7. 设置权限
chmod +x jk.sh
chmod 755 *.py
chmod 644 templates/*
chmod 644 wangluo/*

# 8. 创建初始配置文件
cat > wangluo/nodes.txt << 'EOF'
# 在此粘贴你的节点链接，一行一个
# 示例:
ss://YWVzLTI1Ni1nY206cGFzc3dvcmQ=@192.168.1.100:8388#测试节点1
EOF

touch wangluo/log.txt
```

## 🔧 启动服务

### 方法一：使用系统服务

```bash
# 启动服务
/etc/init.d/openclash-manage start

# 停止服务
/etc/init.d/openclash-manage stop

# 重启服务
/etc/init.d/openclash-manage restart

# 设置开机自启
/etc/init.d/openclash-manage enable
```

### 方法二：手动启动

```bash
cd /root/OpenClashManage
python3 app.py
```

## 🌐 访问管理面板

打开浏览器访问：`http://你的路由器IP:5000`

## 📝 配置文件

- **节点文件**: `/root/OpenClashManage/wangluo/nodes.txt`
- **日志文件**: `/root/OpenClashManage/wangluo/log.txt`
- **项目目录**: `/root/OpenClashManage/`

## 🔍 故障排除

### 1. 端口被占用
```bash
# 查看端口占用
netstat -tlnp | grep 5000

# 杀死占用进程
kill -9 进程ID
```

### 2. Python依赖问题
```bash
# 重新安装依赖
pip3 install --force-reinstall flask ruamel.yaml requests
```

### 3. 权限问题
```bash
# 重新设置权限
chmod +x /root/OpenClashManage/*.py
chmod +x /root/OpenClashManage/jk.sh
```

### 4. 查看日志
```bash
# 查看应用日志
tail -f /root/OpenClashManage/wangluo/log.txt

# 查看系统日志
logread | grep openclash
```

## 📋 功能特性

✅ **节点管理**
- 支持 SS、VMess、VLESS、Trojan 等协议
- 批量导入节点
- 单个节点手动添加
- 节点编辑和删除

✅ **实时监控**
- 守护进程状态监控
- OpenClash 运行状态
- 系统资源监控

✅ **自动化同步**
- 文件变化自动检测
- 配置自动注入
- 服务自动重启

✅ **Web界面**
- 现代化响应式设计
- 实时状态更新
- 中文界面支持

## 🆘 获取帮助

如果遇到问题，请检查：
1. 网络连接是否正常
2. Python3 是否正确安装
3. 端口 5000 是否被占用
4. 文件权限是否正确设置

## 📞 联系方式

如有问题，请通过以下方式联系：
- GitHub Issues: https://github.com/kuku0799/OpenClashManage/issues
- 项目地址: https://github.com/kuku0799/OpenClashManage 