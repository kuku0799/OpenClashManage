#!/bin/sh

# OpenClash管理面板 - OpenWrt一键安装脚本
# 作者: OpenClashManage
# 版本: 1.0
# 支持架构: aarch64, x86_64

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
APP_NAME="OpenClash管理面板"
APP_DIR="/root/OpenClashManage"
LOG_FILE="$APP_DIR/install.log"
SERVICE_NAME="openclash-manage"
ACCESS_IP="192.168.5.1"
ACCESS_PORT="8888"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

print_header() {
    echo -e "${BLUE}"
    echo "=========================================="
    echo "    OpenClash管理面板 - 一键安装脚本"
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

# 检查root权限
check_root() {
    if [ "$(id -u)" != "0" ]; then
        print_error "此脚本需要root权限运行"
        exit 1
    fi
}

# 检查系统架构
check_architecture() {
    ARCH=$(uname -m)
    log "系统架构: $ARCH"
    
    case $ARCH in
        aarch64)
            print_success "检测到ARM64架构"
            ;;
        x86_64)
            print_success "检测到x86_64架构"
            ;;
        armv7l)
            print_success "检测到ARMv7架构"
            ;;
        mips)
            print_success "检测到MIPS架构"
            ;;
        mipsel)
            print_success "检测到MIPSel架构"
            ;;
        *)
            print_warning "未测试的架构: $ARCH，但会尝试安装"
            ;;
    esac
}

# 检查OpenWrt版本
check_openwrt() {
    if [ -f /etc/openwrt_release ]; then
        . /etc/openwrt_release
        log "OpenWrt版本: $DISTRIB_RELEASE"
        log "目标架构: $DISTRIB_TARGET"
        print_success "检测到OpenWrt系统"
    else
        print_error "未检测到OpenWrt系统"
        exit 1
    fi
}

# 更新软件包列表
update_packages() {
    print_step "1" "更新软件包列表..."
    opkg update
    if [ $? -eq 0 ]; then
        print_success "软件包列表更新成功"
    else
        print_error "软件包列表更新失败"
        exit 1
    fi
}

# 安装Python3
install_python3() {
    print_step "2" "安装Python3..."
    
    # 检查Python3是否已安装
    if command -v python3 >/dev/null 2>&1; then
        print_success "Python3已安装"
        python3 --version
    else
        print_warning "正在安装Python3..."
        opkg install python3
        if [ $? -eq 0 ]; then
            print_success "Python3安装成功"
        else
            print_error "Python3安装失败"
            exit 1
        fi
    fi
}

# 安装pip
install_pip() {
    print_step "3" "安装pip..."
    
    # 检查pip是否已安装
    if command -v pip3 >/dev/null 2>&1; then
        print_success "pip已安装"
    else
        print_warning "正在安装pip..."
        opkg install python3-pip
        if [ $? -eq 0 ]; then
            print_success "pip安装成功"
        else
            print_error "pip安装失败"
            exit 1
        fi
    fi
}

# 安装Python依赖
install_python_deps() {
    print_step "4" "安装Python依赖..."
    
    # 安装Flask
    python3 -c "import flask" 2>/dev/null || {
        print_warning "安装Flask..."
        python3 -m pip install Flask
    }
    
    # 安装requests
    python3 -c "import requests" 2>/dev/null || {
        print_warning "安装requests..."
        python3 -m pip install requests
    }
    
    # 安装PyYAML
    python3 -c "import yaml" 2>/dev/null || {
        print_warning "安装PyYAML..."
        python3 -m pip install PyYAML
    }
    
    print_success "Python依赖安装完成"
}

# 创建应用目录
create_app_dirs() {
    print_step "5" "创建应用目录..."
    
    mkdir -p "$APP_DIR"
    mkdir -p "$APP_DIR/wangluo"
    mkdir -p "$APP_DIR/templates"
    
    print_success "应用目录创建完成"
}

