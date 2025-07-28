#!/bin/sh

# OpenClash管理面板 - 快速安装脚本
# 适用于OpenWrt系统

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 配置
APP_DIR="/root/OpenClashManage"
LOG_FILE="$APP_DIR/install.log"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

print_header() {
    echo -e "${BLUE}"
    echo "=========================================="
    echo "    OpenClash管理面板 - 快速安装"
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

# 安装Python3
install_python3() {
    print_step "1" "安装Python3..."
    
    if command -v python3 >/dev/null 2>&1; then
        print_success "Python3已安装"
        python3 --version
    else
        print_warning "正在安装Python3..."
        opkg update
        opkg install python3
        if [ $? -eq 0 ]; then
            print_success "Python3安装成功"
        else
            print_error "Python3安装失败"
            exit 1
        fi
    fi
}

# 安装Python依赖
install_python_deps() {
    print_step "2" "安装Python依赖..."
    
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
    print_step "3" "创建应用目录..."
    
    mkdir -p "$APP_DIR"
    mkdir -p "$APP_DIR/wangluo"
    mkdir -p "$APP_DIR/templates"
    
    print_success "应用目录创建完成"
}

# 创建应用文件
create_app_files() {
    print_step "4" "创建应用文件..."
    
    cd "$APP_DIR"
    
    # 创建app.py
    cat > app.py << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from flask import Flask, render_template, request, jsonify
import os
from datetime import datetime

app = Flask(__name__)
app.secret_key = 'openclash_manage_secret_key_2024'

# 配置路径
ROOT_DIR = "/root/OpenClashManage"
NODES_FILE = f"{ROOT_DIR}/wangluo/nodes.txt"
LOG_FILE = f"{ROOT_DIR}/wangluo/log.txt"

def write_log(msg: str):
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"{now} {msg}"
    print(line)
    try:
        os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
        with open(LOG_FILE, "a", encoding="utf-8") as f:
            f.write(line + "\n")
    except Exception as e:
        print(f"Failed to write log: {e}")

@app.route('/')
def index():
    return "OpenClash管理面板 - 快速安装版本已启动！"

@app.route('/api/status')
def status():
    return jsonify({'status': 'running', 'message': '应用正常运行'})

if __name__ == '__main__':
    write_log("🚀 OpenClash管理面板启动")
    app.run(host='0.0.0.0', port=8888, debug=False)
EOF

    # 创建log.py
    cat > log.py << 'EOF'
from datetime import datetime
import os

DEFAULT_LOG_FILE = "/root/OpenClashManage/wangluo/log.txt"
ENABLE_CONSOLE_OUTPUT = True

def write_log(msg: str, log_path: str = DEFAULT_LOG_FILE):
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    line = f"{now} {msg}"
    if ENABLE_CONSOLE_OUTPUT:
        print(line)
    try:
        os.makedirs(os.path.dirname(log_path), exist_ok=True)
        with open(log_path, "a", encoding="utf-8") as f:
            f.write(line + "\n")
    except Exception as e:
        if ENABLE_CONSOLE_OUTPUT:
            print(f"[log.py] Failed to write log: {e}")
EOF

    # 创建其他文件
    for file in jx.py zc.py zr.py zw.py; do
        cat > "$file" << 'EOF'
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
print("快速安装版本 - 功能待完善")
EOF
        chmod +x "$file"
    done

    # 创建requirements.txt
    cat > requirements.txt << 'EOF'
Flask==2.3.3
requests==2.31.0
ruamel.yaml==0.18.5
EOF

    # 创建templates/index.html
    mkdir -p templates
    cat > templates/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>OpenClash管理面板</title>
    <meta charset="utf-8">
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .header { background: #007bff; color: white; padding: 20px; border-radius: 5px; }
        .content { margin-top: 20px; }
        .status { background: #d4edda; border: 1px solid #c3e6cb; padding: 15px; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>OpenClash管理面板</h1>
            <p>快速安装版本已启动！</p>
        </div>
        <div class="content">
            <div class="status">
                <h3>✅ 安装成功</h3>
                <p><strong>访问地址:</strong> http://192.168.5.1:8888</p>
                <p><strong>管理命令:</strong></p>
                <ul>
                    <li>启动: /etc/init.d/openclash-manage start</li>
                    <li>停止: /etc/init.d/openclash-manage stop</li>
                    <li>重启: /etc/init.d/openclash-manage restart</li>
                    <li>状态: /etc/init.d/openclash-manage status</li>
                </ul>
            </div>
        </div>
    </div>
</body>
</html>
EOF

    # 创建manage.sh
    cat > manage.sh << 'EOF'
#!/bin/sh
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
        ;;
esac
EOF
    chmod +x manage.sh

    print_success "应用文件创建完成"
}

# 设置文件权限
set_permissions() {
    print_step "5" "设置文件权限..."
    
    chmod +x "$APP_DIR/app.py"
    chmod +x "$APP_DIR/manage.sh"
    touch "$APP_DIR/wangluo/log.txt"
    chmod 666 "$APP_DIR/wangluo/log.txt"
    
    print_success "文件权限设置完成"
}

# 创建系统服务
create_service() {
    print_step "6" "创建系统服务..."
    
    cat > /etc/init.d/openclash-manage << 'EOF'
#!/bin/sh /etc/rc.common

START=99
STOP=15

start() {
    /root/OpenClashManage/manage.sh start
}

stop() {
    /root/OpenClashManage/manage.sh stop
}

restart() {
    /root/OpenClashManage/manage.sh restart
}

status() {
    /root/OpenClashManage/manage.sh status
}
EOF

    chmod +x /etc/init.d/openclash-manage
    /etc/init.d/openclash-manage enable
    
    print_success "系统服务创建完成"
}

# 启动应用
start_application() {
    print_step "7" "启动应用..."
    
    cd "$APP_DIR"
    nohup python3 app.py > "$LOG_FILE" 2>&1 &
    local pid=$!
    
    sleep 3
    
    if pgrep -f "python3 app.py" > /dev/null; then
        print_success "应用启动成功，PID: $pid"
    else
        print_error "应用启动失败"
        return 1
    fi
}

# 测试应用
test_application() {
    print_step "8" "测试应用..."
    
    sleep 2
    
    # 检查进程
    if pgrep -f "python3 app.py" > /dev/null; then
        print_success "应用进程运行正常"
    else
        print_error "应用进程未运行"
        return 1
    fi
    
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
}

# 显示安装结果
show_result() {
    echo ""
    echo -e "${BLUE}=========================================="
    echo "    安装完成！"
    echo "=========================================="
    echo -e "${NC}"
    
    print_success "OpenClash管理面板安装成功"
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
    echo "📝 日志文件: /root/OpenClashManage/wangluo/log.txt"
    echo ""
    echo "💡 提示: 现在可以在浏览器中访问管理面板了！"
}

# 主安装流程
main() {
    print_header
    
    check_root
    install_python3
    install_python_deps
    create_app_dirs
    create_app_files
    set_permissions
    create_service
    start_application
    test_application
    show_result
}

# 运行安装
main "$@" 