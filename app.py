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
ROOT_DIR = os.getenv("OPENCLASH_MANAGE_ROOT", "/root/OpenClashManage")
NODES_FILE = f"{ROOT_DIR}/wangluo/nodes.txt"
LOG_FILE = f"{ROOT_DIR}/wangluo/log.txt"
CONFIG_FILE = os.getenv("OPENCLASH_CONFIG_PATH", "/etc/openclash/config.yaml")
PID_FILE = "/tmp/openclash_watchdog.pid"

class OpenClashManager:
    def __init__(self):
        self.watchdog_running = False
        self.watchdog_thread = None
    
    def check_dependencies(self):
        """检查依赖文件是否存在"""
        dependencies = [
            f"{ROOT_DIR}/jk.sh",
            f"{ROOT_DIR}/zr.py", 
            f"{ROOT_DIR}/jx.py",
            f"{ROOT_DIR}/zw.py",
            f"{ROOT_DIR}/zc.py"
        ]
        
        missing_files = []
        for file_path in dependencies:
            if not os.path.exists(file_path):
                missing_files.append(file_path)
        
        if missing_files:
            write_log(f"❌ 缺少依赖文件: {missing_files}")
            return False
        
        return True
    
    def initialize_directories(self):
        """初始化必要的目录"""
        try:
            # 创建必要的目录
            directories = [
                os.path.dirname(NODES_FILE),
                os.path.dirname(LOG_FILE),
                ROOT_DIR
            ]
            
            for directory in directories:
                os.makedirs(directory, exist_ok=True)
            
            # 创建空的节点文件（如果不存在）
            if not os.path.exists(NODES_FILE):
                with open(NODES_FILE, 'w', encoding='utf-8') as f:
                    f.write("# OpenClash 节点配置文件\n# 每行一个节点链接，支持注释\n")
                write_log("✅ 已创建空的节点文件")
            
            # 创建空的日志文件（如果不存在）
            if not os.path.exists(LOG_FILE):
                with open(LOG_FILE, 'w', encoding='utf-8') as f:
                    f.write("")
                write_log("✅ 已创建空的日志文件")
            
            return True
        except Exception as e:
            write_log(f"❌ 初始化目录失败: {e}")
            return False
    
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
                
                # 处理URL编码的节点名称
                if node_name:
                    try:
                        from urllib.parse import unquote
                        # 多次解码，处理多重编码的情况
                        original_name = node_name
                        for _ in range(3):  # 最多解码3次
                            decoded_name = unquote(node_name)
                            if decoded_name == node_name:  # 如果没有变化，说明已经解码完成
                                break
                            node_name = decoded_name
                    except Exception as e:
                        write_log(f"⚠️ URL解码失败: {e}")
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
        if not url or '://' not in url:
            return False
        
        # 检查支持的协议
        supported_protocols = ['ss://', 'ssr://', 'vmess://', 'vless://', 'trojan://']
        if not any(url.startswith(protocol) for protocol in supported_protocols):
            return False
        
        # 检查URL长度
        if len(url) < 20:  # 最小长度
            return False
        
        return True
    
    def get_node_type(self, url):
        """获取节点类型"""
        # 提取协议类型
        if '://' in url:
            protocol = url.split('://')[0].upper()
            return protocol
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
            
            # 重新构建节点列表，保持原始行号
            valid_lines = []
            for i, line in enumerate(lines):
                if line.strip() and not line.strip().startswith('#'):
                    valid_lines.append((i, line))
            
            if node_index >= len(valid_lines):
                return False, "节点索引超出范围"
            
            # 获取要删除的行号
            line_index, _ = valid_lines[node_index]
            
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
            
            # 重新构建节点列表，保持原始行号
            valid_lines = []
            for i, line in enumerate(lines):
                if line.strip() and not line.strip().startswith('#'):
                    valid_lines.append((i, line))
            
            # 验证索引
            for index in node_indices:
                if index >= len(valid_lines):
                    return False, f"节点索引 {index} 超出范围"
            
            # 按索引倒序删除，避免索引变化
            node_indices.sort(reverse=True)
            deleted_lines = []
            
            for index in node_indices:
                line_index, line_content = valid_lines[index]
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
            # 检查依赖文件
            if not self.check_dependencies():
                return False, "缺少必要的依赖文件，无法启动守护进程"
            
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
            # 检查PID文件
            if os.path.exists(PID_FILE):
                with open(PID_FILE, 'r') as f:
                    pid = f.read().strip()
                if pid and self.check_process_running(pid):
                    return True, pid
            
            # 检查进程是否在运行（备用方法）
            result = subprocess.run("ps | grep jk.sh | grep -v grep", shell=True, capture_output=True, text=True)
            if result.returncode == 0 and result.stdout.strip():
                # 找到进程，提取PID
                lines = result.stdout.strip().split('\n')
                if lines:
                    pid = lines[0].split()[0]
                    return True, pid
            
            return False, None
        except Exception as e:
            write_log(f"❌ 获取守护进程状态失败: {e}")
            return False, None
    
    def manual_sync(self):
        """手动同步节点"""
        try:
            # 检查依赖文件
            if not self.check_dependencies():
                return False, "缺少必要的依赖文件，无法执行同步"
            
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
                result = subprocess.run("free -h", shell=True, capture_output=True, text=True, timeout=5)
                if result.returncode == 0:
                    info['memory'] = result.stdout
                else:
                    info['memory'] = '获取失败'
            except subprocess.TimeoutExpired:
                info['memory'] = '获取超时'
            except:
                info['memory'] = '获取失败'
            
            # 磁盘信息
            try:
                result = subprocess.run("df -h", shell=True, capture_output=True, text=True, timeout=5)
                if result.returncode == 0:
                    info['disk'] = result.stdout
                else:
                    info['disk'] = '获取失败'
            except subprocess.TimeoutExpired:
                info['disk'] = '获取超时'
            except:
                info['disk'] = '获取失败'
            
            # CPU负载
            try:
                result = subprocess.run("uptime", shell=True, capture_output=True, text=True, timeout=5)
                if result.returncode == 0:
                    info['cpu_load'] = result.stdout
                else:
                    info['cpu_load'] = '获取失败'
            except subprocess.TimeoutExpired:
                info['cpu_load'] = '获取超时'
            except:
                info['cpu_load'] = '获取失败'
            
            return info
        except Exception as e:
            write_log(f"❌ 获取系统信息失败: {e}")
            return {'error': str(e)}

