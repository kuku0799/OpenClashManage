#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from flask import Flask, render_template, request, jsonify, redirect, url_for, flash
import os
import json
import subprocess
import threading
import time
from datetime import datetime
import hashlib
from log import write_log

app = Flask(__name__)
app.secret_key = 'openclash_manage_secret_key_2024'

# 配置路径
ROOT_DIR = "/root/OpenClashManage"
NODES_FILE = f"{ROOT_DIR}/wangluo/nodes.txt"
LOG_FILE = f"{ROOT_DIR}/wangluo/log.txt"
CONFIG_FILE = "/etc/openclash/config.yaml"
PID_FILE = "/tmp/openclash_watchdog.pid"

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
            return f"读取日志失败: {e}"
    
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
    
    def start_watchdog(self):
        """启动守护进程"""
        if self.watchdog_running:
            return False, "守护进程已在运行"
        
        try:
            # 检查是否已有守护进程运行
            if os.path.exists(PID_FILE):
                with open(PID_FILE, 'r') as f:
                    pid = f.read().strip()
                if pid and self.check_process_running(pid):
                    return False, f"守护进程已在运行 (PID: {pid})"
            
            # 启动守护进程
            cmd = f"bash {ROOT_DIR}/jk.sh"
            subprocess.Popen(cmd, shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            time.sleep(1)
            
            self.watchdog_running = True
            write_log("✅ 守护进程已启动")
            return True, "守护进程启动成功"
        except Exception as e:
            write_log(f"❌ 启动守护进程失败: {e}")
            return False, f"启动失败: {e}"
    
    def stop_watchdog(self):
        """停止守护进程"""
        try:
            if os.path.exists(PID_FILE):
                with open(PID_FILE, 'r') as f:
                    pid = f.read().strip()
                if pid:
                    subprocess.run(f"kill {pid}", shell=True, capture_output=True)
                    os.remove(PID_FILE)
            
            self.watchdog_running = False
            write_log("✅ 守护进程已停止")
            return True, "守护进程已停止"
        except Exception as e:
            write_log(f"❌ 停止守护进程失败: {e}")
            return False, f"停止失败: {e}"
    
    def check_process_running(self, pid):
        """检查进程是否运行"""
        try:
            subprocess.run(f"kill -0 {pid}", shell=True, capture_output=True)
            return True
        except:
            return False
    
    def get_watchdog_status(self):
        """获取守护进程状态"""
        if os.path.exists(PID_FILE):
            with open(PID_FILE, 'r') as f:
                pid = f.read().strip()
            if pid and self.check_process_running(pid):
                return True, pid
        return False, None
    
    def manual_sync(self):
        """手动同步节点"""
        try:
            result = subprocess.run(f"python3 {ROOT_DIR}/zr.py", 
                                 shell=True, capture_output=True, text=True)
            if result.returncode == 0:
                write_log("✅ 手动同步成功")
                return True, "同步成功"
            else:
                write_log(f"❌ 手动同步失败: {result.stderr}")
                return False, f"同步失败: {result.stderr}"
        except Exception as e:
            write_log(f"❌ 手动同步异常: {e}")
            return False, f"同步异常: {e}"
    
    def get_openclash_status(self):
        """获取OpenClash状态"""
        try:
            result = subprocess.run("/etc/init.d/openclash status", 
                                 shell=True, capture_output=True, text=True)
            return "running" in result.stdout.lower()
        except:
            return False
    
    def restart_openclash(self):
        """重启OpenClash"""
        try:
            subprocess.run("/etc/init.d/openclash restart", shell=True)
            write_log("✅ OpenClash已重启")
            return True, "重启成功"
        except Exception as e:
            write_log(f"❌ 重启OpenClash失败: {e}")
            return False, f"重启失败: {e}"
    
    def get_system_info(self):
        """获取系统信息"""
        try:
            # 获取内存使用
            mem_info = subprocess.run("free -h", shell=True, capture_output=True, text=True).stdout
            
            # 获取磁盘使用
            disk_info = subprocess.run("df -h /", shell=True, capture_output=True, text=True).stdout
            
            # 获取CPU负载
            cpu_load = subprocess.run("uptime", shell=True, capture_output=True, text=True).stdout
            
            return {
                'memory': mem_info,
                'disk': disk_info,
                'cpu_load': cpu_load
            }
        except Exception as e:
            return {'error': str(e)}

# 创建管理器实例
manager = OpenClashManager()

@app.route('/')
def index():
    """主页"""
    nodes_content = manager.get_nodes_content()
    log_content = manager.get_log_content(50)
    watchdog_status, watchdog_pid = manager.get_watchdog_status()
    openclash_status = manager.get_openclash_status()
    
    return render_template('index.html',
                         nodes_content=nodes_content,
                         log_content=log_content,
                         watchdog_status=watchdog_status,
                         watchdog_pid=watchdog_pid,
                         openclash_status=openclash_status)

@app.route('/api/save_nodes', methods=['POST'])
def save_nodes():
    """保存节点内容"""
    content = request.form.get('content', '')
    if manager.save_nodes_content(content):
        return jsonify({'success': True, 'message': '节点保存成功'})
    else:
        return jsonify({'success': False, 'message': '节点保存失败'})

@app.route('/api/start_watchdog', methods=['POST'])
def start_watchdog():
    """启动守护进程"""
    success, message = manager.start_watchdog()
    return jsonify({'success': success, 'message': message})

@app.route('/api/stop_watchdog', methods=['POST'])
def stop_watchdog():
    """停止守护进程"""
    success, message = manager.stop_watchdog()
    return jsonify({'success': success, 'message': message})

@app.route('/api/manual_sync', methods=['POST'])
def manual_sync():
    """手动同步"""
    success, message = manager.manual_sync()
    return jsonify({'success': success, 'message': message})

@app.route('/api/restart_openclash', methods=['POST'])
def restart_openclash():
    """重启OpenClash"""
    success, message = manager.restart_openclash()
    return jsonify({'success': success, 'message': message})

@app.route('/api/clear_log', methods=['POST'])
def clear_log():
    """清空日志"""
    if manager.clear_log():
        return jsonify({'success': True, 'message': '日志已清空'})
    else:
        return jsonify({'success': False, 'message': '清空日志失败'})

@app.route('/api/get_status')
def get_status():
    """获取状态信息"""
    watchdog_status, watchdog_pid = manager.get_watchdog_status()
    openclash_status = manager.get_openclash_status()
    log_content = manager.get_log_content(20)
    
    return jsonify({
        'watchdog_status': watchdog_status,
        'watchdog_pid': watchdog_pid,
        'openclash_status': openclash_status,
        'log_content': log_content
    })

@app.route('/api/system_info')
def system_info():
    """获取系统信息"""
    info = manager.get_system_info()
    return jsonify(info)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=False) 