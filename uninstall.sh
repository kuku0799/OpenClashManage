#!/bin/bash

# OpenClashManage 卸载脚本
# 用于完全移除OpenClashManage服务

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印函数
print_message() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# 检测系统类型
detect_system() {
    if [[ -f /etc/openwrt_release ]]; then
        SYSTEM_TYPE="openwrt"
    elif [[ -f /etc/debian_version ]]; then
        SYSTEM_TYPE="debian"
    elif [[ -f /etc/redhat-release ]]; then
        SYSTEM_TYPE="centos"
    else
        SYSTEM_TYPE="generic"
    fi
    print_info "检测到系统类型: $SYSTEM_TYPE"
}

# 停止服务
stop_service() {
    print_info "正在停止OpenClashManage服务..."
    
    case $SYSTEM_TYPE in
        "openwrt")
            if [[ -f /etc/init.d/openclash-manage ]]; then
                /etc/init.d/openclash-manage stop 2>/dev/null || true
                print_message "已停止OpenClashManage服务"
            fi
            ;;
        *)
            if systemctl is-active --quiet openclash-manage 2>/dev/null; then
                systemctl stop openclash-manage
                print_message "已停止OpenClashManage服务"
            fi
            ;;
    esac
}

# 禁用服务
disable_service() {
    print_info "正在禁用OpenClashManage服务..."
    
    case $SYSTEM_TYPE in
        "openwrt")
            if [[ -f /etc/init.d/openclash-manage ]]; then
                /etc/init.d/openclash-manage disable 2>/dev/null || true
                print_message "已禁用OpenClashManage服务"
            fi
            ;;
        *)
            if systemctl is-enabled --quiet openclash-manage 2>/dev/null; then
                systemctl disable openclash-manage
                print_message "已禁用OpenClashManage服务"
            fi
            ;;
    esac
}

# 删除服务文件
remove_service_files() {
    print_info "正在删除服务文件..."
    
    case $SYSTEM_TYPE in
        "openwrt")
            if [[ -f /etc/init.d/openclash-manage ]]; then
                rm -f /etc/init.d/openclash-manage
                print_message "已删除OpenWrt服务文件"
            fi
            ;;
        *)
            if [[ -f /etc/systemd/system/openclash-manage.service ]]; then
                rm -f /etc/systemd/system/openclash-manage.service
                systemctl daemon-reload
                print_message "已删除systemd服务文件"
            fi
            ;;
    esac
}

# 删除应用文件
remove_app_files() {
    print_info "正在删除应用文件..."
    
    # 删除应用目录
    if [[ -d /opt/openclash-manage ]]; then
        rm -rf /opt/openclash-manage
        print_message "已删除应用目录 /opt/openclash-manage"
    fi
    
    # 删除其他可能的安装位置
    if [[ -d /usr/local/openclash-manage ]]; then
        rm -rf /usr/local/openclash-manage
        print_message "已删除应用目录 /usr/local/openclash-manage"
    fi
    
    if [[ -d /root/openclash-manage ]]; then
        rm -rf /root/openclash-manage
        print_message "已删除应用目录 /root/openclash-manage"
    fi
}

# 删除日志文件
remove_log_files() {
    print_info "正在删除日志文件..."
    
    if [[ -f /var/log/openclash-manage.log ]]; then
        rm -f /var/log/openclash-manage.log
        print_message "已删除日志文件 /var/log/openclash-manage.log"
    fi
    
    if [[ -f /tmp/openclash-manage.log ]]; then
        rm -f /tmp/openclash-manage.log
        print_message "已删除日志文件 /tmp/openclash-manage.log"
    fi
}

# 删除配置文件
remove_config_files() {
    print_info "正在删除配置文件..."
    
    if [[ -d /etc/openclash-manage ]]; then
        rm -rf /etc/openclash-manage
        print_message "已删除配置目录 /etc/openclash-manage"
    fi
}

# 清理进程
cleanup_processes() {
    print_info "正在清理残留进程..."
    
    # 查找并杀死相关进程
    pids=$(ps aux | grep -E "(openclash-manage|app.py)" | grep -v grep | awk '{print $2}' 2>/dev/null || true)
    
    if [[ -n "$pids" ]]; then
        echo "$pids" | xargs kill -9 2>/dev/null || true
        print_message "已清理残留进程"
    else
        print_info "未发现残留进程"
    fi
}

# 清理端口占用
cleanup_ports() {
    print_info "正在检查端口占用..."
    
    # 检查8888端口
    if netstat -tlnp 2>/dev/null | grep -q ":8888 "; then
        print_warning "端口8888仍被占用，可能需要手动清理"
    fi
    
    # 检查8080端口
    if netstat -tlnp 2>/dev/null | grep -q ":8080 "; then
        print_warning "端口8080仍被占用，可能需要手动清理"
    fi
}

# 清理Python缓存
cleanup_python_cache() {
    print_info "正在清理Python缓存..."
    
    find /opt -name "*.pyc" -delete 2>/dev/null || true
    find /usr/local -name "*.pyc" -delete 2>/dev/null || true
    find /root -name "*.pyc" -delete 2>/dev/null || true
    
    find /opt -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
    find /usr/local -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
    find /root -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
    
    print_message "已清理Python缓存文件"
}

# 显示卸载结果
show_uninstall_result() {
    echo
    print_message "=== OpenClashManage 卸载完成 ==="
    echo
    print_info "已清理的内容："
    echo "  ✅ 服务文件"
    echo "  ✅ 应用文件"
    echo "  ✅ 日志文件"
    echo "  ✅ 配置文件"
    echo "  ✅ 残留进程"
    echo "  ✅ Python缓存"
    echo
    print_warning "注意事项："
    echo "  ⚠️  如果端口仍被占用，请手动检查"
    echo "  ⚠️  如需重新安装，请运行安装脚本"
    echo
    print_info "重新安装命令："
    echo "  wget -qO- https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/install_wget.sh | bash"
    echo
}

# 主函数
main() {
    echo
    print_info "=== OpenClashManage 卸载脚本 ==="
    echo
    
    # 检测系统类型
    detect_system
    
    # 确认卸载
    echo
    print_warning "此操作将完全移除OpenClashManage服务"
    read -p "确认卸载？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "取消卸载"
        exit 0
    fi
    
    echo
    print_info "开始卸载..."
    
    # 执行卸载步骤
    stop_service
    disable_service
    remove_service_files
    remove_app_files
    remove_log_files
    remove_config_files
    cleanup_processes
    cleanup_ports
    cleanup_python_cache
    
    # 显示结果
    show_uninstall_result
}

# 执行主函数
main "$@" 