# OpenWrt OpenClash管理工具

专为OpenWrt系统优化的OpenClash管理工具，提供Web界面管理节点和配置。

## 🚀 快速安装

### 方法一：一键安装（推荐）

```bash
# 下载安装脚本
wget https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/install_openwrt.sh

# 设置执行权限
chmod +x install_openwrt.sh

# 运行安装
bash install_openwrt.sh
```

### 方法二：手动安装

```bash
# 1. 更新软件包
opkg update

# 2. 安装基础依赖
opkg install python3 python3-pip python3-requests python3-yaml

# 3. 安装Python包
python3 -m pip install Flask==2.3.3 requests PyYAML

# 4. 创建目录
mkdir -p /root/OpenClashManage
cd /root/OpenClashManage

# 5. 下载文件
wget https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/app.py
wget https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/log.py
wget https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/jk.sh
wget https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/start_openwrt.sh

# 6. 设置权限
chmod +x *.py *.sh
```

## 📋 系统要求

- OpenWrt 18.06 或更高版本
- Python 3.6+
- 至少 32MB 可用内存
- 至少 10MB 可用存储空间

## 🔧 使用方法

### 启动服务

```bash
# 使用系统服务
/etc/init.d/openclash-manage start

# 或使用启动脚本
bash /root/OpenClashManage/start_openwrt.sh start
```

### 停止服务

```bash
# 使用系统服务
/etc/init.d/openclash-manage stop

# 或使用启动脚本
bash /root/OpenClashManage/start_openwrt.sh stop
```

### 查看状态

```bash
# 查看服务状态
/etc/init.d/openclash-manage status

# 或使用启动脚本
bash /root/OpenClashManage/start_openwrt.sh status
```

### 访问Web界面

安装完成后，在浏览器中访问：
```
http://你的路由器IP:5000
```

## 🛠️ 故障排除

### 运行诊断

```bash
# 运行故障排除脚本
bash fix_openwrt.sh

# 修复常见问题
bash fix_openwrt.sh fix
```

### 常见问题

#### 1. Python包安装失败

```bash
# 更新软件包列表
opkg update

# 尝试安装替代包
opkg install python3-base
opkg install python3-light

# 手动安装pip
wget https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py
```

#### 2. 端口被占用

```bash
# 查看端口占用
netstat -tlnp | grep :5000

# 杀死占用进程
kill -9 <PID>
```

#### 3. 权限问题

```bash
# 修复文件权限
chmod +x /root/OpenClashManage/*.py
chmod +x /root/OpenClashManage/*.sh
chmod 666 /root/OpenClashManage/wangluo/*.txt
```

#### 4. 内存不足

```bash
# 查看内存使用
free -h

# 清理缓存
sync && echo 3 > /proc/sys/vm/drop_caches
```

## 📁 文件结构

```
/root/OpenClashManage/
├── app.py              # 主程序
├── log.py              # 日志模块
├── jk.sh               # 守护进程脚本
├── start_openwrt.sh    # 启动脚本
├── fix_openwrt.sh      # 故障排除脚本
├── wangluo/
│   ├── nodes.txt       # 节点文件
│   └── log.txt         # 日志文件
└── templates/
    └── index.html      # Web界面模板
```

## 🔍 日志查看

```bash
# 查看应用日志
tail -f /root/OpenClashManage/wangluo/log.txt

# 查看系统日志
tail -f /var/log/messages

# 查看服务状态
/etc/init.d/openclash-manage status
```

## 🗑️ 卸载

```bash
# 使用卸载脚本
bash /root/OpenClashManage/uninstall_openwrt.sh

# 或手动卸载
/etc/init.d/openclash-manage stop
/etc/init.d/openclash-manage disable
rm -f /etc/init.d/openclash-manage
rm -rf /root/OpenClashManage
```

## 📝 配置说明

### 节点文件格式

在 `/root/OpenClashManage/wangluo/nodes.txt` 中添加节点，支持以下格式：

```
# SS节点
ss://YWVzLTI1Ni1nY206cGFzc3dvcmQ=@server:port#节点名称

# VMess节点
vmess://eyJhZGQiOiJzZXJ2ZXIiLCJwb3J0IjoiODA4MCIsImlkIjoiMTIzNDU2Nzg5MCIsIm5ldCI6IndzIiwidHlwZSI6Im5vbmUiLCJob3N0IjoiIiwicGF0aCI6IiIsInRscyI6IiJ9#节点名称

# VLESS节点
vless://uuid@server:port?security=tls&type=ws#节点名称

# Trojan节点
trojan://password@server:port#节点名称
```

### 支持的协议

- SS (Shadowsocks)
- VMess
- VLESS
- Trojan
- SSR
- Snell
- Hysteria
- TUIC

## 🔧 高级配置

### 修改端口

编辑 `app.py` 文件，修改端口号：

```python
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
```

### 修改路径

编辑相关文件中的路径配置：

```python
ROOT_DIR = "/root/OpenClashManage"
NODES_FILE = f"{ROOT_DIR}/wangluo/nodes.txt"
CONFIG_FILE = "/etc/openclash/config.yaml"
```

### 自定义防火墙规则

```bash
# 添加防火墙规则
iptables -I INPUT -p tcp --dport 5000 -j ACCEPT

# 保存规则
iptables-save > /etc/iptables.rules
```

## 📞 技术支持

如果遇到问题，请：

1. 运行故障排除脚本：`bash fix_openwrt.sh`
2. 查看日志文件：`tail -f /root/OpenClashManage/wangluo/log.txt`
3. 检查系统状态：`/etc/init.d/openclash-manage status`

## 📄 许可证

本项目采用 MIT 许可证。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

**注意：** 此工具仅用于学习和研究目的，请遵守当地法律法规。 