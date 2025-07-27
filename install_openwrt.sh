#!/bin/bash

# OpenClash管理面板安装脚本
# 适用于OpenWrt系统

echo "🚀 开始安装OpenClash管理面板..."

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请使用root权限运行此脚本"
    exit 1
fi

# 更新软件包列表
echo "📦 更新软件包列表..."
opkg update

# 安装必要的软件包
echo "📦 安装必要的软件包..."
opkg install python3 python3-pip python3-flask python3-yaml python3-requests git wget curl

# 创建安装目录
INSTALL_DIR="/root/OpenClashManage"
echo "📁 创建安装目录: $INSTALL_DIR"
mkdir -p $INSTALL_DIR
cd $INSTALL_DIR

# 下载项目文件
echo "📥 下载项目文件..."
wget -O app.py https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/app.py
wget -O jx.py https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/jx.py
wget -O zr.py https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/zr.py
wget -O zw.py https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/zw.py
wget -O jk.sh https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/jk.sh
wget -O log.py https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/log.py
wget -O requirements.txt https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/requirements.txt
wget -O README.md https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/README.md

# 创建必要的目录
mkdir -p templates
mkdir -p wangluo

# 下载模板文件
echo "📥 下载模板文件..."
wget -O templates/index.html https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/templates/index.html

# 创建初始节点文件
echo "📝 创建初始节点文件..."
cat > wangluo/nodes.txt << 'EOF'
# 在此粘贴你的节点链接，一行一个，支持 ss:// vmess:// vless:// trojan://协议
# 示例:
# ss://YWVzLTI1Ni1nY206cGFzc3dvcmQ=@server:port#节点名称
# vmess://eyJhZGQiOiJzZXJ2ZXIiLCJwb3J0IjoiODA4MCIsImlkIjoiMTIzNDU2Nzg5MCIsIm5ldCI6IndzIiwidHlwZSI6Im5vbmUiLCJob3N0IjoiIiwicGF0aCI6IiIsInRscyI6IiJ9#节点名称

# 测试节点（可以删除这些测试节点）
ss://YWVzLTI1Ni1nY206cGFzc3dvcmQ=@192.168.1.100:8388#测试节点1
vmess://eyJhZGQiOiIxOTIuMTY4LjEuMTAwIiwicG9ydCI6IjgwODAiLCJpZCI6IjEyMzQ1Njc4OTAiLCJuZXQiOiJ3cyIsInR5cGUiOiJub25lIiwiaG9zdCI6IiIsInBhdGgiOiIiLCJ0bHMiOiIifQ==#测试节点2
vless://12345678-1234-1234-1234-123456789012@192.168.1.100:443?security=tls&type=ws#测试节点3
trojan://password@192.168.1.100:443#测试节点4
EOF

# 创建日志文件
touch wangluo/log.txt

# 设置文件权限
echo "🔐 设置文件权限..."
chmod +x jk.sh
chmod 755 *.py
chmod 644 templates/*
chmod 644 wangluo/*

# 安装Python依赖
echo "📦 安装Python依赖..."
pip3 install flask ruamel.yaml requests

# 创建启动脚本
echo "📝 创建启动脚本..."
cat > start.sh << 'EOF'
#!/bin/bash
cd /root/OpenClashManage
python3 app.py
EOF

chmod +x start.sh

# 创建服务文件
echo "📝 创建系统服务..."
cat > /etc/init.d/openclash-manage << 'EOF'
#!/bin/sh /etc/rc.common

START=99
STOP=15

start() {
    echo "启动OpenClash管理面板..."
    cd /root/OpenClashManage
    python3 app.py > /dev/null 2>&1 &
    echo $! > /var/run/openclash-manage.pid
}

stop() {
    echo "停止OpenClash管理面板..."
    if [ -f /var/run/openclash-manage.pid ]; then
        kill $(cat /var/run/openclash-manage.pid)
        rm -f /var/run/openclash-manage.pid
    fi
}

restart() {
    stop
    sleep 2
    start
}
EOF

chmod +x /etc/init.d/openclash-manage

# 启用服务
echo "🔧 启用系统服务..."
/etc/init.d/openclash-manage enable

echo "✅ 安装完成！"
echo ""
echo "📋 使用说明："
echo "1. 启动服务: /etc/init.d/openclash-manage start"
echo "2. 停止服务: /etc/init.d/openclash-manage stop"
echo "3. 重启服务: /etc/init.d/openclash-manage restart"
echo "4. 手动启动: cd /root/OpenClashManage && python3 app.py"
echo ""
echo "🌐 访问地址: http://你的路由器IP:5000"
echo ""
echo "📝 编辑节点文件: nano /root/OpenClashManage/wangluo/nodes.txt"
echo "📊 查看日志: tail -f /root/OpenClashManage/wangluo/log.txt"
echo ""
echo "🚀 现在可以启动服务了！" 