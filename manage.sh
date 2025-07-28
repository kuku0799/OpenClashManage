#!/bin/sh

# OpenClash管理面板 - 简单管理脚本
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