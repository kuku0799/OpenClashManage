#!/bin/sh

# OpenClash管理面板 - 一键部署脚本
# 从GitHub自动下载并安装

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# GitHub仓库信息
GITHUB_REPO="kuku0799/OpenClashManage"
GITHUB_RAW="https://raw.githubusercontent.com/$GITHUB_REPO/main"

print_header() {
    echo -e "${BLUE}"
    echo "=========================================="
    echo "    OpenClash管理面板 - 一键部署"
    echo "=========================================="
    echo -e "${NC}"
}

print_step() {
    echo -e "${GREEN}[步骤 $1]${NC} $2"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# 检查网络连接
check_network() {
    print_step "1" "检查网络连接..."
    
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        print_success "网络连接正常"
    else
        print_error "网络连接失败，请检查网络设置"
        exit 1
    fi
}

# 下载安装脚本
download_install_script() {
    print_step "2" "下载安装脚本..."
    
    # 创建临时目录
    mkdir -p /tmp/openclash_install
    cd /tmp/openclash_install
    
    # 下载安装脚本
    if wget -q "$GITHUB_RAW/install_openwrt.sh"; then
        print_success "安装脚本下载成功"
        chmod +x install_openwrt.sh
    else
        print_error "安装脚本下载失败"
        exit 1
    fi
}

# 下载应用文件
download_app_files() {
    print_step "3" "下载应用文件..."
    
    # 下载主应用文件
    for file in app.py log.py; do
        if wget -q "$GITHUB_RAW/$file"; then
            print_success "$file 下载成功"
        else
            print_error "$file 下载失败"
            exit 1
        fi
    done
    
    # 下载templates目录
    mkdir -p templates
    if wget -q "$GITHUB_RAW/templates/index.html" -O templates/index.html; then
        print_success "templates/index.html 下载成功"
    else
        print_error "templates/index.html 下载失败"
        exit 1
    fi
}

# 运行安装
run_installation() {
    print_step "4" "开始安装..."
    
    # 运行安装脚本
    ./install_openwrt.sh install
    
    if [ $? -eq 0 ]; then
        print_success "安装完成！"
    else
        print_error "安装失败"
        exit 1
    fi
}

# 显示安装结果
show_result() {
    echo ""
    echo -e "${BLUE}=========================================="
    echo "    部署完成！"
    echo "=========================================="
    echo -e "${NC}"
    
    echo -e "${GREEN}✓ OpenClash管理面板部署成功${NC}"
    echo ""
    echo "📱 访问地址:"
    echo "  本地访问: http://localhost:8888"
    echo "  局域网访问: http://192.168.5.1:8888"
    echo ""
    echo "🔧 管理命令:"
    echo "  启动: /etc/init.d/openclash-manage start"
    echo "  停止: /etc/init.d/openclash-manage stop"
    echo "  重启: /etc/init.d/openclash-manage restart"
    echo "  状态: /etc/init.d/openclash-manage status"
    echo "  日志: /root/OpenClashManage/manage.sh logs"
    echo ""
    echo "🔄 开机自启动: 已启用"
    echo "📁 安装目录: /root/OpenClashManage"
    echo ""
    echo -e "${YELLOW}💡 提示: 现在可以在浏览器中访问管理面板了！${NC}"
}

# 清理临时文件
cleanup() {
    print_step "5" "清理临时文件..."
    rm -rf /tmp/openclash_install
    print_success "清理完成"
}

# 主函数
main() {
    print_header
    
    # 检查root权限
    if [ "$(id -u)" != "0" ]; then
        print_error "此脚本需要root权限运行"
        exit 1
    fi
    
    # 执行部署步骤
    check_network
    download_install_script
    download_app_files
    run_installation
    cleanup
    show_result
}

# 运行主函数
main "$@" 