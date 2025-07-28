#!/bin/bash

# OpenClash管理面板一键修复脚本
# 修复节点同步问题并添加全方位监控

ROOT_DIR="/root/OpenClashManage"
LOG_FILE="$ROOT_DIR/wangluo/log.txt"

echo "🔧 OpenClash管理面板一键修复脚本"
echo "=================================="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为root用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用root用户运行此脚本"
        exit 1
    fi
    log_success "用户权限检查通过"
}

# 检查并安装依赖
install_dependencies() {
    log_info "检查并安装依赖..."
    
    # 检查Python3
    if ! command -v python3 &> /dev/null; then
        log_error "Python3未安装，请先安装Python3"
        exit 1
    fi
    log_success "Python3已安装"
    
    # 安装Python依赖
    log_info "安装Python依赖..."
    pip3 install ruamel.yaml requests 2>/dev/null || {
        log_warning "pip3安装失败，尝试使用opkg安装..."
        opkg update
        opkg install python3-yaml python3-requests 2>/dev/null || {
            log_error "无法安装Python依赖"
            exit 1
        }
    }
    log_success "Python依赖安装完成"
}

# 检查OpenClash安装
check_openclash() {
    log_info "检查OpenClash安装状态..."
    
    if ! opkg list-installed | grep -q openclash; then
        log_error "OpenClash未安装，请先安装OpenClash"
        log_info "安装命令: opkg install luci-app-openclash"
        exit 1
    fi
    log_success "OpenClash已安装"
    
    # 检查配置文件
    config_path=$(uci get openclash.config.config_path 2>/dev/null)
    if [ -z "$config_path" ]; then
        log_error "无法获取OpenClash配置文件路径"
        exit 1
    fi
    
    if [ ! -f "$config_path" ]; then
        log_error "OpenClash配置文件不存在: $config_path"
        exit 1
    fi
    log_success "OpenClash配置文件正常"
}

# 创建必要的目录和文件
create_directories() {
    log_info "创建必要的目录和文件..."
    
    # 创建目录
    mkdir -p "$ROOT_DIR/wangluo"
    mkdir -p "$ROOT_DIR/logs"
    
    # 创建节点文件（如果不存在）
    if [ ! -f "$ROOT_DIR/wangluo/nodes.txt" ]; then
        cat > "$ROOT_DIR/wangluo/nodes.txt" << 'EOF'
# 在此粘贴你的节点链接，一行一个，支持 ss:// vmess:// vless:// trojan://协议
# 示例:
# ss://YWVzLTI1Ni1nY206cGFzc3dvcmQ=@server:port#节点名称
# vmess://eyJhZGQiOiJzZXJ2ZXIiLCJwb3J0IjoiODA4MCIsImlkIjoiMTIzNDU2Nzg5MCIsIm5ldCI6IndzIiwidHlwZSI6Im5vbmUiLCJob3N0IjoiIiwicGF0aCI6IiIsInRscyI6IiJ9#节点名称

# 测试节点（可以删除这些测试节点）
ss://YWVzLTI1Ni1nY206cGFzc3dvcmQ=@192.168.1.100:8388#测试SS节点
vmess://eyJhZGQiOiIxOTIuMTY4LjEuMTAwIiwicG9ydCI6IjgwODAiLCJpZCI6IjEyMzQ1Njc4OTAiLCJuZXQiOiJ3cyIsInR5cGUiOiJub25lIiwiaG9zdCI6IiIsInBhdGgiOiIiLCJ0bHMiOiIifQ==#测试VMess节点
vless://12345678-1234-1234-1234-123456789012@192.168.1.100:443?security=tls&type=ws#测试VLESS节点
trojan://password@192.168.1.100:443#测试Trojan节点
EOF
        log_success "节点文件已创建"
    fi
    
    # 创建日志文件（如果不存在）
    touch "$ROOT_DIR/wangluo/log.txt"
    log_success "日志文件已创建"
}

