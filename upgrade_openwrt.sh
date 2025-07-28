#!/bin/bash

# OpenClash管理面板 - OpenWrt升级脚本
# 适用于更新现有安装

echo "🔄 开始升级OpenClash管理面板..."
echo "=================================="

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请使用root权限运行此脚本"
    exit 1
fi

# 设置安装目录
INSTALL_DIR="/root/OpenClashManage"
echo "📁 安装目录: $INSTALL_DIR"

# 检查是否已安装
if [ ! -d "$INSTALL_DIR" ]; then
    echo "❌ 未找到现有安装，请先运行完整安装脚本"
    echo "运行: bash install_openwrt_complete.sh"
    exit 1
fi

echo "✅ 找到现有安装，开始升级..."

# 停止现有服务
echo "🛑 停止现有服务..."
/etc/init.d/openclash-manage stop 2>/dev/null || true
pkill -f "python3 app.py" 2>/dev/null || true

# 备份现有配置
echo "📦 备份现有配置..."
BACKUP_DIR="/root/OpenClashManage_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# 备份重要文件
if [ -f "$INSTALL_DIR/wangluo/nodes.txt" ]; then
    cp "$INSTALL_DIR/wangluo/nodes.txt" "$BACKUP_DIR/"
    echo "✅ 已备份节点文件"
fi

if [ -f "$INSTALL_DIR/wangluo/log.txt" ]; then
    cp "$INSTALL_DIR/wangluo/log.txt" "$BACKUP_DIR/"
    echo "✅ 已备份日志文件"
fi

# 下载最新文件
echo "📥 下载最新文件..."
cd "$INSTALL_DIR"

# 下载核心文件
wget -O app.py https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/app.py
wget -O jx.py https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/jx.py
wget -O zr.py https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/zr.py
wget -O zw.py https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/zw.py
wget -O jk.sh https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/jk.sh
wget -O log.py https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/log.py
wget -O requirements.txt https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/requirements.txt

# 下载模板文件
mkdir -p templates
wget -O templates/index.html https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/templates/index.html

# 设置文件权限
echo "🔧 设置文件权限..."
chmod +x jk.sh
chmod +x zr.py
chmod +x zw.py

# 更新Python依赖
echo "📦 更新Python依赖..."
pip3 install --upgrade flask ruamel.yaml requests

# 更新系统服务
echo "📝 更新系统服务..."
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

# 更新启动脚本
echo "📝 更新启动脚本..."
cat > start_openclash_manage.sh << 'EOF'
#!/bin/bash
cd /root/OpenClashManage
python3 app.py &
echo "OpenClash管理面板已启动，访问地址: http://$(uci get network.lan.ipaddr):5000"
EOF

chmod +x start_openclash_manage.sh

# 更新停止脚本
echo "📝 更新停止脚本..."
cat > stop_openclash_manage.sh << 'EOF'
#!/bin/bash
pkill -f "python3 app.py"
echo "OpenClash管理面板已停止"
EOF

chmod +x stop_openclash_manage.sh

# 确保防火墙规则存在
echo "🔧 检查防火墙规则..."
if ! grep -q "OpenClash-Manage" /etc/config/firewall 2>/dev/null; then
    echo "添加防火墙规则..."
    cat >> /etc/config/firewall << 'EOF'

config rule
    option name 'OpenClash-Manage'
    option src 'lan'
    option proto 'tcp'
    option dest_port '5000'
    option target 'ACCEPT'
EOF
    /etc/init.d/firewall restart
fi

# 获取路由器IP地址
ROUTER_IP=$(uci get network.lan.ipaddr 2>/dev/null || echo "192.168.1.1")

echo ""
echo "✅ 升级完成！"
echo "=================================="
echo "🌐 访问地址: http://$ROUTER_IP:5000"
echo "📁 安装目录: $INSTALL_DIR"
echo "📦 备份目录: $BACKUP_DIR"
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
echo "🎉 OpenClash管理面板已成功升级并启动！"
echo "请在浏览器中访问: http://$ROUTER_IP:5000"
echo ""
echo "💡 如果遇到问题，可以恢复备份："
echo "  cp $BACKUP_DIR/* $INSTALL_DIR/wangluo/" 