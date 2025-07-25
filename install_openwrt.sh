#!/bin/bash

# OpenClash 管理面板 - OpenWrt 专用安装脚本
# 作者: OpenClashManage
# 版本: 1.0.0

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "此脚本需要root权限运行"
        print_message "请使用: bash install_openwrt.sh"
        exit 1
    fi
}

# 检查OpenWrt系统
check_openwrt() {
    print_step "检查OpenWrt系统..."
    
    if [[ -f /etc/openwrt_release ]]; then
        print_message "✅ 检测到 OpenWrt 系统"
    else
        print_error "❌ 此脚本仅适用于 OpenWrt 系统"
        exit 1
    fi
}

# 安装OpenWrt依赖
install_openwrt_deps() {
    print_step "安装OpenWrt依赖..."
    
    # 更新软件包列表
    opkg update
    
    # 安装必要的包
    opkg install python3 python3-pip python3-yaml curl wget
    
    # 检查OpenClash是否安装
    if ! opkg list-installed | grep -q "luci-app-openclash"; then
        print_warning "⚠️  OpenClash 未安装，请手动安装"
        print_message "安装命令: opkg install luci-app-openclash"
    else
        print_message "✅ OpenClash 已安装"
    fi
}

# 创建项目目录
create_directories() {
    print_step "创建项目目录..."
    
    PROJECT_DIR="/root/OpenClashManage"
    mkdir -p "$PROJECT_DIR"
    mkdir -p "$PROJECT_DIR/wangluo"
    mkdir -p "$PROJECT_DIR/templates"
    
    print_message "项目目录: $PROJECT_DIR"
}

# 下载项目文件
download_files() {
    print_step "下载项目文件..."
    
    GITHUB_REPO="https://raw.githubusercontent.com/kuku0799/OpenClashManage/main"
    
    # 下载主要文件
    files=(
        "app.py"
        "requirements.txt"
        "start.sh"
        "jk.sh"
        "jx.py"
        "log.py"
        "zc.py"
        "zr.py"
        "zw.py"
        "templates/index.html"
    )
    
    for file in "${files[@]}"; do
        print_message "下载 $file..."
        if [[ "$file" == "templates/index.html" ]]; then
            mkdir -p "$PROJECT_DIR/templates"
            curl -sSL "$GITHUB_REPO/$file" -o "$PROJECT_DIR/$file"
        else
            curl -sSL "$GITHUB_REPO/$file" -o "$PROJECT_DIR/$file"
        fi
        
        if [[ $? -eq 0 ]]; then
            print_message "✓ $file 下载成功"
        else
            print_error "✗ $file 下载失败"
            exit 1
        fi
    done
}

# 安装Python依赖
install_python_deps() {
    print_step "安装Python依赖..."
    
    cd /root/OpenClashManage
    
    # 使用pip3安装依赖
    pip3 install Flask==2.3.3 ruamel.yaml==0.18.5
    
    if [[ $? -eq 0 ]]; then
        print_message "✓ Python依赖安装成功"
    else
        print_error "✗ Python依赖安装失败"
        exit 1
    fi
}

# 设置文件权限
set_permissions() {
    print_step "设置文件权限..."
    
    chmod +x /root/OpenClashManage/start.sh
    chmod +x /root/OpenClashManage/jk.sh
    chmod +x /root/OpenClashManage/zr.py
    chmod +x /root/OpenClashManage/zw.py
    
    print_message "✓ 文件权限设置完成"
}

# 创建OpenWrt服务文件
create_openwrt_service() {
    print_step "创建OpenWrt服务..."
    
    SERVICE_FILE="/etc/init.d/openclash-manage"
    
    cat > "$SERVICE_FILE" << 'EOF'
#!/bin/sh /etc/rc.common

START=99
STOP=15

start() {
    echo "启动 OpenClash 管理面板..."
    cd /root/OpenClashManage
    python3 app.py > /dev/null 2>&1 &
    echo $! > /var/run/openclash-manage.pid
}

stop() {
    echo "停止 OpenClash 管理面板..."
    if [ -f /var/run/openclash-manage.pid ]; then
        kill $(cat /var/run/openclash-manage.pid) 2>/dev/null
        rm -f /var/run/openclash-manage.pid
    fi
}

restart() {
    stop
    sleep 2
    start
}

status() {
    if [ -f /var/run/openclash-manage.pid ]; then
        echo "OpenClash 管理面板正在运行"
    else
        echo "OpenClash 管理面板未运行"
    fi
}
EOF

    chmod +x "$SERVICE_FILE"
    /etc/init.d/openclash-manage enable
    
    print_message "✓ OpenWrt服务创建完成"
}

# 创建初始配置文件
create_initial_config() {
    print_step "创建初始配置..."
    
    # 创建空的节点文件
    cat > /root/OpenClashManage/wangluo/nodes.txt << EOF
# 在此粘贴你的节点链接，一行一个，支持 ss:// vmess:// vless:// trojan://协议
# 示例:
# ss://YWVzLTI1Ni1nY206cGFzc3dvcmQ=@server:port#节点名称
# vmess://eyJhZGQiOiJzZXJ2ZXIiLCJwb3J0IjoiODA4MCIsImlkIjoiMTIzNDU2Nzg5MCIsIm5ldCI6IndzIiwidHlwZSI6Im5vbmUiLCJob3N0IjoiIiwicGF0aCI6IiIsInRscyI6IiJ9#节点名称
EOF

    # 创建空的日志文件
    touch /root/OpenClashManage/wangluo/log.txt
    
    print_message "✓ 初始配置文件创建完成"
}

# 检查OpenClash安装
check_openclash() {
    print_step "检查OpenClash安装..."
    
    if [[ -f "/etc/openclash/config.yaml" ]]; then
        print_message "✓ OpenClash 已安装"
    else
        print_warning "⚠️  OpenClash 未安装或配置文件不存在"
        print_message "请确保 OpenClash 已正确安装"
    fi
}

# 显示安装结果
show_result() {
    print_step "安装完成！"
    
    echo ""
    echo "🎉 OpenClash 管理面板安装成功！"
    echo ""
    echo "📱 访问地址:"
    echo "   http://$(uci get network.lan.ipaddr 2>/dev/null || echo "192.168.1.1"):8080"
    echo ""
    echo "🔧 管理命令:"
    echo "   启动服务: /etc/init.d/openclash-manage start"
    echo "   停止服务: /etc/init.d/openclash-manage stop"
    echo "   重启服务: /etc/init.d/openclash-manage restart"
    echo "   查看状态: /etc/init.d/openclash-manage status"
    echo ""
    echo "📁 项目目录: /root/OpenClashManage"
    echo "📝 节点文件: /root/OpenClashManage/wangluo/nodes.txt"
    echo "📋 日志文件: /root/OpenClashManage/wangluo/log.txt"
    echo ""
    echo "🚀 现在可以启动服务并访问管理面板了！"
}

# 主函数
main() {
    echo "=========================================="
    echo "    OpenClash 管理面板 - OpenWrt 安装"
    echo "=========================================="
    echo ""
    
    check_root
    check_openwrt
    install_openwrt_deps
    create_directories
    download_files
    install_python_deps
    set_permissions
    create_openwrt_service
    create_initial_config
    check_openclash
    show_result
}

# 运行主函数
main "$@" 