# OpenWrt OpenClash管理面板完整安装指南

## 🎯 安装目标
将OpenClash管理面板完整安装到OpenWrt系统上，实现：
- 节点管理（添加、删除、编辑）
- 自动同步到OpenClash配置
- Web界面管理
- 实时状态监控

## 📋 系统要求
- OpenWrt 21.02+ 或 22.03+
- 至少 50MB 可用空间
- 支持Python3的OpenWrt系统

## 🚀 快速安装

### **方法一：一键安装（推荐）**

```bash
# 1. 下载安装脚本
wget https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/install_openwrt_complete.sh

# 2. 给脚本执行权限
chmod +x install_openwrt_complete.sh

# 3. 运行安装脚本
bash install_openwrt_complete.sh
```

### **方法二：分步安装**

#### **步骤1：配置软件源**
```bash
# 下载软件源配置脚本
wget https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/setup_openwrt_sources_complete.sh

# 给脚本执行权限
chmod +x setup_openwrt_sources_complete.sh

# 运行软件源配置
bash setup_openwrt_sources_complete.sh
```

#### **步骤2：安装OpenClash管理面板**
```bash
# 下载安装脚本
wget https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/install_openwrt_complete.sh

# 给脚本执行权限
chmod +x install_openwrt_complete.sh

# 运行安装脚本
bash install_openwrt_complete.sh
```

## 📁 安装后的文件结构

```
/root/OpenClashManage/
├── app.py                 # Flask主应用
├── jx.py                  # 节点解析器
├── zr.py                  # 同步处理器
├── zw.py                  # 配置注入器
├── jk.sh                  # 监控脚本
├── log.py                 # 日志模块
├── requirements.txt       # Python依赖
├── templates/
│   └── index.html        # Web界面模板
├── wangluo/              # 数据目录
│   ├── nodes.txt         # 节点文件
│   └── log.txt           # 日志文件
├── start_openclash_manage.sh  # 启动脚本
└── stop_openclash_manage.sh   # 停止脚本
```

## 🔧 管理命令

### **系统服务管理**
```bash
# 启动服务
/etc/init.d/openclash-manage start

# 停止服务
/etc/init.d/openclash-manage stop

# 重启服务
/etc/init.d/openclash-manage restart

# 查看状态
/etc/init.d/openclash-manage status

# 启用开机自启
/etc/init.d/openclash-manage enable

# 禁用开机自启
/etc/init.d/openclash-manage disable
```

### **手动管理**
```bash
# 进入安装目录
cd /root/OpenClashManage

# 启动管理面板
python3 app.py

# 停止管理面板
pkill -f "python3 app.py"

# 查看进程
ps aux | grep app.py
```

## 🌐 访问地址

安装完成后，在浏览器中访问：
```
http://路由器IP:5000
```

例如：
- `http://192.168.1.1:5000`
- `http://192.168.5.1:5000`
- `http://10.0.0.1:5000`

## 🔍 功能验证

### **1. 基本功能测试**
- ✅ 访问Web界面
- ✅ 查看节点列表
- ✅ 添加新节点
- ✅ 删除节点
- ✅ 编辑节点信息

### **2. 高级功能测试**
- ✅ 节点链接解析
- ✅ 手动添加节点
- ✅ 批量操作
- ✅ 搜索功能
- ✅ 实时状态监控

### **3. 同步功能测试**
- ✅ 启动监控服务
- ✅ 修改节点后自动同步
- ✅ OpenClash配置更新
- ✅ 日志记录

## 🛠️ 故障排除

### **问题1：无法访问Web界面**
```bash
# 检查服务状态
/etc/init.d/openclash-manage status

# 检查端口是否监听
netstat -tlnp | grep :5000

# 检查防火墙
iptables -L | grep 5000

# 重启服务
/etc/init.d/openclash-manage restart
```

### **问题2：Python依赖缺失**
```bash
# 重新安装Python依赖
pip3 install flask ruamel.yaml requests

# 或者使用opkg安装
opkg install python3-flask python3-yaml python3-requests
```

### **问题3：OpenClash配置同步失败**
```bash
# 检查OpenClash是否安装
opkg list-installed | grep openclash

# 检查配置文件权限
ls -la /etc/openclash/

# 手动测试同步
cd /root/OpenClashManage
python3 zr.py
```

### **问题4：节点解析失败**
```bash
# 检查节点文件
cat /root/OpenClashManage/wangluo/nodes.txt

# 查看日志
tail -f /root/OpenClashManage/wangluo/log.txt

# 测试解析器
cd /root/OpenClashManage
python3 jx.py
```

## 📊 性能优化

### **1. 内存优化**
```bash
# 限制Python进程内存使用
sed -i 's/python3 app.py/python3 -X maxsize=50m app.py/' /etc/init.d/openclash-manage
```

### **2. 日志轮转**
```bash
# 创建日志轮转配置
cat > /etc/logrotate.d/openclash-manage << 'EOF'
/root/OpenClashManage/wangluo/log.txt {
    daily
    rotate 7
    compress
    missingok
    notifempty
}
EOF
```

### **3. 监控脚本优化**
```bash
# 优化监控脚本执行频率
sed -i 's/sleep 5/sleep 10/' /root/OpenClashManage/jk.sh
```

## 🔒 安全配置

### **1. 防火墙配置**
```bash
# 只允许局域网访问
iptables -I INPUT -p tcp --dport 5000 -s 192.168.0.0/16 -j ACCEPT
iptables -I INPUT -p tcp --dport 5000 -j DROP
```

### **2. 访问控制**
```bash
# 修改Flask配置，只监听局域网
sed -i 's/host=.*/host="192.168.1.1"/' /root/OpenClashManage/app.py
```

## 📈 监控和维护

### **1. 系统监控**
```bash
# 查看服务状态
systemctl status openclash-manage

# 查看资源使用
top -p $(pgrep -f "python3 app.py")

# 查看磁盘使用
df -h /root/OpenClashManage/
```

### **2. 日志分析**
```bash
# 查看实时日志
tail -f /root/OpenClashManage/wangluo/log.txt

# 查看错误日志
grep "ERROR" /root/OpenClashManage/wangluo/log.txt

# 查看访问日志
grep "GET\|POST" /root/OpenClashManage/wangluo/log.txt
```

## 🎉 安装完成

安装完成后，您将拥有一个功能完整的OpenClash管理面板，可以：
- 通过Web界面管理节点
- 自动同步到OpenClash配置
- 实时监控系统状态
- 支持多种节点协议

如有问题，请查看日志文件或联系技术支持。 