# 设置脚本权限
set_permissions() {
    log_info "设置脚本权限..."
    
    chmod +x "$ROOT_DIR/zr.py"
    chmod +x "$ROOT_DIR/jx.py"
    chmod +x "$ROOT_DIR/zw.py"
    chmod +x "$ROOT_DIR/zc.py"
    chmod +x "$ROOT_DIR/jk.sh"
    chmod +x "$ROOT_DIR/test_sync.py"
    chmod +x "$ROOT_DIR/monitor_sync.py"
    chmod +x "$ROOT_DIR/start_monitor.sh"
    
    log_success "脚本权限设置完成"
}

# 测试修复效果
test_fixes() {
    log_info "测试修复效果..."
    
    cd "$ROOT_DIR"
    
    # 运行测试脚本
    if python3 test_sync.py; then
        log_success "测试通过，修复成功"
        return 0
    else
        log_warning "部分测试失败，但核心功能可能正常"
        return 1
    fi
}

# 启动监控
start_monitoring() {
    log_info "启动实时监控..."
    
    cd "$ROOT_DIR"
    
    # 后台启动监控
    nohup python3 monitor_sync.py > "$ROOT_DIR/logs/monitor.log" 2>&1 &
    MONITOR_PID=$!
    echo $MONITOR_PID > "$ROOT_DIR/logs/monitor.pid"
    
    log_success "监控已启动 (PID: $MONITOR_PID)"
    log_info "监控日志: $ROOT_DIR/logs/monitor.log"
}

# 启动守护进程
start_watchdog() {
    log_info "启动守护进程..."
    
    cd "$ROOT_DIR"
    
    # 检查是否已有守护进程运行
    if [ -f "/tmp/openclash_watchdog.pid" ]; then
        PID=$(cat /tmp/openclash_watchdog.pid)
        if kill -0 $PID 2>/dev/null; then
            log_warning "守护进程已在运行 (PID: $PID)"
            return 0
        fi
    fi
    
    # 启动守护进程
    nohup bash jk.sh > "$ROOT_DIR/logs/watchdog.log" 2>&1 &
    WATCHDOG_PID=$!
    
    log_success "守护进程已启动 (PID: $WATCHDOG_PID)"
    log_info "守护进程日志: $ROOT_DIR/logs/watchdog.log"
}

# 显示使用说明
show_usage() {
    echo ""
    echo "🎉 修复完成！"
    echo "=================="
    echo ""
    echo "📋 可用命令:"
    echo "1. 查看监控: tail -f $ROOT_DIR/logs/monitor.log"
    echo "2. 查看守护进程: tail -f $ROOT_DIR/logs/watchdog.log"
    echo "3. 查看同步日志: tail -f $ROOT_DIR/wangluo/log.txt"
    echo "4. 手动同步: cd $ROOT_DIR && python3 zr.py"
    echo "5. 运行测试: cd $ROOT_DIR && python3 test_sync.py"
    echo "6. 启动监控: cd $ROOT_DIR && python3 monitor_sync.py"
    echo "7. 使用菜单: cd $ROOT_DIR && bash start_monitor.sh"
    echo ""
    echo "🔧 故障排除:"
    echo "- 如果节点无法同步，请检查OpenClash配置"
    echo "- 如果守护进程未运行，请手动启动: bash $ROOT_DIR/jk.sh"
    echo "- 查看详细错误: cat $ROOT_DIR/wangluo/log.txt"
    echo ""
    echo "📊 监控功能:"
    echo "- 实时监控节点文件变化"
    echo "- 监控同步进程状态"
    echo "- 监控OpenClash服务状态"
    echo "- 详细的错误日志记录"
    echo ""
}

# 主函数
main() {
    echo "🚀 开始一键修复..."
    echo ""
    
    # 检查root权限
    check_root
    
    # 安装依赖
    install_dependencies
    
    # 检查OpenClash
    check_openclash
    
    # 创建目录和文件
    create_directories
    
    # 设置权限
    set_permissions
    
    # 测试修复效果
    test_fixes
    
    # 启动监控
    start_monitoring
    
    # 启动守护进程
    start_watchdog
    
    # 显示使用说明
    show_usage
    
    log_success "一键修复完成！"
}

# 运行主函数
main "$@" 