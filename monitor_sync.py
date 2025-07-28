#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
实时监控OpenClash同步流程
从添加节点到注入策略组的完整监控
"""

import os
import time
import subprocess
import threading
from datetime import datetime
import hashlib

class SyncMonitor:
    def __init__(self):
        self.nodes_file = "/root/OpenClashManage/wangluo/nodes.txt"
        self.log_file = "/root/OpenClashManage/wangluo/log.txt"
        self.last_nodes_hash = ""
        self.last_log_size = 0
        self.monitoring = False
        
    def log(self, msg):
        """输出日志"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"[{timestamp}] {msg}")
        
    def get_file_hash(self, file_path):
        """获取文件MD5哈希"""
        try:
            with open(file_path, 'rb') as f:
                return hashlib.md5(f.read()).hexdigest()
        except:
            return ""
            
    def get_file_size(self, file_path):
        """获取文件大小"""
        try:
            return os.path.getsize(file_path)
        except:
            return 0
            
    def read_log_tail(self, lines=10):
        """读取日志文件尾部"""
        try:
            with open(self.log_file, 'r', encoding='utf-8') as f:
                all_lines = f.readlines()
                return ''.join(all_lines[-lines:])
        except:
            return ""
            
    def check_openclash_status(self):
        """检查OpenClash状态"""
        try:
            result = subprocess.run("pgrep -f 'openclash'", shell=True, capture_output=True, text=True)
            return result.returncode == 0
        except:
            return False
            
    def check_watchdog_status(self):
        """检查守护进程状态"""
        pid_file = "/tmp/openclash_watchdog.pid"
        if os.path.exists(pid_file):
            try:
                with open(pid_file, 'r') as f:
                    pid = f.read().strip()
                result = subprocess.run(f"ps -p {pid}", shell=True, capture_output=True)
                return result.returncode == 0
            except:
                pass
        return False
        
    def monitor_nodes_file(self):
        """监控节点文件变化"""
        current_hash = self.get_file_hash(self.nodes_file)
        
        if current_hash != self.last_nodes_hash:
            if self.last_nodes_hash:  # 不是第一次运行
                self.log("🔄 检测到节点文件变化")
                self.log(f"🔍 文件哈希: {self.last_nodes_hash} -> {current_hash}")
                
                # 读取节点文件内容
                try:
                    with open(self.nodes_file, 'r', encoding='utf-8') as f:
                        content = f.read()
                    lines = [line.strip() for line in content.split('\n') if line.strip() and not line.startswith('#')]
                    self.log(f"📊 当前节点数量: {len(lines)}")
                except Exception as e:
                    self.log(f"❌ 读取节点文件失败: {e}")
                    
            self.last_nodes_hash = current_hash
            
    def monitor_log_file(self):
        """监控日志文件变化"""
        current_size = self.get_file_size(self.log_file)
        
        if current_size != self.last_log_size:
            if self.last_log_size:  # 不是第一次运行
                self.log("📝 检测到日志文件变化")
                
                # 读取新的日志内容
                new_log = self.read_log_tail(5)
                if new_log:
                    self.log("📋 最新日志:")
                    for line in new_log.strip().split('\n'):
                        if line.strip():
                            self.log(f"   {line}")
                            
            self.last_log_size = current_size
            
    def monitor_sync_process(self):
        """监控同步进程"""
        # 检查是否有zr.py进程在运行
        try:
            result = subprocess.run("pgrep -f 'zr.py'", shell=True, capture_output=True, text=True)
            if result.returncode == 0:
                self.log("⚡ 检测到同步进程正在运行")
        except:
            pass
            
    def check_system_status(self):
        """检查系统状态"""
        # 检查OpenClash状态
        openclash_running = self.check_openclash_status()
        watchdog_running = self.check_watchdog_status()
        
        status_msg = []
        status_msg.append(f"OpenClash: {'🟢 运行中' if openclash_running else '🔴 未运行'}")
        status_msg.append(f"守护进程: {'🟢 运行中' if watchdog_running else '🔴 未运行'}")
        
        # 检查配置文件
        config_path = ""
        try:
            result = subprocess.run("uci get openclash.config.config_path", shell=True, capture_output=True, text=True)
            if result.returncode == 0:
                config_path = result.stdout.strip()
                if os.path.exists(config_path):
                    status_msg.append(f"配置文件: 🟢 存在")
                else:
                    status_msg.append(f"配置文件: 🔴 不存在")
            else:
                status_msg.append(f"配置文件: 🔴 无法获取路径")
        except:
            status_msg.append(f"配置文件: 🔴 检查失败")
            
        return status_msg
        
    def start_monitoring(self):
        """开始监控"""
        self.log("🚀 开始监控OpenClash同步流程...")
        self.log("📊 监控项目:")
        self.log("   - 节点文件变化")
        self.log("   - 日志文件更新")
        self.log("   - 同步进程状态")
        self.log("   - 系统服务状态")
        self.log("   - 配置文件状态")
        self.log("")
        
        self.monitoring = True
        
        # 初始化状态
        self.last_nodes_hash = self.get_file_hash(self.nodes_file)
        self.last_log_size = self.get_file_size(self.log_file)
        
        try:
            while self.monitoring:
                # 监控节点文件
                self.monitor_nodes_file()
                
                # 监控日志文件
                self.monitor_log_file()
                
                # 监控同步进程
                self.monitor_sync_process()
                
                # 每10秒检查一次系统状态
                if int(time.time()) % 10 == 0:
                    status = self.check_system_status()
                    if status:
                        self.log("📊 系统状态:")
                        for s in status:
                            self.log(f"   {s}")
                        self.log("")
                
                time.sleep(1)
                
        except KeyboardInterrupt:
            self.log("⏹️ 监控已停止")
        except Exception as e:
            self.log(f"❌ 监控异常: {e}")
            
    def stop_monitoring(self):
        """停止监控"""
        self.monitoring = False

def main():
    """主函数"""
    monitor = SyncMonitor()
    
    print("🔍 OpenClash同步流程监控器")
    print("=" * 50)
    print("监控内容:")
    print("1. 节点文件变化检测")
    print("2. 日志文件实时更新")
    print("3. 同步进程状态")
    print("4. OpenClash服务状态")
    print("5. 守护进程状态")
    print("6. 配置文件状态")
    print("")
    print("按 Ctrl+C 停止监控")
    print("=" * 50)
    print("")
    
    try:
        monitor.start_monitoring()
    except KeyboardInterrupt:
        print("\n⏹️ 监控已停止")

if __name__ == "__main__":
    main() 