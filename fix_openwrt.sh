#!/bin/bash

# OpenWrt OpenClash管理工具故障排除脚本

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置
APP_DIR="/root/OpenClashManage"
LOG_FILE="$APP_DIR/wangluo/log.txt"

# 日志函数
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# 检查系统信息
check_system() {
    log "=== 系统信息 ==="
    echo "系统版本: $(cat /etc/openwrt_release 2>/dev/null || echo '未知')"
    echo "内核版本: $(uname -r)"
    echo "架构: $(uname -m)"
    echo "内存: $(free -h | grep Mem | awk '{print $2}')"
    echo "磁盘: $(df -h / | tail -1 | awk '{print $4}') 可用"
    echo
}

# 检查网络连接
check_network() {
    log "=== 网络连接检查 ==="
    
    # 检查网络接口
    echo "网络接口:"
    ip addr show | grep -E "inet.*scope global" | awk '{print "  " $2}'
    echo
    
    # 检查DNS
    echo "DNS解析测试:"
    if nslookup google.com >/dev/null 2>&1; then
        echo "  ✅ DNS解析正常"
    else
        echo "  ❌ DNS解析失败"
    fi
    echo
    
    # 检查外网连接
    echo "外网连接测试:"
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo "  ✅ 外网连接正常"
    else
        echo "  ❌ 外网连接失败"
    fi
    echo
}

# 检查Python环境
check_python() {
    log "=== Python环境检查 ==="
    
    # 检查Python版本
    if command -v python3 >/dev/null 2>&1; then
        echo "Python版本: $(python3 --version)"
    else
        error "未找到python3"
        return 1
    fi
    
    # 检查pip
    if command -v pip3 >/dev/null 2>&1; then
        echo "pip版本: $(pip3 --version)"
    else
        warn "未找到pip3"
    fi
    
    # 检查已安装的包
    echo "已安装的Python包:"
    python3 -m pip list 2>/dev/null | grep -E "(Flask|requests|yaml)" || echo "  未找到相关包"
    echo
}

# 检查依赖包
check_dependencies() {
    log "=== 依赖包检查 ==="
    
    # 检查系统包
    echo "系统包检查:"
    for pkg in python3 python3-pip python3-requests python3-yaml; do
        if opkg list-installed | grep -q "^$pkg"; then
            echo "  ✅ $pkg 已安装"
        else
            echo "  ❌ $pkg 未安装"
        fi
    done
    echo
    
    # 检查Python包
    echo "Python包检查:"
    for pkg in flask requests yaml; do
        if python3 -c "import $pkg" 2>/dev/null; then
            echo "  ✅ $pkg 已安装"
        else
            echo "  ❌ $pkg 未安装"
        fi
    done
    echo
}

# 检查应用文件
check_files() {
    log "=== 应用文件检查 ==="
    
    # 检查目录
    if [ -d "$APP_DIR" ]; then
        echo "✅ 应用目录存在: $APP_DIR"
    else
        error "❌ 应用目录不存在: $APP_DIR"
        return 1
    fi
    
    # 检查关键文件
    for file in app.py log.py jk.sh templates/index.html; do
        if [ -f "$APP_DIR/$file" ]; then
            echo "  ✅ $file 存在"
        else
            echo "  ❌ $file 不存在"
        fi
    done
    
    # 检查权限
    echo "文件权限检查:"
    if [ -x "$APP_DIR/app.py" ]; then
        echo "  ✅ app.py 可执行"
    else
        echo "  ❌ app.py 不可执行"
    fi
    
    if [ -x "$APP_DIR/jk.sh" ]; then
        echo "  ✅ jk.sh 可执行"
    else
        echo "  ❌ jk.sh 不可执行"
    fi
    echo
}

# 检查端口占用
check_ports() {
    log "=== 端口检查 ==="
    
    # 检查5000端口
    if netstat -tlnp 2>/dev/null | grep -q ":5000"; then
        echo "❌ 端口5000已被占用:"
        netstat -tlnp 2>/dev/null | grep ":5000"
    else
        echo "✅ 端口5000可用"
    fi
    
    # 检查5001端口
    if netstat -tlnp 2>/dev/null | grep -q ":5001"; then
        echo "❌ 端口5001已被占用:"
        netstat -tlnp 2>/dev/null | grep ":5001"
    else
        echo "✅ 端口5001可用"
    fi
    echo
}

