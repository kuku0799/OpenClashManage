#!/bin/bash

# OpenClash管理面板 - OpenWrt完整安装脚本
# 适用于OpenWrt系统

echo "🚀 开始安装OpenClash管理面板到OpenWrt系统..."
echo "================================================"

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请使用root权限运行此脚本"
    exit 1
fi

# 设置安装目录
INSTALL_DIR="/root/OpenClashManage"
echo "📁 安装目录: $INSTALL_DIR"

# 更新软件包列表
echo "📦 更新软件包列表..."
opkg update

# 安装必要的软件包
echo "📦 安装必要的软件包..."
opkg install python3 python3-pip python3-flask python3-yaml python3-requests git wget curl

# 创建安装目录
echo "📁 创建安装目录..."
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

# 创建templates目录并下载模板文件
mkdir -p templates
wget -O templates/index.html https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/templates/index.html

# 创建wangluo目录
mkdir -p wangluo

# 安装Python依赖
echo "📦 安装Python依赖..."
pip3 install flask ruamel.yaml requests

# 设置文件权限
echo "🔧 设置文件权限..."
chmod +x jk.sh
chmod +x zr.py
chmod +x zw.py

# 创建启动脚本
echo "📝 创建启动脚本..."
cat > start_openclash_manage.sh << 'EOF'
#!/bin/bash
cd /root/OpenClashManage
python3 app.py &
echo "OpenClash管理面板已启动，访问地址: http://$(uci get network.lan.ipaddr):5000"
EOF

chmod +x start_openclash_manage.sh

# 创建停止脚本
echo "📝 创建停止脚本..."
cat > stop_openclash_manage.sh << 'EOF'
#!/bin/bash
pkill -f "python3 app.py"
echo "OpenClash管理面板已停止"
EOF

chmod +x stop_openclash_manage.sh

# 创建系统服务
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
        kill $(cat /var/run/openclash-manage.pid) 2>/dev/null
        rm -f /var/run/openclash-manage.pid
    fi
    pkill -f "python3 app.py" 2>/dev/null
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

# 创建防火墙规则
echo "🔧 配置防火墙..."
cat >> /etc/config/firewall << 'EOF'

config rule
    option name 'OpenClash-Manage'
    option src 'lan'
    option proto 'tcp'
    option dest_port '5000'
    option target 'ACCEPT'
EOF

# 重启防火墙
/etc/init.d/firewall restart

# 获取路由器IP地址
ROUTER_IP=$(uci get network.lan.ipaddr 2>/dev/null || echo "192.168.1.1")

echo ""
echo "✅ 安装完成！"
echo "================================================"
echo "🌐 访问地址: http://$ROUTER_IP:5000"
echo "📁 安装目录: $INSTALL_DIR"
echo ""
echo "🔧 管理命令:"
echo "  启动服务: /etc/init.d/openclash-manage start"
echo "  停止服务: /etc/init.d/openclash-manage stop"
echo "  重启服务: /etc/init.d/openclash-manage restart"
echo "  查看状态: /etc/init.d/openclash-manage status"
echo ""
echo "🚀 现在启动服务..."
/etc/init.d/openclash-manage start

echo ""
echo "🎉 OpenClash管理面板已成功安装并启动！"
echo "请在浏览器中访问: http://$ROUTER_IP:5000" 