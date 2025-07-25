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
import re

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
    
    def parse_nodes(self, content):
        """解析节点内容，返回节点列表"""
        nodes = []
        lines = content.strip().split('\n')
        
        for i, line in enumerate(lines):
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            
            # 尝试解析节点名称（在#后面）
            node_name = ""
            if '#' in line:
                parts = line.split('#', 1)
                node_url = parts[0].strip()
                node_name = parts[1].strip() if len(parts) > 1 else ""
            else:
                node_url = line
            
            # 验证是否为有效的节点链接
            if self.is_valid_node_url(node_url):
                nodes.append({
                    'index': i,
                    'url': node_url,
                    'name': node_name,
                    'type': self.get_node_type(node_url),
                    'full_line': line
                })
        
        return nodes
    
    def is_valid_node_url(self, url):
        """验证是否为有效的节点URL"""
        valid_prefixes = ['ss://', 'vmess://', 'vless://', 'trojan://']
        return any(url.startswith(prefix) for prefix in valid_prefixes)
    
    def get_node_type(self, url):
        """获取节点类型"""
        if url.startswith('ss://'):
            return 'Shadowsocks'
        elif url.startswith('vmess://'):
            return 'VMess'
        elif url.startswith('vless://'):
            return 'VLESS'
        elif url.startswith('trojan://'):
            return 'Trojan'
        else:
            return 'Unknown'
    
    def get_nodes_list(self):
        """获取节点列表"""
        content = self.get_nodes_content()
        return self.parse_nodes(content)
    
    def delete_node(self, node_index):
        """删除指定索引的节点"""
        try:
            content = self.get_nodes_content()
            lines = content.split('\n')
            
            # 找到实际的节点行（跳过注释和空行）
            node_lines = []
            for i, line in enumerate(lines):
                line = line.strip()
                if line and not line.startswith('#'):
                    node_lines.append((i, line))
            
            if node_index >= len(node_lines):
                return False, "节点索引超出范围"
            
            # 获取要删除的行号
            line_index, _ = node_lines[node_index]
            
            # 删除该行
            lines.pop(line_index)
            
            # 保存更新后的内容
            new_content = '\n'.join(lines)
            if self.save_nodes_content(new_content):
                write_log(f"✅ 已删除节点 #{node_index + 1}")
                return True, f"节点 #{node_index + 1} 已删除"
            else:
                return False, "保存节点文件失败"
                
        except Exception as e:
            write_log(f"❌ 删除节点失败: {e}")
            return False, f"删除节点失败: {e}"
    
    def delete_nodes_batch(self, node_indices):
        """批量删除节点"""
        try:
            content = self.get_nodes_content()
            lines = content.split('\n')
            
            # 找到实际的节点行（跳过注释和空行）
            node_lines = []
            for i, line in enumerate(lines):
                line = line.strip()
                if line and not line.startswith('#'):
                    node_lines.append((i, line))
            
            # 验证索引
            for index in node_indices:
                if index >= len(node_lines):
                    return False, f"节点索引 {index} 超出范围"
            
            # 按索引倒序删除，避免索引变化
            node_indices.sort(reverse=True)
            deleted_lines = []
            
            for index in node_indices:
                line_index, line_content = node_lines[index]
                deleted_lines.append(line_content)
                lines.pop(line_index)
            
            # 保存更新后的内容
            new_content = '\n'.join(lines)
            if self.save_nodes_content(new_content):
                write_log(f"✅ 已批量删除 {len(node_indices)} 个节点")
                return True, f"已删除 {len(node_indices)} 个节点"
            else:
                return False, "保存节点文件失败"
                
        except Exception as e:
            write_log(f"❌ 批量删除节点失败: {e}")
            return False, f"批量删除节点失败: {e}"
    
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
                    subprocess.run(f"kill {pid}", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    time.sleep(1)
            
            # 确保进程已停止
            subprocess.run("pkill -f 'jk.sh'", shell=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            
            if os.path.exists(PID_FILE):
                os.remove(PID_FILE)
            
            self.watchdog_running = False
            write_log("✅ 守护进程已停止")
            return True, "守护进程停止成功"
        except Exception as e:
            write_log(f"❌ 停止守护进程失败: {e}")
            return False, f"停止失败: {e}"
    
    def check_process_running(self, pid):
        """检查进程是否运行"""
        try:
            result = subprocess.run(f"ps -p {pid}", shell=True, capture_output=True, text=True)
            return result.returncode == 0
        except:
            return False
    
    def get_watchdog_status(self):
        """获取守护进程状态"""
        try:
            if os.path.exists(PID_FILE):
                with open(PID_FILE, 'r') as f:
                    pid = f.read().strip()
                if pid and self.check_process_running(pid):
                    return True, pid
            return False, None
        except:
            return False, None
    
    def manual_sync(self):
        """手动同步节点"""
        try:
            cmd = f"python3 {ROOT_DIR}/zr.py"
            result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
            
            if result.returncode == 0:
                write_log("✅ 手动同步完成")
                return True, "手动同步完成"
            else:
                write_log(f"❌ 手动同步失败: {result.stderr}")
                return False, f"同步失败: {result.stderr}"
        except Exception as e:
            write_log(f"❌ 手动同步异常: {e}")
            return False, f"同步异常: {e}"
    
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
    success = manager.clear_log()
    return jsonify({
        'success': success,
        'message': '日志清空成功' if success else '日志清空失败'
    })

@app.route('/api/get_status')
def get_status():
    """获取状态信息"""
    watchdog_status, watchdog_pid = manager.get_watchdog_status()
    openclash_status = manager.get_openclash_status()
    log_content = manager.get_log_content()
    
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

@app.route('/api/get_nodes', methods=['GET'])
def get_nodes():
    """获取节点列表"""
    nodes = manager.get_nodes_list()
    return jsonify({
        'success': True,
        'nodes': nodes
    })

@app.route('/api/delete_node', methods=['POST'])
def delete_node():
    """删除单个节点"""
    try:
        data = request.get_json()
        node_index = data.get('index')
        
        if node_index is None:
            return jsonify({'success': False, 'message': '缺少节点索引参数'})
        
        success, message = manager.delete_node(node_index)
        return jsonify({'success': success, 'message': message})
    except Exception as e:
        return jsonify({'success': False, 'message': f'删除节点失败: {e}'})

@app.route('/api/delete_nodes_batch', methods=['POST'])
def delete_nodes_batch():
    """批量删除节点"""
    try:
        data = request.get_json()
        node_indices = data.get('indices', [])
        
        if not node_indices:
            return jsonify({'success': False, 'message': '缺少节点索引参数'})
        
        success, message = manager.delete_nodes_batch(node_indices)
        return jsonify({'success': success, 'message': message})
    except Exception as e:
        return jsonify({'success': False, 'message': f'批量删除节点失败: {e}'})

@app.route('/api/test_node_speed', methods=['POST'])
def test_node_speed():
    """测试节点速度"""
    try:
        data = request.get_json()
        node_index = data.get('index')
        
        if node_index is None:
            return jsonify({'success': False, 'message': '缺少节点索引参数'})
        
        # 获取节点信息
        nodes = manager.get_nodes_list()
        if node_index >= len(nodes):
            return jsonify({'success': False, 'message': '节点索引超出范围'})
        
        node = nodes[node_index]
        node_url = node['url']
        
        # 模拟测速（实际项目中需要调用真实的测速工具）
        import random
        import time
        
        # 模拟测速延迟
        time.sleep(1)
        
        # 生成模拟结果
        latency = random.randint(50, 300)  # 延迟 50-300ms
        speed = random.randint(1, 100)     # 速度 1-100Mbps
        
        result = {
            'success': True,
            'node_name': node.get('name', f'节点 {node_index + 1}'),
            'latency': latency,
            'speed': speed,
            'status': 'success' if latency < 200 else 'warning' if latency < 500 else 'error'
        }
        
        return jsonify(result)
    except Exception as e:
        return jsonify({'success': False, 'message': f'测速失败: {e}'})

@app.route('/api/get_node_groups', methods=['GET'])
def get_node_groups():
    """获取节点分组"""
    try:
        nodes = manager.get_nodes_list()
        groups = {
            '地区': {},
            '类型': {},
            '速度': {}
        }
        
        for i, node in enumerate(nodes):
            # 按类型分组
            node_type = node.get('type', 'Unknown')
            if node_type not in groups['类型']:
                groups['类型'][node_type] = []
            groups['类型'][node_type].append(i)
            
            # 按地区分组（从节点名称中提取）
            name = node.get('name', '').lower()
            region = '其他'
            if any(keyword in name for keyword in ['香港', 'hk', 'hongkong']):
                region = '香港'
            elif any(keyword in name for keyword in ['台湾', 'tw', 'taiwan']):
                region = '台湾'
            elif any(keyword in name for keyword in ['美国', 'us', 'usa']):
                region = '美国'
            elif any(keyword in name for keyword in ['日本', 'jp', 'japan']):
                region = '日本'
            elif any(keyword in name for keyword in ['新加坡', 'sg', 'singapore']):
                region = '新加坡'
            elif any(keyword in name for keyword in ['韩国', 'kr', 'korea']):
                region = '韩国'
            
            if region not in groups['地区']:
                groups['地区'][region] = []
            groups['地区'][region].append(i)
        
        return jsonify({'success': True, 'groups': groups})
    except Exception as e:
        return jsonify({'success': False, 'message': f'获取分组失败: {e}'})

@app.route('/api/import_nodes', methods=['POST'])
def import_nodes():
    """导入节点（支持多种格式）"""
    try:
        data = request.get_json()
        import_type = data.get('type')  # 'manual', 'file', 'url'
        content = data.get('content', '')
        
        if not content:
            return jsonify({'success': False, 'message': '内容不能为空'})
        
        # 获取当前节点内容
        current_content = manager.get_nodes_content()
        
        if import_type == 'manual':
            # 手动输入：直接添加新内容
            new_content = current_content + '\n' + content
        elif import_type == 'file':
            # 文件导入：解析文件内容
            new_content = current_content + '\n' + content
        elif import_type == 'url':
            # URL导入：从URL获取节点列表
            try:
                import requests
                response = requests.get(content, timeout=10)
                if response.status_code == 200:
                    url_content = response.text
                    new_content = current_content + '\n' + url_content
                else:
                    return jsonify({'success': False, 'message': f'URL请求失败: {response.status_code}'})
            except Exception as e:
                return jsonify({'success': False, 'message': f'URL导入失败: {e}'})
        else:
            return jsonify({'success': False, 'message': '不支持的导入类型'})
        
        # 保存新内容
        if manager.save_nodes_content(new_content):
            write_log(f"✅ 成功导入节点 (类型: {import_type})")
            return jsonify({'success': True, 'message': '节点导入成功'})
        else:
            return jsonify({'success': False, 'message': '保存节点失败'})
            
    except Exception as e:
        write_log(f"❌ 导入节点失败: {e}")
        return jsonify({'success': False, 'message': f'导入节点失败: {e}'})

@app.route('/api/validate_node', methods=['POST'])
def validate_node():
    """验证单个节点格式"""
    try:
        data = request.get_json()
        node_url = data.get('url', '').strip()
        
        if not node_url:
            return jsonify({'success': False, 'message': '节点URL不能为空'})
        
        # 验证节点格式
        valid_prefixes = ['ss://', 'vmess://', 'vless://', 'trojan://']
        is_valid = any(node_url.startswith(prefix) for prefix in valid_prefixes)
        
        if is_valid:
            node_type = manager.get_node_type(node_url)
            return jsonify({
                'success': True, 
                'message': '节点格式正确',
                'type': node_type
            })
        else:
            return jsonify({'success': False, 'message': '不支持的节点格式'})
            
    except Exception as e:
        return jsonify({'success': False, 'message': f'验证节点失败: {e}'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8888, debug=False) 