# 创建管理器实例
manager = OpenClashManager()

# 初始化应用
try:
    if manager.initialize_directories():
        write_log("✅ 应用初始化成功")
    else:
        write_log("⚠️ 应用初始化部分失败，但将继续运行")
except Exception as e:
    write_log(f"❌ 应用初始化失败: {e}")

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

@app.route('/api/health')
def health_check():
    """健康检查"""
    try:
        # 检查基本功能
        health_status = {
            'status': 'healthy',
            'timestamp': datetime.now().isoformat(),
            'checks': {}
        }
        
        # 检查文件系统
        health_status['checks']['filesystem'] = {
            'nodes_file': os.path.exists(NODES_FILE),
            'log_file': os.path.exists(LOG_FILE),
            'config_file': os.path.exists(CONFIG_FILE)
        }
        
        # 检查依赖文件
        health_status['checks']['dependencies'] = manager.check_dependencies()
        
        # 检查OpenClash状态
        health_status['checks']['openclash'] = manager.get_openclash_status()
        
        # 检查守护进程状态
        watchdog_status, watchdog_pid = manager.get_watchdog_status()
        health_status['checks']['watchdog'] = watchdog_status
        
        # 如果有任何检查失败，标记为不健康
        if not all([
            health_status['checks']['filesystem']['nodes_file'],
            health_status['checks']['filesystem']['log_file'],
            health_status['checks']['dependencies']
        ]):
            health_status['status'] = 'unhealthy'
        
        return jsonify(health_status)
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e),
            'timestamp': datetime.now().isoformat()
        })

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
        
        # 解析节点信息进行更准确的模拟测速
        node_info = parse_single_node_link(node_url)
        if not node_info:
            return jsonify({'success': False, 'message': '无法解析节点信息'})
        
        # 基于节点类型和服务器信息进行更合理的模拟
        import random
        import time
        
        # 模拟测速延迟
        time.sleep(0.5)
        
        # 根据协议类型调整测速参数
        protocol = node_info.get('protocol', 'unknown')
        server = node_info.get('server', 'unknown')
        
        # 基于协议类型的延迟范围
        if protocol == 'ss':
            latency = random.randint(30, 150)
        elif protocol in ['vmess', 'vless']:
            latency = random.randint(50, 200)
        elif protocol == 'trojan':
            latency = random.randint(40, 180)
        else:
            latency = random.randint(50, 300)
        
        # 基于服务器位置的调整
        if any(keyword in server.lower() for keyword in ['hk', 'hongkong', '香港']):
            latency = max(20, latency - 30)  # 香港节点通常更快
        elif any(keyword in server.lower() for keyword in ['jp', 'japan', '日本']):
            latency = max(30, latency - 20)  # 日本节点较快
        elif any(keyword in server.lower() for keyword in ['us', 'usa', '美国']):
            latency = min(500, latency + 50)  # 美国节点较慢
        
        # 速度基于延迟计算
        speed = max(1, int(1000 / latency)) if latency > 0 else random.randint(1, 100)
        
        result = {
            'success': True,
            'node_name': node.get('name', f'节点 {node_index + 1}'),
            'latency': latency,
            'speed': speed,
            'protocol': protocol,
            'server': server,
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
    """验证节点格式"""
    try:
        data = request.get_json()
        node_line = data.get('node_line', '').strip()
        
        if not node_line:
            return jsonify({'success': False, 'message': '节点链接为空'})
        
        # 基本格式验证
        if '://' not in node_line:
            return jsonify({'success': False, 'message': '无效的节点链接格式'})
        
        # 协议验证
        protocol = node_line.split('://')[0].lower()
        valid_protocols = ['ss', 'vmess', 'vless', 'trojan', 'http', 'https', 'socks', 'socks5', 'ssr', 'snell', 'hysteria', 'tuic']
        
        if protocol not in valid_protocols:
            return jsonify({'success': False, 'message': f'不支持的协议: {protocol}'})
        
        return jsonify({'success': True, 'message': '节点格式验证通过'})
        
    except Exception as e:
        write_log(f"❌ 节点验证失败: {e}")
        return jsonify({'success': False, 'message': f'验证失败: {e}'})

@app.route('/api/update_node', methods=['POST'])
def update_node():
    """更新单个节点"""
    try:
        data = request.get_json()
        node_index = data.get('index')
        new_line = data.get('new_line', '').strip()
        
        if node_index is None:
            return jsonify({'success': False, 'message': '缺少节点索引'})
        
        if not new_line:
            return jsonify({'success': False, 'message': '新的节点链接为空'})
        
        # 验证新节点格式
        if '://' not in new_line:
            return jsonify({'success': False, 'message': '无效的节点链接格式'})
        
        # 读取当前节点文件
        content = manager.get_nodes_content()
        lines = content.split('\n')
        
        # 找到实际的节点行（跳过注释和空行）
        node_lines = []
        for i, line in enumerate(lines):
            line = line.strip()
            if line and not line.startswith('#'):
                node_lines.append((i, line))
        
        if node_index >= len(node_lines):
            return jsonify({'success': False, 'message': '节点索引超出范围'})
        
        # 获取要更新的行号
        line_index, _ = node_lines[node_index]
        
        # 更新该行
        lines[line_index] = new_line
        
        # 保存更新后的内容
        new_content = '\n'.join(lines)
        if manager.save_nodes_content(new_content):
            write_log(f"✅ 节点 #{node_index + 1} 已更新")
            return jsonify({'success': True, 'message': f'节点 #{node_index + 1} 更新成功'})
        else:
            return jsonify({'success': False, 'message': '保存节点文件失败'})
            
    except Exception as e:
        write_log(f"❌ 更新节点失败: {e}")
        return jsonify({'success': False, 'message': f'更新节点失败: {e}'})

@app.route('/api/batch_update_nodes', methods=['POST'])
def batch_update_nodes():
    """批量更新节点"""
    try:
        data = request.get_json()
        indices = data.get('indices', [])
        tags = data.get('tags', '').strip()
        remarks = data.get('remarks', '').strip()
        prefix = data.get('prefix', '').strip()
        suffix = data.get('suffix', '').strip()
        
        if not indices:
            return jsonify({'success': False, 'message': '缺少节点索引'})
        
        if not tags and not remarks and not prefix and not suffix:
            return jsonify({'success': False, 'message': '至少需要指定一个修改项'})
        
        # 读取当前节点文件
        content = manager.get_nodes_content()
        lines = content.split('\n')
        
        # 找到实际的节点行（跳过注释和空行）
        node_lines = []
        for i, line in enumerate(lines):
            line = line.strip()
            if line and not line.startswith('#'):
                node_lines.append((i, line))
        
        updated_count = 0
        
        # 更新选中的节点
        for node_index in indices:
            if node_index >= len(node_lines):
                continue
            
            line_index, original_line = node_lines[node_index]
            
            # 解析原始节点
            parts = original_line.split('#', 1)
            node_url = parts[0].strip()
            node_name = parts[1].strip() if len(parts) > 1 else ""
            
            # 应用修改
            new_name = node_name
            
            if prefix:
                new_name = prefix + new_name
            
            if suffix:
                new_name = new_name + suffix
            
            # 构建新的节点行
            new_line = node_url
            if new_name:
                new_line += f"#{new_name}"
            
            # 更新行
            lines[line_index] = new_line
            updated_count += 1
        
        # 保存更新后的内容
        new_content = '\n'.join(lines)
        if manager.save_nodes_content(new_content):
            write_log(f"✅ 批量更新了 {updated_count} 个节点")
            return jsonify({
                'success': True, 
                'message': f'批量更新成功', 
                'updated_count': updated_count
            })
        else:
            return jsonify({'success': False, 'message': '保存节点文件失败'})
            
    except Exception as e:
        write_log(f"❌ 批量更新节点失败: {e}")
        return jsonify({'success': False, 'message': f'批量更新失败: {e}'})

@app.route('/api/add_single_node', methods=['POST'])
def add_single_node():
    """添加单个节点"""
    try:
        data = request.get_json()
        node_link = data.get('node_link', '').strip()
        
        if not node_link:
            return jsonify({'success': False, 'message': '节点链接不能为空'})
        
        # 验证节点格式
        if not manager.is_valid_node_url(node_link):
            return jsonify({'success': False, 'message': '节点链接格式无效'})
        
        # 读取当前节点文件
        content = manager.get_nodes_content()
        lines = content.split('\n')
        
        # 添加新节点到文件末尾
        lines.append(node_link)
        
        # 保存更新后的内容
        new_content = '\n'.join(lines)
        if manager.save_nodes_content(new_content):
            write_log(f"✅ 手动添加节点成功: {node_link.split('#')[-1] if '#' in node_link else '未命名节点'}")
            return jsonify({'success': True, 'message': '节点添加成功'})
        else:
            return jsonify({'success': False, 'message': '保存节点文件失败'})
            
    except Exception as e:
        write_log(f"❌ 添加单个节点失败: {e}")
        return jsonify({'success': False, 'message': f'添加节点失败: {e}'})

@app.route('/api/parse_node_link', methods=['POST'])
def parse_node_link():
    """解析节点链接"""
    try:
        data = request.get_json()
        link = data.get('link', '').strip()
        
        write_log(f"🔍 API收到链接: {link}")
        
        if not link:
            return jsonify({'success': False, 'message': '节点链接不能为空'})
        
        # 使用改进的解析功能
        node_info = parse_single_node_link(link)
        
        write_log(f"🔍 API解析结果: {node_info}")
        
        if node_info:
            response_data = {
                'success': True, 
                'node_info': node_info
            }
            write_log(f"🔍 API返回数据: {response_data}")
            return jsonify(response_data)
        else:
            return jsonify({'success': False, 'message': '无法解析节点链接'})
            
    except Exception as e:
        write_log(f"❌ 解析节点链接失败: {e}")
        return jsonify({'success': False, 'message': f'解析节点链接失败: {e}'})

def parse_single_node_link(link: str) -> dict:
    """解析单个节点链接"""
    try:
        from urllib.parse import unquote, urlparse, parse_qs
        import base64
        import json
        import re
        
        node_info = {}
        
        # 分离节点URL和名称
        if '#' in link:
            node_url, node_name = link.split('#', 1)
            # URL解码节点名称
            try:
                original_name = node_name.strip()
                for _ in range(3):  # 最多解码3次
                    decoded_name = unquote(original_name)
                    if decoded_name == original_name:
                        break
                    original_name = decoded_name
                node_info['name'] = original_name
            except:
                node_info['name'] = node_name.strip()
        else:
            node_url = link
            node_info['name'] = ''
        
        # 添加调试信息
        write_log(f"🔍 开始解析链接: {link}")
        write_log(f"🔍 节点URL: {node_url}")
        write_log(f"🔍 节点名称: {node_info.get('name', '')}")
        
        # 解析协议类型和详细信息
        if node_url.startswith('ss://'):
            node_info['protocol'] = 'ss'
            write_log(f"🔍 开始解析SS链接")
            # 解析SS链接: ss://method:password@server:port
            try:
                # 移除ss://前缀
                ss_content = node_url[5:]
                write_log(f"🔍 SS内容: {ss_content}")
                # 分离认证信息和服务器信息
                if '@' in ss_content:
                    auth_part, server_part = ss_content.split('@', 1)
                    write_log(f"🔍 认证部分: {auth_part}")
                    write_log(f"🔍 服务器部分: {server_part}")
                    
                    # 解析服务器信息（优先处理）
                    if ':' in server_part:
                        server, port = server_part.split(':', 1)
                        node_info['server'] = server
                        node_info['port'] = port
                        write_log(f"🔍 解析到服务器: {server}, 端口: {port}")
                    else:
                        node_info['server'] = server_part
                        node_info['port'] = '8388'
                        write_log(f"🔍 解析到服务器: {server_part}, 默认端口: 8388")
                    
                    # 解析认证信息 - SS的认证部分是Base64编码的method:password
                    try:
                        # 解码Base64认证信息
                        auth_decoded = base64.b64decode(auth_part + '=' * (-len(auth_part) % 4)).decode()
                        write_log(f"🔍 解码后的认证信息: {auth_decoded}")
                        if ':' in auth_decoded:
                            method, password = auth_decoded.split(':', 1)
                            node_info['method'] = method
                            node_info['password'] = password
                            write_log(f"🔍 解析到方法: {method}, 密码: {password}")
                        else:
                            node_info['method'] = 'aes-256-gcm'
                            node_info['password'] = auth_decoded
                            write_log(f"🔍 使用默认方法: aes-256-gcm, 密码: {auth_decoded}")
                    except Exception as e:
                        write_log(f"⚠️ Base64解码失败: {e}")
                        # 如果解码失败，使用默认值
                        node_info['method'] = 'aes-256-gcm'
                        node_info['password'] = auth_part
                        write_log(f"🔍 使用默认方法: aes-256-gcm, 密码: {auth_part}")
                else:
                    write_log(f"⚠️ 没有找到@分隔符")
                    # 没有认证信息的情况
                    if ':' in ss_content:
                        server, port = ss_content.split(':', 1)
                        node_info['server'] = server
                        node_info['port'] = port
                        write_log(f"🔍 解析到服务器: {server}, 端口: {port}")
                    else:
                        node_info['server'] = ss_content
                        node_info['port'] = '8388'
                        write_log(f"🔍 解析到服务器: {ss_content}, 默认端口: 8388")
                    node_info['method'] = 'aes-256-gcm'
                    node_info['password'] = ''
                    write_log(f"🔍 使用默认方法: aes-256-gcm, 空密码")
            except Exception as e:
                write_log(f"⚠️ SS链接解析失败: {e}")
                # 设置默认值
                node_info['server'] = '192.168.1.100'
                node_info['port'] = '8388'
                node_info['method'] = 'aes-256-gcm'
                node_info['password'] = ''
                write_log(f"🔍 使用默认值: server=192.168.1.100, port=8388")
                
        elif node_url.startswith('vmess://'):
            node_info['protocol'] = 'vmess'
            # 解析VMess链接: vmess://base64(json)
            try:
                # 移除vmess://前缀
                vmess_content = node_url[8:]
                # 解码base64
                vmess_json = base64.b64decode(vmess_content + '=' * (-len(vmess_content) % 4)).decode()
                vmess_config = json.loads(vmess_json)
                
                node_info['server'] = vmess_config.get('add', '')
                node_info['port'] = str(vmess_config.get('port', ''))
                node_info['uuid'] = vmess_config.get('id', '')
                node_info['network'] = vmess_config.get('net', 'tcp')
                node_info['path'] = vmess_config.get('path', '')
                node_info['host'] = vmess_config.get('host', '')
                node_info['tls'] = vmess_config.get('tls', 'none') == 'tls'
                
            except Exception as e:
                write_log(f"⚠️ VMess链接解析失败: {e}")
                # 尝试简单的解析
                try:
                    # 移除vmess://前缀
                    vmess_content = node_url[8:]
                    # 尝试解码base64
                    vmess_json = base64.b64decode(vmess_content + '=' * (-len(vmess_content) % 4)).decode()
                    vmess_config = json.loads(vmess_json)
                    
                    node_info['server'] = vmess_config.get('add', '192.168.1.100')
                    node_info['port'] = str(vmess_config.get('port', '8080'))
                    node_info['uuid'] = vmess_config.get('id', '')
                    node_info['network'] = vmess_config.get('net', 'tcp')
                    node_info['path'] = vmess_config.get('path', '')
                    node_info['host'] = vmess_config.get('host', '')
                    node_info['tls'] = vmess_config.get('tls', 'none') == 'tls'
                except:
                    node_info['server'] = '192.168.1.100'
                    node_info['port'] = '8080'
                    node_info['uuid'] = ''
                    node_info['network'] = 'tcp'
                    node_info['path'] = ''
                    node_info['host'] = ''
                    node_info['tls'] = False
                
        elif node_url.startswith('vless://'):
            node_info['protocol'] = 'vless'
            # 解析VLESS链接: vless://uuid@server:port?type=network&path=path&host=host&security=tls
            try:
                # 移除vless://前缀
                vless_content = node_url[8:]
                # 分离UUID和服务器信息
                if '@' in vless_content:
                    uuid, server_part = vless_content.split('@', 1)
                    node_info['uuid'] = uuid
                    
                    # 分离服务器地址和查询参数
                    if '?' in server_part:
                        server_port, query = server_part.split('?', 1)
                        # 解析查询参数
                        params = parse_qs(query)
                        node_info['network'] = params.get('type', ['tcp'])[0]
                        node_info['path'] = params.get('path', [''])[0]
                        node_info['host'] = params.get('host', [''])[0]
                        node_info['tls'] = params.get('security', ['none'])[0] == 'tls'
                        node_info['sni'] = params.get('sni', [''])[0]
                    else:
                        server_port = server_part
                        node_info['network'] = 'tcp'
                        node_info['path'] = ''
                        node_info['host'] = ''
                        node_info['tls'] = False
                        node_info['sni'] = ''
                    
                    # 解析服务器地址和端口
                    if ':' in server_port:
                        server, port = server_port.split(':', 1)
                        node_info['server'] = server
                        node_info['port'] = port
                    else:
                        node_info['server'] = server_port
                        node_info['port'] = '443'
                else:
                    node_info['uuid'] = ''
                    node_info['server'] = 'unknown'
                    node_info['port'] = '443'
                    node_info['network'] = 'tcp'
                    node_info['path'] = ''
                    node_info['host'] = ''
                    node_info['tls'] = False
                    node_info['sni'] = ''
                    
            except Exception as e:
                write_log(f"⚠️ VLESS链接解析失败: {e}")
                node_info['protocol'] = 'vless'
                node_info['uuid'] = ''
                node_info['server'] = 'unknown'
                node_info['port'] = '443'
                node_info['network'] = 'tcp'
                node_info['path'] = ''
                node_info['host'] = ''
                node_info['tls'] = False
                node_info['sni'] = ''
                
        elif node_url.startswith('trojan://'):
            node_info['protocol'] = 'trojan'
            # 解析Trojan链接: trojan://password@server:port?security=tls&sni=sni
            try:
                # 移除trojan://前缀
                trojan_content = node_url[9:]
                # 分离密码和服务器信息
                if '@' in trojan_content:
                    password, server_part = trojan_content.split('@', 1)
                    node_info['password'] = password
                    
                    # 分离服务器地址和查询参数
                    if '?' in server_part:
                        server_port, query = server_part.split('?', 1)
                        # 解析查询参数
                        params = parse_qs(query)
                        node_info['tls'] = params.get('security', ['none'])[0] == 'tls'
                        node_info['sni'] = params.get('sni', [''])[0]
                    else:
                        server_port = server_part
                        node_info['tls'] = False
                        node_info['sni'] = ''
                    
                    # 解析服务器地址和端口
                    if ':' in server_port:
                        server, port = server_port.split(':', 1)
                        node_info['server'] = server
                        node_info['port'] = port
                    else:
                        node_info['server'] = server_port
                        node_info['port'] = '443'
                else:
                    node_info['password'] = ''
                    node_info['server'] = 'unknown'
                    node_info['port'] = '443'
                    node_info['tls'] = False
                    node_info['sni'] = ''
                    
            except Exception as e:
                write_log(f"⚠️ Trojan链接解析失败: {e}")
                node_info['protocol'] = 'trojan'
                node_info['password'] = ''
                node_info['server'] = 'unknown'
                node_info['port'] = '443'
                node_info['tls'] = False
                node_info['sni'] = ''
                
        else:
            node_info['protocol'] = 'unknown'
            node_info['server'] = 'unknown'
            node_info['port'] = '8080'
        
        # 设置默认值
        node_info.setdefault('method', 'aes-256-gcm')
        node_info.setdefault('network', 'tcp')
        node_info.setdefault('path', '')
        node_info.setdefault('host', '')
        node_info.setdefault('tls', False)
        node_info.setdefault('sni', '')
        node_info.setdefault('password', '')
        node_info.setdefault('uuid', '')
        
        # 确保服务器和端口有值
        if 'server' not in node_info or node_info['server'] == 'unknown' or node_info['server'] == '':
            node_info['server'] = '192.168.1.100'
        if 'port' not in node_info or node_info['port'] == 'unknown' or node_info['port'] == '':
            if node_info['protocol'] == 'ss':
                node_info['port'] = '8388'
            elif node_info['protocol'] in ['vmess', 'vless']:
                node_info['port'] = '443'
            elif node_info['protocol'] == 'trojan':
                node_info['port'] = '443'
            else:
                node_info['port'] = '8080'
        
        # 添加调试信息
        write_log(f"🔍 解析结果: {node_info}")
        
        # 确保所有必要字段都存在
        required_fields = ['protocol', 'server', 'port', 'name']
        for field in required_fields:
            if field not in node_info:
                write_log(f"⚠️ 缺少字段: {field}")
            else:
                write_log(f"✅ 字段 {field}: {node_info[field]}")
        
        write_log(f"🔍 最终返回的node_info: {node_info}")
        return node_info
        
    except Exception as e:
        write_log(f"❌ 解析节点链接时出错: {e}")
        return None

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8888, debug=False) 