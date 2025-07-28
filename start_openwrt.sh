#!/bin/sh

# OpenClash管理面板启动脚本 - OpenWrt版本
# 作者: OpenClashManage
# 版本: 1.0

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 应用目录
APP_DIR="/root/OpenClashManage"
LOG_FILE="$APP_DIR/log.txt"
PID_FILE="$APP_DIR/app.pid"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 检查是否以root权限运行
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}错误: 此脚本需要root权限运行${NC}"
        exit 1
    fi
}

# 检查系统架构
check_architecture() {
    ARCH=$(uname -m)
    log "系统架构: $ARCH"
    
    if [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "x86_64" ]; then
        echo -e "${YELLOW}警告: 未测试的架构 $ARCH${NC}"
    fi
}

# 检查依赖
check_dependencies() {
    log "检查Python3..."
    if ! command -v python3 >/dev/null 2>&1; then
        echo -e "${RED}错误: Python3未安装${NC}"
        echo "请运行: opkg install python3"
        exit 1
    fi
    
    log "检查Python模块..."
    python3 -c "import flask" 2>/dev/null || {
        echo -e "${RED}错误: Flask未安装${NC}"
        echo "请运行: python3 -m pip install Flask"
        exit 1
    }
    
    python3 -c "import requests" 2>/dev/null || {
        echo -e "${RED}错误: Requests未安装${NC}"
        echo "请运行: python3 -m pip install requests"
        exit 1
    }
    
    python3 -c "import yaml" 2>/dev/null || {
        echo -e "${RED}错误: PyYAML未安装${NC}"
        echo "请运行: python3 -m pip install PyYAML"
        exit 1
    }
    
    echo -e "${GREEN}✓ 所有依赖检查通过${NC}"
}

# 检查文件
check_files() {
    log "检查应用文件..."
    
    if [ ! -f "$APP_DIR/app.py" ]; then
        echo -e "${RED}错误: app.py文件不存在${NC}"
        exit 1
    fi
    
    if [ ! -d "$APP_DIR/templates" ]; then
        echo -e "${RED}错误: templates目录不存在${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✓ 应用文件检查通过${NC}"
}

# 检查端口
check_port() {
    PORT=5000
    log "检查端口 $PORT..."
    
    if netstat -tlnp 2>/dev/null | grep -q ":$PORT "; then
        echo -e "${YELLOW}警告: 端口 $PORT 已被占用${NC}"
        netstat -tlnp | grep ":$PORT "
        echo -e "${YELLOW}尝试停止占用进程...${NC}"
        PID=$(netstat -tlnp 2>/dev/null | grep ":$PORT " | awk '{print $7}' | cut -d'/' -f1)
        if [ -n "$PID" ]; then
            kill -9 "$PID" 2>/dev/null
            sleep 2
        fi
    fi
}

# 启动应用
start_app() {
    log "启动OpenClash管理面板..."
    
    cd "$APP_DIR"
    
    # 使用nohup后台运行
    nohup python3 app.py > "$LOG_FILE" 2>&1 &
    APP_PID=$!
    
    # 保存PID
    echo $APP_PID > "$PID_FILE"
    
    # 等待应用启动
    sleep 3
    
    # 检查是否启动成功
    if kill -0 $APP_PID 2>/dev/null; then
        echo -e "${GREEN}✓ 应用启动成功 (PID: $APP_PID)${NC}"
        
        # 获取IP地址
        IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')
        if [ -n "$IP" ]; then
            echo -e "${BLUE}访问地址: http://$IP:5000${NC}"
        else
            echo -e "${BLUE}访问地址: http://localhost:5000${NC}"
        fi
        
        log "应用已启动，PID: $APP_PID"
    else
        echo -e "${RED}✗ 应用启动失败${NC}"
        log "应用启动失败"
        tail -10 "$LOG_FILE"
        exit 1
    fi
}

# 停止应用
stop_app() {
    log "停止应用..."
    
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 $PID 2>/dev/null; then
            kill $PID
            echo -e "${GREEN}✓ 应用已停止${NC}"
            log "应用已停止，PID: $PID"
        else
            echo -e "${YELLOW}应用未运行${NC}"
        fi
        rm -f "$PID_FILE"
    else
        echo -e "${YELLOW}未找到PID文件${NC}"
    fi
}

# 重启应用
restart_app() {
    log "重启应用..."
    stop_app
    sleep 2
    start_app
}

# 检查状态
check_status() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 $PID 2>/dev/null; then
            echo -e "${GREEN}✓ 应用正在运行 (PID: $PID)${NC}"
            
            # 检查端口
            if netstat -tlnp 2>/dev/null | grep -q ":5000 "; then
                echo -e "${GREEN}✓ 端口5000正在监听${NC}"
            else
                echo -e "${YELLOW}⚠ 端口5000未监听${NC}"
            fi
            
            # 显示访问地址
            IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')
            if [ -n "$IP" ]; then
                echo -e "${BLUE}访问地址: http://$IP:5000${NC}"
            else
                echo -e "${BLUE}访问地址: http://localhost:5000${NC}"
            fi
        else
            echo -e "${RED}✗ 应用未运行${NC}"
            rm -f "$PID_FILE"
        fi
    else
        echo -e "${YELLOW}应用未运行${NC}"
    fi
}

# 显示日志
show_logs() {
    if [ -f "$LOG_FILE" ]; then
        echo -e "${BLUE}=== 应用日志 (最后20行) ===${NC}"
        tail -20 "$LOG_FILE"
    else
        echo -e "${YELLOW}日志文件不存在${NC}"
    fi
}

# 主函数
main() {
    case "$1" in
        start)
            check_root
            check_architecture
            check_dependencies
            check_files
            check_port
            start_app
            ;;
        stop)
            check_root
            stop_app
            ;;
        restart)
            check_root
            restart_app
            ;;
        status)
            check_status
            ;;
        logs)
            show_logs
            ;;
        *)
            echo "用法: $0 {start|stop|restart|status|logs}"
            echo ""
            echo "命令说明:"
            echo "  start   - 启动应用"
            echo "  stop    - 停止应用"
            echo "  restart - 重启应用"
            echo "  status  - 检查状态"
            echo "  logs    - 显示日志"
            echo ""
            echo "示例:"
            echo "  $0 start    # 启动应用"
            echo "  $0 status   # 检查状态"
            echo "  $0 logs     # 查看日志"
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@" 