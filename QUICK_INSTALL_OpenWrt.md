# OpenWrt 快速安装指南

## 🚀 一键安装

### 步骤1：下载安装脚本

```bash
wget https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/install_openwrt.sh
chmod +x install_openwrt.sh
```

### 步骤2：运行安装

```bash
bash install_openwrt.sh
```

### 步骤3：启动服务

```bash
/etc/init.d/openclash-manage start
```

### 步骤4：访问Web界面

在浏览器中访问：`http://你的路由器IP:5000`

## 🔧 如果遇到问题

### 问题1：Python包安装失败

```bash
# 更新软件包
opkg update

# 安装基础包
opkg install python3 python3-pip

# 手动安装pip（如果opkg安装失败）
wget https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py

# 安装Python依赖
python3 -m pip install Flask requests PyYAML
```

### 问题2：端口被占用

```bash
# 查看端口占用
netstat -tlnp | grep :5000

# 杀死占用进程
kill -9 <PID>
```

### 问题3：权限问题

```bash
# 修复权限
chmod +x /root/OpenClashManage/*.py
chmod +x /root/OpenClashManage/*.sh
chmod 666 /root/OpenClashManage/wangluo/*.txt
```

### 问题4：运行故障排除

```bash
# 下载故障排除脚本
wget https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/fix_openwrt.sh
chmod +x fix_openwrt.sh

# 运行诊断
bash fix_openwrt.sh

# 自动修复
bash fix_openwrt.sh fix
```

## 📋 常用命令

```bash
# 启动服务
/etc/init.d/openclash-manage start

# 停止服务
/etc/init.d/openclash-manage stop

# 重启服务
/etc/init.d/openclash-manage restart

# 查看状态
/etc/init.d/openclash-manage status

# 查看日志
tail -f /root/OpenClashManage/wangluo/log.txt

# 编辑节点文件
nano /root/OpenClashManage/wangluo/nodes.txt
```

## 🎯 快速测试

```bash
# 测试应用启动
cd /root/OpenClashManage
python3 app.py

# 在另一个终端测试访问
curl http://localhost:5000
```

## 📞 获取帮助

如果遇到问题，请：

1. 运行故障排除脚本：`bash fix_openwrt.sh`
2. 查看详细日志：`tail -f /root/OpenClashManage/wangluo/log.txt`
3. 检查系统状态：`/etc/init.d/openclash-manage status`

---

**安装完成后，您就可以通过Web界面管理OpenClash节点了！** 