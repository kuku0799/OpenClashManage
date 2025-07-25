#!/bin/bash

# OpenClash 管理面板一键安装脚本
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
        print_message "请使用: sudo bash install.sh"
        exit 1
    fi
}

# 检查系统类型
check_system() {
    print_step "检查系统环境..."
    
    if [[ -f /etc/openwrt_release ]]; then
        print_message "检测到 OpenWrt 系统"
        SYSTEM_TYPE="openwrt"
    elif [[ -f /etc/debian_version ]]; then
        print_message "检测到 Debian/Ubuntu 系统"
        SYSTEM_TYPE="debian"
    else
        print_warning "未知系统类型，可能不完全兼容"
        SYSTEM_TYPE="unknown"
    fi
}

# 安装依赖
install_dependencies() {
    print_step "安装系统依赖..."
    
    if [[ "$SYSTEM_TYPE" == "openwrt" ]]; then
        # OpenWrt 依赖安装
        opkg update
        opkg install python3 python3-pip python3-yaml
        opkg install luci-app-openclash || print_warning "OpenClash 未安装，请手动安装"
    elif [[ "$SYSTEM_TYPE" == "debian" ]]; then
        # Debian/Ubuntu 依赖安装
        apt update
        apt install -y python3 python3-pip python3-yaml
    else
        print_warning "请手动安装 Python3 和相关依赖"
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
    pip3 install -r requirements.txt
    
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

# 创建服务文件
create_service() {
    print_step "创建系统服务..."
    
    SERVICE_FILE="/etc/systemd/system/openclash-manage.service"
    
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=OpenClash Management Panel
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root/OpenClashManage
ExecStart=/usr/bin/python3 /root/OpenClashManage/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable openclash-manage.service
    
    print_message "✓ 系统服务创建完成"
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
    echo "   http://$(hostname -I | awk '{print $1}'):8080"
    echo ""
    echo "🔧 管理命令:"
    echo "   启动服务: systemctl start openclash-manage"
    echo "   停止服务: systemctl stop openclash-manage"
    echo "   重启服务: systemctl restart openclash-manage"
    echo "   查看状态: systemctl status openclash-manage"
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
    echo "    OpenClash 管理面板一键安装脚本"
    echo "=========================================="
    echo ""
    
    check_root
    check_system
    install_dependencies
    create_directories
    download_files
    install_python_deps
    set_permissions
    create_service
    create_initial_config
    check_openclash
    show_result
}

# 运行主函数
main "$@" 