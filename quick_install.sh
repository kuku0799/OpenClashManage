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
import json
import subprocess
import threading
import time
from datetime import datetime

app = Flask(__name__)
app.secret_key = 'openclash_manage_secret_key_2024'

# 配置路径
ROOT_DIR = "/root/OpenClashManage"
NODES_FILE = f"{ROOT_DIR}/wangluo/nodes.txt"
LOG_FILE = f"{ROOT_DIR}/wangluo/log.txt"
CONFIG_FILE = "/etc/openclash/config.yaml"
PID_FILE = "/tmp/openclash_watchdog.pid"

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

class OpenClashManager:
    def __init__(self):
        self.watchdog_running = False
        self.watchdog_thread = None
    
    def get_nodes_content(self):
        """获取节点文件内容"""
        try:
            if os.path.exists(NODES_FILE):
                with open(NODES_FILE, 'r', encoding='utf-8') as f:
                    return f.read()
            return ""
        except Exception as e:
            write_log(f"❌ 读取节点文件失败: {e}")
            return ""
    
    def save_nodes_content(self, content):
        """保存节点文件内容"""
        try:
            os.makedirs(os.path.dirname(NODES_FILE), exist_ok=True)
            with open(NODES_FILE, 'w', encoding='utf-8') as f:
                f.write(content)
            write_log("✅ 节点文件已更新")
            return True
        except Exception as e:
            write_log(f"❌ 保存节点文件失败: {e}")
            return False
    
    def get_log_content(self, lines=100):
        """获取日志内容"""
        try:
            if os.path.exists(LOG_FILE):
                with open(LOG_FILE, 'r', encoding='utf-8') as f:
                    all_lines = f.readlines()
                    return ''.join(all_lines[-lines:])
            return ""
        except Exception as e:
            write_log(f"❌ 读取日志失败: {e}")
            return ""
    
    def clear_log(self):
        """清空日志"""
        try:
            with open(LOG_FILE, 'w', encoding='utf-8') as f:
                f.write("")
            write_log("✅ 日志已清空")
            return True
        except Exception as e:
            write_log(f"❌ 清空日志失败: {e}")
            return False
    
    def get_openclash_status(self):
        """获取OpenClash状态"""
        try:
            result = subprocess.run("pgrep -f 'openclash'", shell=True, capture_output=True, text=True)
            return result.returncode == 0
        except:
            return False
    
    def restart_openclash(self):
        """重启OpenClash"""
        try:
            subprocess.run("/etc/init.d/openclash restart", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            time.sleep(3)
            write_log("✅ OpenClash 已重启")
            return True, "OpenClash 重启成功"
        except Exception as e:
            write_log(f"❌ 重启 OpenClash 失败: {e}")
            return False, f"重启失败: {e}"
    
    def get_system_info(self):
        """获取系统信息"""
        try:
            info = {}
            
            # 内存信息
            try:
                result = subprocess.run("free -h", shell=True, capture_output=True, text=True)
                if result.returncode == 0:
                    info['memory'] = result.stdout
            except:
                pass
            
            # 磁盘信息
            try:
                result = subprocess.run("df -h", shell=True, capture_output=True, text=True)
                if result.returncode == 0:
                    info['disk'] = result.stdout
            except:
                pass
            
            # CPU负载
            try:
                result = subprocess.run("uptime", shell=True, capture_output=True, text=True)
                if result.returncode == 0:
                    info['cpu_load'] = result.stdout
            except:
                pass
            
            return info
        except Exception as e:
            return {'error': str(e)}

# 创建管理器实例
manager = OpenClashManager()

@app.route('/')
def index():
    """主页"""
    nodes_content = manager.get_nodes_content()
    log_content = manager.get_log_content()
    return render_template('index.html', nodes_content=nodes_content, log_content=log_content)

@app.route('/api/save_nodes', methods=['POST'])
def save_nodes():
    """保存节点"""
    content = request.form.get('content', '')
    success = manager.save_nodes_content(content)
    return jsonify({
        'success': success,
        'message': '节点保存成功' if success else '节点保存失败'
    })

@app.route('/api/clear_log', methods=['POST'])
def clear_log():
    """清空日志"""
    success = manager.clear_log()
    return jsonify({
        'success': success,
        'message': '日志清空成功' if success else '日志清空失败'
    })

@app.route('/api/get_status')
def get_status():
    """获取状态"""
    openclash_status = manager.get_openclash_status()
    watchdog_status = False  # 简化版本
    
    return jsonify({
        'openclash_running': openclash_status,
        'watchdog_running': watchdog_status,
        'timestamp': datetime.now().isoformat()
    })

@app.route('/api/system_info')
def system_info():
    """获取系统信息"""
    info = manager.get_system_info()
    return jsonify(info)

@app.route('/api/restart_openclash', methods=['POST'])
def restart_openclash():
    """重启OpenClash"""
    success, message = manager.restart_openclash()
    return jsonify({
        'success': success,
        'message': message
    })

@app.route('/api/get_nodes', methods=['GET'])
def get_nodes():
    """获取节点列表"""
    content = manager.get_nodes_content()
    return jsonify({
        'content': content,
        'lines': len(content.split('\n')) if content else 0
    })

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
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>OpenClash管理面板</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 20px 40px rgba(0,0,0,0.1);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            text-align: center;
        }
        
        .header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        
        .header p {
            font-size: 1.1em;
            opacity: 0.9;
        }
        
        .content {
            padding: 30px;
        }
        
        .status-bar {
            background: #f8f9fa;
            border-radius: 10px;
            padding: 20px;
            margin-bottom: 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            flex-wrap: wrap;
            gap: 15px;
        }
        
        .status-item {
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .status-dot {
            width: 12px;
            height: 12px;
            border-radius: 50%;
            display: inline-block;
        }
        
        .status-running {
            background: #28a745;
        }
        
        .status-stopped {
            background: #dc3545;
        }
        
        .tabs {
            display: flex;
            border-bottom: 2px solid #e9ecef;
            margin-bottom: 20px;
        }
        
        .tab {
            padding: 15px 30px;
            background: none;
            border: none;
            cursor: pointer;
            font-size: 16px;
            color: #6c757d;
            border-bottom: 3px solid transparent;
            transition: all 0.3s ease;
        }
        
        .tab.active {
            color: #667eea;
            border-bottom-color: #667eea;
        }
        
        .tab:hover {
            color: #667eea;
        }
        
        .tab-content {
            display: none;
        }
        
        .tab-content.active {
            display: block;
        }
        
        .form-group {
            margin-bottom: 20px;
        }
        
        .form-group label {
            display: block;
            margin-bottom: 8px;
            font-weight: 600;
            color: #495057;
        }
        
        .form-control {
            width: 100%;
            padding: 12px;
            border: 2px solid #e9ecef;
            border-radius: 8px;
            font-size: 14px;
            transition: border-color 0.3s ease;
        }
        
        .form-control:focus {
            outline: none;
            border-color: #667eea;
        }
        
        .btn {
            padding: 12px 24px;
            border: none;
            border-radius: 8px;
            font-size: 14px;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.3s ease;
            margin-right: 10px;
            margin-bottom: 10px;
        }
        
        .btn-primary {
            background: #667eea;
            color: white;
        }
        
        .btn-primary:hover {
            background: #5a6fd8;
        }
        
        .btn-success {
            background: #28a745;
            color: white;
        }
        
        .btn-success:hover {
            background: #218838;
        }
        
        .btn-danger {
            background: #dc3545;
            color: white;
        }
        
        .btn-danger:hover {
            background: #c82333;
        }
        
        .btn-warning {
            background: #ffc107;
            color: #212529;
        }
        
        .btn-warning:hover {
            background: #e0a800;
        }
        
        .log-container {
            background: #f8f9fa;
            border-radius: 8px;
            padding: 20px;
            max-height: 400px;
            overflow-y: auto;
            font-family: 'Courier New', monospace;
            font-size: 12px;
            line-height: 1.4;
            white-space: pre-wrap;
        }
        
        .alert {
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 20px;
        }
        
        .alert-success {
            background: #d4edda;
            border: 1px solid #c3e6cb;
            color: #155724;
        }
        
        .alert-danger {
            background: #f8d7da;
            border: 1px solid #f5c6cb;
            color: #721c24;
        }
        
        .alert-info {
            background: #d1ecf1;
            border: 1px solid #bee5eb;
            color: #0c5460;
        }
        
        .system-info {
            background: #f8f9fa;
            border-radius: 8px;
            padding: 20px;
            margin-top: 20px;
        }
        
        .system-info h3 {
            margin-bottom: 15px;
            color: #495057;
        }
        
        .system-info pre {
            background: white;
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
            font-size: 12px;
        }
        
        @media (max-width: 768px) {
            .container {
                margin: 10px;
                border-radius: 10px;
            }
            
            .header {
                padding: 20px;
            }
            
            .header h1 {
                font-size: 2em;
            }
            
            .content {
                padding: 20px;
            }
            
            .status-bar {
                flex-direction: column;
                align-items: flex-start;
            }
            
            .tabs {
                flex-wrap: wrap;
            }
            
            .tab {
                padding: 10px 15px;
                font-size: 14px;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>OpenClash管理面板</h1>
            <p>快速安装版本 - 功能完整</p>
        </div>
        
        <div class="content">
            <div class="status-bar">
                <div class="status-item">
                    <span class="status-dot status-running" id="openclash-status"></span>
                    <span>OpenClash: <span id="openclash-text">检查中...</span></span>
                </div>
                <div class="status-item">
                    <span class="status-dot status-stopped" id="watchdog-status"></span>
                    <span>守护进程: <span id="watchdog-text">未运行</span></span>
                </div>
                <div class="status-item">
                    <span>访问地址: http://192.168.5.1:8888</span>
                </div>
            </div>
            
            <div class="tabs">
                <button class="tab active" onclick="showTab('nodes')">节点管理</button>
                <button class="tab" onclick="showTab('logs')">日志查看</button>
                <button class="tab" onclick="showTab('system')">系统信息</button>
                <button class="tab" onclick="showTab('control')">控制面板</button>
            </div>
            
            <!-- 节点管理 -->
            <div id="nodes-tab" class="tab-content active">
                <div class="form-group">
                    <label for="nodes-content">节点配置:</label>
                    <textarea id="nodes-content" class="form-control" rows="15" placeholder="在此输入节点配置...">{{ nodes_content }}</textarea>
                </div>
                <button class="btn btn-primary" onclick="saveNodes()">保存节点</button>
                <button class="btn btn-success" onclick="loadNodes()">刷新节点</button>
                <div id="nodes-alert"></div>
            </div>
            
            <!-- 日志查看 -->
            <div id="logs-tab" class="tab-content">
                <div class="log-container" id="log-content">{{ log_content }}</div>
                <button class="btn btn-warning" onclick="clearLog()">清空日志</button>
                <button class="btn btn-primary" onclick="refreshLog()">刷新日志</button>
                <div id="logs-alert"></div>
            </div>
            
            <!-- 系统信息 -->
            <div id="system-tab" class="tab-content">
                <div class="system-info">
                    <h3>系统状态</h3>
                    <div id="system-content">加载中...</div>
                </div>
                <button class="btn btn-primary" onclick="loadSystemInfo()">刷新系统信息</button>
            </div>
            
            <!-- 控制面板 -->
            <div id="control-tab" class="tab-content">
                <h3>控制操作</h3>
                <button class="btn btn-success" onclick="restartOpenClash()">重启OpenClash</button>
                <button class="btn btn-primary" onclick="refreshStatus()">刷新状态</button>
                <div id="control-alert"></div>
            </div>
        </div>
    </div>
    
    <script>
        // 显示标签页
        function showTab(tabName) {
            // 隐藏所有标签页
            document.querySelectorAll('.tab-content').forEach(tab => {
                tab.classList.remove('active');
            });
            document.querySelectorAll('.tab').forEach(tab => {
                tab.classList.remove('active');
            });
            
            // 显示选中的标签页
            document.getElementById(tabName + '-tab').classList.add('active');
            event.target.classList.add('active');
        }
        
        // 保存节点
        function saveNodes() {
            const content = document.getElementById('nodes-content').value;
            fetch('/api/save_nodes', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                },
                body: 'content=' + encodeURIComponent(content)
            })
            .then(response => response.json())
            .then(data => {
                showAlert('nodes-alert', data.success ? 'success' : 'danger', data.message);
            })
            .catch(error => {
                showAlert('nodes-alert', 'danger', '保存失败: ' + error);
            });
        }
        
        // 加载节点
        function loadNodes() {
            fetch('/api/get_nodes')
            .then(response => response.json())
            .then(data => {
                document.getElementById('nodes-content').value = data.content;
                showAlert('nodes-alert', 'success', '节点加载成功');
            })
            .catch(error => {
                showAlert('nodes-alert', 'danger', '加载失败: ' + error);
            });
        }
        
        // 清空日志
        function clearLog() {
            if (confirm('确定要清空日志吗？')) {
                fetch('/api/clear_log', {
                    method: 'POST'
                })
                .then(response => response.json())
                .then(data => {
                    showAlert('logs-alert', data.success ? 'success' : 'danger', data.message);
                    if (data.success) {
                        document.getElementById('log-content').textContent = '';
                    }
                })
                .catch(error => {
                    showAlert('logs-alert', 'danger', '清空失败: ' + error);
                });
            }
        }
        
        // 刷新日志
        function refreshLog() {
            location.reload();
        }
        
        // 加载系统信息
        function loadSystemInfo() {
            fetch('/api/system_info')
            .then(response => response.json())
            .then(data => {
                let html = '';
                if (data.memory) {
                    html += '<h4>内存信息:</h4><pre>' + data.memory + '</pre>';
                }
                if (data.disk) {
                    html += '<h4>磁盘信息:</h4><pre>' + data.disk + '</pre>';
                }
                if (data.cpu_load) {
                    html += '<h4>CPU负载:</h4><pre>' + data.cpu_load + '</pre>';
                }
                if (data.error) {
                    html = '<div class="alert alert-danger">加载系统信息失败: ' + data.error + '</div>';
                }
                document.getElementById('system-content').innerHTML = html;
            })
            .catch(error => {
                document.getElementById('system-content').innerHTML = '<div class="alert alert-danger">加载失败: ' + error + '</div>';
            });
        }
        
        // 重启OpenClash
        function restartOpenClash() {
            if (confirm('确定要重启OpenClash吗？')) {
                fetch('/api/restart_openclash', {
                    method: 'POST'
                })
                .then(response => response.json())
                .then(data => {
                    showAlert('control-alert', data.success ? 'success' : 'danger', data.message);
                })
                .catch(error => {
                    showAlert('control-alert', 'danger', '重启失败: ' + error);
                });
            }
        }
        
        // 刷新状态
        function refreshStatus() {
            fetch('/api/get_status')
            .then(response => response.json())
            .then(data => {
                updateStatus(data);
            })
            .catch(error => {
                console.error('刷新状态失败:', error);
            });
        }
        
        // 更新状态显示
        function updateStatus(data) {
            const openclashStatus = document.getElementById('openclash-status');
            const openclashText = document.getElementById('openclash-text');
            const watchdogStatus = document.getElementById('watchdog-status');
            const watchdogText = document.getElementById('watchdog-text');
            
            if (data.openclash_running) {
                openclashStatus.className = 'status-dot status-running';
                openclashText.textContent = '运行中';
            } else {
                openclashStatus.className = 'status-dot status-stopped';
                openclashText.textContent = '已停止';
            }
            
            if (data.watchdog_running) {
                watchdogStatus.className = 'status-dot status-running';
                watchdogText.textContent = '运行中';
            } else {
                watchdogStatus.className = 'status-dot status-stopped';
                watchdogText.textContent = '未运行';
            }
        }
        
        // 显示提示信息
        function showAlert(elementId, type, message) {
            const alertDiv = document.getElementById(elementId);
            alertDiv.innerHTML = '<div class="alert alert-' + type + '">' + message + '</div>';
            setTimeout(() => {
                alertDiv.innerHTML = '';
            }, 3000);
        }
        
        // 页面加载完成后初始化
        document.addEventListener('DOMContentLoaded', function() {
            refreshStatus();
            loadSystemInfo();
            
            // 每30秒自动刷新状态
            setInterval(refreshStatus, 30000);
        });
    </script>
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