# 复制应用文件
copy_app_files() {
    print_step "6" "复制应用文件..."
    
    cd "$APP_DIR"
    
    # 从GitHub下载应用文件
    GITHUB_RAW="https://raw.githubusercontent.com/kuku0799/OpenClashManage/main"
    
    # 下载主应用文件
    for file in app.py log.py jx.py zc.py zr.py zw.py; do
        if wget -q "$GITHUB_RAW/$file" -O "$file"; then
            print_success "$file 下载成功"
            chmod +x "$file"
        else
            print_error "$file 下载失败"
            exit 1
        fi
    done
    
    # 下载requirements.txt
    if wget -q "$GITHUB_RAW/requirements.txt" -O requirements.txt; then
        print_success "requirements.txt 下载成功"
    else
        print_error "requirements.txt 下载失败"
        exit 1
    fi
    
    # 下载templates目录
    mkdir -p templates
    if wget -q "$GITHUB_RAW/templates/index.html" -O templates/index.html; then
        print_success "templates/index.html 下载成功"
    else
        print_error "templates/index.html 下载失败"
        exit 1
    fi
    
    # 下载管理脚本
    if wget -q "$GITHUB_RAW/manage.sh" -O manage.sh; then
        print_success "manage.sh 下载成功"
        chmod +x manage.sh
    else
        print_error "manage.sh 下载失败"
        exit 1
    fi
    
    print_success "应用文件下载完成"
}

# 设置文件权限
set_permissions() {
    print_step "7" "设置文件权限..."
    
    chmod +x "$APP_DIR/app.py"
    chmod +x "$APP_DIR/manage.sh"
    chmod 666 "$APP_DIR/wangluo/log.txt" 2>/dev/null || touch "$APP_DIR/wangluo/log.txt" && chmod 666 "$APP_DIR/wangluo/log.txt"
    
    print_success "文件权限设置完成"
}

# 创建管理脚本
create_manage_script() {
    print_step "8" "创建管理脚本..."
    
    cat > "$APP_DIR/manage.sh" << 'EOF'
#!/bin/sh

# OpenClash管理面板 - 管理脚本
APP_DIR="/root/OpenClashManage"
LOG_FILE="$APP_DIR/wangluo/log.txt"

case "$1" in
    start)
        echo "启动OpenClash管理面板..."
        cd "$APP_DIR"
        nohup python3 app.py > "$LOG_FILE" 2>&1 &
        echo "应用已启动，PID: $!"
        echo "访问地址: http://192.168.5.1:8888"
        ;;
    stop)
        echo "停止OpenClash管理面板..."
        pkill -f "python3 app.py"
        echo "应用已停止"
        ;;
    restart)
        echo "重启OpenClash管理面板..."
        pkill -f "python3 app.py"
        sleep 2
        cd "$APP_DIR"
        nohup python3 app.py > "$LOG_FILE" 2>&1 &
        echo "应用已重启，PID: $!"
        echo "访问地址: http://192.168.5.1:8888"
        ;;
    status)
        if pgrep -f "python3 app.py" > /dev/null; then
            echo "✓ 应用正在运行"
            ps | grep "python3 app.py" | grep -v grep
            echo "访问地址: http://192.168.5.1:8888"
        else
            echo "✗ 应用未运行"
        fi
        ;;
    logs)
        if [ -f "$LOG_FILE" ]; then
            echo "=== 应用日志 ==="
            tail -20 "$LOG_FILE"
        else
            echo "日志文件不存在"
        fi
        ;;
    *)
        echo "用法: $0 {start|stop|restart|status|logs}"
        echo ""
        echo "命令说明:"
        echo "  start   - 启动应用"
        echo "  stop    - 停止应用"
        echo "  restart - 重启应用"
        echo "  status  - 查看状态"
        echo "  logs    - 查看日志"
        ;;
esac
EOF

    chmod +x "$APP_DIR/manage.sh"
    print_success "管理脚本创建完成"
}

# 创建系统服务
create_system_service() {
    print_step "9" "创建系统服务..."
    
    cat > "/etc/init.d/$SERVICE_NAME" << EOF
#!/bin/sh /etc/rc.common

START=99
STOP=15

start() {
    echo "启动OpenClash管理面板..."
    $APP_DIR/manage.sh start
}

stop() {
    echo "停止OpenClash管理面板..."
    $APP_DIR/manage.sh stop
}

restart() {
    echo "重启OpenClash管理面板..."
    $APP_DIR/manage.sh restart
}

status() {
    $APP_DIR/manage.sh status
}
EOF

    chmod +x "/etc/init.d/$SERVICE_NAME"
    print_success "系统服务创建完成"
}

