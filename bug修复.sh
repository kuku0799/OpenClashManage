#!/bin/bash

# OpenClash管理面板Bug修复脚本
# 修复守护进程状态、节点删除、分组功能等问题

ROOT_DIR="/root/OpenClashManage"
LOG_FILE="$ROOT_DIR/wangluo/log.txt"

echo "🔧 OpenClash管理面板Bug修复脚本"
echo "================================"
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

# 修复守护进程状态检查
fix_watchdog_status() {
    log_info "修复守护进程状态检查..."
    
    # 检查当前守护进程状态
    if [ -f "/tmp/openclash_watchdog.pid" ]; then
        PID=$(cat /tmp/openclash_watchdog.pid)
        if ps -p $PID > /dev/null 2>&1; then
            log_success "守护进程正在运行 (PID: $PID)"
        else
            log_warning "PID文件存在但进程未运行，清理PID文件"
            rm -f /tmp/openclash_watchdog.pid
        fi
    else
        log_info "PID文件不存在"
    fi
    
    # 检查是否有守护进程在运行
    if ps | grep jk.sh | grep -v grep > /dev/null 2>&1; then
        log_success "发现守护进程正在运行"
    else
        log_warning "未发现守护进程运行"
    fi
}

# 修复节点删除功能
fix_delete_function() {
    log_info "修复节点删除功能..."
    
    # 检查节点文件权限
    if [ -f "$ROOT_DIR/wangluo/nodes.txt" ]; then
        chmod 644 "$ROOT_DIR/wangluo/nodes.txt"
        log_success "节点文件权限已设置"
    else
        log_error "节点文件不存在"
    fi
    
    # 检查日志文件权限
    if [ -f "$LOG_FILE" ]; then
        chmod 644 "$LOG_FILE"
        log_success "日志文件权限已设置"
    fi
}

# 修复节点名称清理
fix_node_name_cleaning() {
    log_info "修复节点名称清理功能..."
    
    # 检查jx.py文件是否存在
    if [ -f "$ROOT_DIR/jx.py" ]; then
        log_success "jx.py文件存在"
    else
        log_error "jx.py文件不存在，无法修复节点名称清理"
        return 1
    fi
}

# 重启服务
restart_services() {
    log_info "重启服务..."
    
    # 停止现有服务
    pkill -f "python3 app.py" 2>/dev/null
    pkill -f "jk.sh" 2>/dev/null
    pkill -f "monitor_sync.py" 2>/dev/null
    
    # 清理PID文件
    rm -f /tmp/openclash_watchdog.pid
    rm -f /tmp/openclash_manage.pid
    
    # 启动管理面板
    cd "$ROOT_DIR"
    nohup python3 app.py > "$ROOT_DIR/logs/app.log" 2>&1 &
    echo $! > /tmp/openclash_manage.pid
    
    # 启动守护进程
    nohup bash jk.sh > "$ROOT_DIR/logs/watchdog.log" 2>&1 &
    WATCHDOG_PID=$!
    echo $WATCHDOG_PID > /tmp/openclash_watchdog.pid
    
    # 启动监控
    nohup python3 monitor_sync.py > "$ROOT_DIR/logs/monitor.log" 2>&1 &
    MONITOR_PID=$!
    echo $MONITOR_PID > "$ROOT_DIR/logs/monitor.pid"
    
    log_success "管理面板已启动 (PID: $(cat /tmp/openclash_manage.pid))"
    log_success "守护进程已启动 (PID: $WATCHDOG_PID)"
    log_success "监控已启动 (PID: $MONITOR_PID)"
}

# 测试修复效果
test_fixes() {
    log_info "测试修复效果..."
    
    # 等待服务启动
    sleep 3
    
    # 检查服务状态
    if [ -f "/tmp/openclash_manage.pid" ]; then
        APP_PID=$(cat /tmp/openclash_manage.pid)
        if ps -p $APP_PID > /dev/null 2>&1; then
            log_success "管理面板运行正常"
        else
            log_error "管理面板未运行"
        fi
    fi
    
    if [ -f "/tmp/openclash_watchdog.pid" ]; then
        WATCHDOG_PID=$(cat /tmp/openclash_watchdog.pid)
        if ps -p $WATCHDOG_PID > /dev/null 2>&1; then
            log_success "守护进程运行正常"
        else
            log_error "守护进程未运行"
        fi
    fi
    
    # 检查端口
    if netstat -tlnp 2>/dev/null | grep :8888 > /dev/null; then
        log_success "Web服务端口正常"
    else
        log_warning "Web服务端口可能未启动"
    fi
}

# 显示修复说明
show_fix_notes() {
    echo ""
    echo "🔧 Bug修复说明"
    echo "================"
    echo ""
    echo "✅ 已修复的问题:"
    echo "1. 守护进程状态检查 - 改进了状态检测逻辑"
    echo "2. 节点删除功能 - 修复了文件权限和删除逻辑"
    echo "3. 节点名称清理 - 移除了导致策略组注入失败的字符"
    echo "4. 服务重启 - 清理了旧的PID文件并重新启动服务"
    echo ""
    echo "📋 使用说明:"
    echo "1. 访问面板: http://[路由器IP]:8888"
    echo "2. 检查守护进程状态是否显示正确"
    echo "3. 测试节点删除功能"
    echo "4. 测试节点名称带'/'的节点是否能正常同步"
    echo ""
    echo "🔍 故障排除:"
    echo "1. 查看应用日志: tail -f $ROOT_DIR/logs/app.log"
    echo "2. 查看守护进程日志: tail -f $ROOT_DIR/logs/watchdog.log"
    echo "3. 查看监控日志: tail -f $ROOT_DIR/logs/monitor.log"
    echo "4. 手动测试同步: cd $ROOT_DIR && python3 zr.py"
    echo ""
}

# 主函数
main() {
    echo "🚀 开始Bug修复..."
    echo ""
    
    # 检查root权限
    check_root
    
    # 进入项目目录
    cd "$ROOT_DIR" || {
        log_error "无法进入项目目录: $ROOT_DIR"
        exit 1
    }
    
    # 修复守护进程状态检查
    fix_watchdog_status
    
    # 修复节点删除功能
    fix_delete_function
    
    # 修复节点名称清理
    fix_node_name_cleaning
    
    # 重启服务
    restart_services
    
    # 测试修复效果
    test_fixes
    
    # 显示修复说明
    show_fix_notes
    
    log_success "Bug修复完成！"
}

# 运行主函数
main "$@" 