# 检查进程
check_processes() {
    log "=== 进程检查 ==="
    
    # 检查Python进程
    if pgrep -f "python3.*app.py" >/dev/null; then
        echo "✅ 发现Python应用进程:"
        ps aux | grep "python3.*app.py" | grep -v grep
    else
        echo "❌ 未发现Python应用进程"
    fi
    
    # 检查守护进程
    if pgrep -f "jk.sh" >/dev/null; then
        echo "✅ 发现守护进程:"
        ps aux | grep "jk.sh" | grep -v grep
    else
        echo "❌ 未发现守护进程"
    fi
    echo
}

# 检查日志
check_logs() {
    log "=== 日志检查 ==="
    
    if [ -f "$LOG_FILE" ]; then
        echo "应用日志 (最后10行):"
        tail -10 "$LOG_FILE" 2>/dev/null || echo "  无法读取日志文件"
    else
        echo "❌ 日志文件不存在: $LOG_FILE"
    fi
    
    # 检查系统日志
    echo "系统日志 (最后5行):"
    tail -5 /var/log/messages 2>/dev/null || echo "  无法读取系统日志"
    echo
}

# 修复常见问题
fix_common_issues() {
    log "=== 修复常见问题 ==="
    
    # 修复Python包
    echo "修复Python包..."
    python3 -m pip install --upgrade pip 2>/dev/null
    python3 -m pip install Flask==2.3.3 requests PyYAML 2>/dev/null
    
    # 修复文件权限
    echo "修复文件权限..."
    chmod +x "$APP_DIR"/*.py 2>/dev/null
    chmod +x "$APP_DIR"/*.sh 2>/dev/null
    chmod 666 "$APP_DIR/wangluo/"*.txt 2>/dev/null
    
    # 创建缺失的目录
    echo "创建缺失目录..."
    mkdir -p "$APP_DIR/wangluo" 2>/dev/null
    mkdir -p "$APP_DIR/templates" 2>/dev/null
    
    # 创建缺失的文件
    echo "创建缺失文件..."
    touch "$APP_DIR/wangluo/nodes.txt" 2>/dev/null
    touch "$APP_DIR/wangluo/log.txt" 2>/dev/null
    
    echo "修复完成"
    echo
}

# 测试应用启动
test_startup() {
    log "=== 测试应用启动 ==="
    
    # 停止现有进程
    pkill -f "python3.*app.py" 2>/dev/null
    pkill -f "jk.sh" 2>/dev/null
    
    # 测试启动
    cd "$APP_DIR"
    timeout 10s python3 app.py &
    TEST_PID=$!
    
    sleep 3
    
    if kill -0 $TEST_PID 2>/dev/null; then
        echo "✅ 应用启动测试成功"
        kill $TEST_PID 2>/dev/null
    else
        echo "❌ 应用启动测试失败"
    fi
    echo
}

# 显示修复建议
show_recommendations() {
    log "=== 修复建议 ==="
    
    echo "如果遇到问题，请尝试以下步骤："
    echo
    echo "1. 更新软件包:"
    echo "   opkg update"
    echo
    echo "2. 安装基础依赖:"
    echo "   opkg install python3 python3-pip python3-requests python3-yaml"
    echo
    echo "3. 安装Python包:"
    echo "   python3 -m pip install Flask requests PyYAML"
    echo
    echo "4. 重新安装应用:"
    echo "   bash install_openwrt.sh"
    echo
    echo "5. 手动启动测试:"
    echo "   cd /root/OpenClashManage && python3 app.py"
    echo
    echo "6. 查看详细日志:"
    echo "   tail -f /root/OpenClashManage/wangluo/log.txt"
    echo
}

# 主函数
main() {
    echo "OpenWrt OpenClash管理工具故障排除脚本"
    echo "======================================"
    echo
    
    check_system
    check_network
    check_python
    check_dependencies
    check_files
    check_ports
    check_processes
    check_logs
    
    if [ "$1" = "fix" ]; then
        fix_common_issues
        test_startup
    fi
    
    show_recommendations
}

# 运行主函数
main "$@" 