# 启用开机自启动
enable_autostart() {
    print_step "10" "启用开机自启动..."
    
    /etc/init.d/$SERVICE_NAME enable
    print_success "开机自启动已启用"
}

# 启动应用
start_application() {
    print_step "11" "启动应用..."
    
    $APP_DIR/manage.sh start
    sleep 3
    
    # 检查应用是否启动成功
    if pgrep -f "python3 app.py" > /dev/null; then
        print_success "应用启动成功"
    else
        print_error "应用启动失败"
        return 1
    fi
}

# 测试应用
test_application() {
    print_step "12" "测试应用..."
    
    # 检查端口
    if command -v ss >/dev/null 2>&1; then
        if ss -tlnp 2>/dev/null | grep -q ":8888 "; then
            print_success "端口8888正在监听"
        else
            print_warning "端口8888未监听"
        fi
    elif command -v netstat >/dev/null 2>&1; then
        if netstat -tlnp 2>/dev/null | grep -q ":8888 "; then
            print_success "端口8888正在监听"
        else
            print_warning "端口8888未监听"
        fi
    else
        print_warning "无法检查端口状态"
    fi
    
    # 测试HTTP访问
    if command -v curl >/dev/null 2>&1; then
        if curl -s -o /dev/null -w "%{http_code}" "http://localhost:8888" | grep -q "200\|404"; then
            print_success "HTTP访问测试通过"
        else
            print_warning "HTTP访问测试失败"
        fi
    fi
}

# 显示安装结果
show_installation_result() {
    echo ""
    echo -e "${BLUE}=========================================="
    echo "    安装完成！"
    echo "=========================================="
    echo -e "${NC}"
    
    echo -e "${GREEN}✓ OpenClash管理面板安装成功${NC}"
    echo ""
    echo "📱 访问地址:"
    echo "  本地访问: http://localhost:8888"
    echo "  局域网访问: http://$ACCESS_IP:8888"
    echo ""
    echo "🔧 管理命令:"
    echo "  启动: /etc/init.d/$SERVICE_NAME start"
    echo "  停止: /etc/init.d/$SERVICE_NAME stop"
    echo "  重启: /etc/init.d/$SERVICE_NAME restart"
    echo "  状态: /etc/init.d/$SERVICE_NAME status"
    echo "  日志: $APP_DIR/manage.sh logs"
    echo ""
    echo "🔄 开机自启动: 已启用"
    echo "📁 安装目录: $APP_DIR"
    echo "📝 日志文件: $APP_DIR/wangluo/log.txt"
    echo ""
    echo -e "${YELLOW}💡 提示: 现在可以在浏览器中访问管理面板了！${NC}"
}

# 主安装函数
main_install() {
    print_header
    
    # 检查环境
    check_root
    check_architecture
    check_openwrt
    
    # 开始安装
    update_packages
    install_python3
    install_pip
    install_python_deps
    create_app_dirs
    copy_app_files
    set_permissions
    create_manage_script
    create_system_service
    enable_autostart
    start_application
    test_application
    
    # 显示结果
    show_installation_result
}

# 卸载函数
uninstall() {
    echo -e "${RED}正在卸载OpenClash管理面板...${NC}"
    
    # 停止服务
    /etc/init.d/$SERVICE_NAME stop 2>/dev/null
    
    # 禁用开机自启动
    /etc/init.d/$SERVICE_NAME disable 2>/dev/null
    
    # 删除服务文件
    rm -f "/etc/init.d/$SERVICE_NAME"
    
    # 删除应用目录
    rm -rf "$APP_DIR"
    
    echo -e "${GREEN}卸载完成！${NC}"
}

# 主函数
case "$1" in
    install)
        main_install
        ;;
    uninstall)
        uninstall
        ;;
    *)
        echo "OpenClash管理面板 - 一键安装脚本"
        echo ""
        echo "用法: $0 {install|uninstall}"
        echo ""
        echo "命令:"
        echo "  install   - 安装OpenClash管理面板"
        echo "  uninstall - 卸载OpenClash管理面板"
        echo ""
        echo "示例:"
        echo "  $0 install    # 安装应用"
        echo "  $0 uninstall  # 卸载应用"
        ;;
esac 