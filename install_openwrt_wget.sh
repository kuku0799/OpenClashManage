#!/bin/bash

# OpenClash 管理面板 - OpenWrt 专用安装脚本 (wget版本)
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
        print_message "请使用: bash install_openwrt_wget.sh"
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

# 检查存储空间
check_storage() {
    print_step "检查存储空间..."
    
    # 检查overlay文件系统空间
    OVERLAY_AVAILABLE=$(df /overlay | awk 'NR==2 {print $4}')
    OVERLAY_AVAILABLE_KB=$((OVERLAY_AVAILABLE * 1024))
    
    print_message "可用空间: ${OVERLAY_AVAILABLE_KB}KB"
    
    # 需要的最小空间 (约5MB)
    MIN_SPACE=5120
    
    if [[ $OVERLAY_AVAILABLE_KB -lt $MIN_SPACE ]]; then
        print_warning "⚠️  存储空间不足，需要至少 ${MIN_SPACE}KB 可用空间"
        print_message "当前可用: ${OVERLAY_AVAILABLE_KB}KB"
        
        # 提供清理建议
        print_step "尝试清理存储空间..."
        cleanup_storage
        
        # 再次检查空间
        OVERLAY_AVAILABLE=$(df /overlay | awk 'NR==2 {print $4}')
        OVERLAY_AVAILABLE_KB=$((OVERLAY_AVAILABLE * 1024))
        
        if [[ $OVERLAY_AVAILABLE_KB -lt $MIN_SPACE ]]; then
            print_error "❌ 清理后空间仍然不足"
            print_message "请手动清理空间或考虑以下方案："
            echo "   1. 删除不需要的软件包: opkg remove <package_name>"
            echo "   2. 清理opkg缓存: opkg clean"
            echo "   3. 重启系统释放临时文件"
            echo "   4. 考虑使用外部存储"
            exit 1
        fi
    fi
    
    print_message "✅ 存储空间充足"
}

# 清理存储空间
cleanup_storage() {
    print_message "执行存储空间清理..."
    
    # 清理opkg缓存
    opkg clean 2>/dev/null || true
    
    # 清理临时文件
    rm -rf /tmp/* 2>/dev/null || true
    rm -rf /var/tmp/* 2>/dev/null || true
    
    # 清理日志文件
    find /var/log -name "*.log" -size +1M -delete 2>/dev/null || true
    
    # 清理下载缓存
    rm -rf /var/opkg-lists/*.gz 2>/dev/null || true
    
    print_message "✅ 存储空间清理完成"
}

# 安装OpenWrt依赖 (优化版)
install_openwrt_deps() {
    print_step "安装OpenWrt依赖..."
    
    # 更新软件包列表
    print_message "更新软件包列表..."
    opkg update
    
    # 检查并安装最小化的Python环境
    print_message "安装Python环境..."
    
    # 先尝试安装python3-light (更小)
    if ! opkg list-installed | grep -q "python3-light"; then
        print_message "安装 python3-light..."
        opkg install python3-light
    fi
    
    # 安装必要的Python模块
    if ! opkg list-installed | grep -q "python3-yaml"; then
        print_message "安装 python3-yaml..."
        opkg install python3-yaml
    fi
    
    # 检查wget是否已安装
    if ! opkg list-installed | grep -q "wget"; then
        print_message "安装 wget..."
        opkg install wget
    fi
    
    # 尝试安装pip (如果空间允许)
    if ! opkg list-installed | grep -q "python3-pip"; then
        print_message "尝试安装 python3-pip..."
        if opkg install python3-pip 2>/dev/null; then
            print_message "✅ python3-pip 安装成功"
        else
            print_warning "⚠️  python3-pip 安装失败，将使用替代方案"
        fi
    fi
    
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

# 下载项目文件 (使用wget)
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
            wget -q --no-check-certificate "$GITHUB_REPO/$file" -O "$PROJECT_DIR/$file"
        else
            wget -q --no-check-certificate "$GITHUB_REPO/$file" -O "$PROJECT_DIR/$file"
        fi
        
        if [[ $? -eq 0 ]]; then
            print_message "✓ $file 下载成功"
        else
            print_error "✗ $file 下载失败"
            exit 1
        fi
    done
}

# 安装Python依赖 (优化版)
install_python_deps() {
    print_step "安装Python依赖..."
    
    cd /root/OpenClashManage
    
    # 检查pip是否可用
    if command -v pip3 >/dev/null 2>&1; then
        print_message "使用pip3安装依赖..."
        pip3 install Flask==2.3.3 ruamel.yaml==0.18.5
        
        if [[ $? -eq 0 ]]; then
            print_message "✓ Python依赖安装成功"
        else
            print_warning "⚠️  pip安装失败，尝试替代方案"
            install_python_deps_alternative
        fi
    else
        print_warning "⚠️  pip3不可用，使用替代方案"
        install_python_deps_alternative
    fi
}

# 替代的Python依赖安装方法
install_python_deps_alternative() {
    print_message "使用opkg安装Python依赖..."
    
    # 尝试通过opkg安装Flask
    if opkg list-installed | grep -q "python3-flask"; then
        print_message "✅ Flask已安装"
    else
        print_message "尝试安装python3-flask..."
        if opkg install python3-flask 2>/dev/null; then
            print_message "✅ Flask安装成功"
        else
            print_warning "⚠️  Flask安装失败，将使用内置模块"
        fi
    fi
    
    # 检查yaml模块
    if opkg list-installed | grep -q "python3-yaml"; then
        print_message "✅ YAML模块已安装"
    else
        print_warning "⚠️  YAML模块未安装，某些功能可能受限"
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
    echo "   http://$(uci get network.lan.ipaddr 2>/dev/null || echo "192.168.1.1"):8888"
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
    check_storage
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