#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
测试OpenClash同步功能
"""

import os
import sys
import subprocess
import time
from datetime import datetime

def log(msg):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{timestamp}] {msg}")

def test_openclash_installation():
    """测试OpenClash是否安装"""
    log("🔍 测试OpenClash安装状态...")
    result = subprocess.run("opkg list-installed | grep openclash", shell=True, capture_output=True, text=True)
    if result.returncode == 0:
        log("✅ OpenClash已安装")
        return True
    else:
        log("❌ OpenClash未安装")
        return False

def test_config_path():
    """测试配置文件路径"""
    log("🔍 测试配置文件路径...")
    result = subprocess.run("uci get openclash.config.config_path", shell=True, capture_output=True, text=True)
    if result.returncode == 0:
        config_path = result.stdout.strip()
        log(f"✅ 配置文件路径: {config_path}")
        
        if os.path.exists(config_path):
            log("✅ 配置文件存在")
            return True
        else:
            log("❌ 配置文件不存在")
            return False
    else:
        log("❌ 无法获取配置文件路径")
        return False

def test_python_dependencies():
    """测试Python依赖"""
    log("🔍 测试Python依赖...")
    dependencies = ["ruamel.yaml", "requests"]
    
    for dep in dependencies:
        try:
            __import__(dep)
            log(f"✅ {dep} 已安装")
        except ImportError:
            log(f"❌ {dep} 未安装")
            return False
    
    return True

def test_script_files():
    """测试脚本文件"""
    log("🔍 测试脚本文件...")
    scripts = [
        "/root/OpenClashManage/zr.py",
        "/root/OpenClashManage/jx.py", 
        "/root/OpenClashManage/zw.py",
        "/root/OpenClashManage/zc.py",
        "/root/OpenClashManage/jk.sh"
    ]
    
    for script in scripts:
        if os.path.exists(script):
            log(f"✅ {script} 存在")
        else:
            log(f"❌ {script} 不存在")
            return False
    
    return True

def test_nodes_file():
    """测试节点文件"""
    log("🔍 测试节点文件...")
    nodes_file = "/root/OpenClashManage/wangluo/nodes.txt"
    
    if os.path.exists(nodes_file):
        log("✅ 节点文件存在")
        
        with open(nodes_file, 'r', encoding='utf-8') as f:
            content = f.read()
            lines = [line.strip() for line in content.split('\n') if line.strip() and not line.startswith('#')]
            log(f"✅ 节点文件中有 {len(lines)} 个有效节点")
            return True
    else:
        log("❌ 节点文件不存在")
        return False

def test_manual_sync():
    """测试手动同步"""
    log("🔍 测试手动同步...")
    
    # 切换到项目目录
    os.chdir("/root/OpenClashManage")
    
    # 运行同步脚本
    result = subprocess.run("python3 zr.py", shell=True, capture_output=True, text=True)
    
    if result.returncode == 0:
        log("✅ 手动同步成功")
        return True
    else:
        log("❌ 手动同步失败")
        log(f"错误输出: {result.stderr}")
        return False

def test_watchdog():
    """测试守护进程"""
    log("🔍 测试守护进程...")
    
    # 检查PID文件
    pid_file = "/tmp/openclash_watchdog.pid"
    if os.path.exists(pid_file):
        with open(pid_file, 'r') as f:
            pid = f.read().strip()
        log(f"🔍 守护进程PID: {pid}")
        
        # 检查进程是否运行
        result = subprocess.run(f"ps -p {pid}", shell=True, capture_output=True)
        if result.returncode == 0:
            log("✅ 守护进程正在运行")
            return True
        else:
            log("❌ 守护进程未运行")
            return False
    else:
        log("❌ 守护进程PID文件不存在")
        return False

def main():
    """主测试函数"""
    log("🚀 开始测试OpenClash同步功能...")
    
    tests = [
        ("OpenClash安装", test_openclash_installation),
        ("配置文件路径", test_config_path),
        ("Python依赖", test_python_dependencies),
        ("脚本文件", test_script_files),
        ("节点文件", test_nodes_file),
        ("手动同步", test_manual_sync),
        ("守护进程", test_watchdog)
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        log(f"\n{'='*50}")
        log(f"测试: {test_name}")
        log(f"{'='*50}")
        
        try:
            if test_func():
                passed += 1
                log(f"✅ {test_name} 测试通过")
            else:
                log(f"❌ {test_name} 测试失败")
        except Exception as e:
            log(f"❌ {test_name} 测试异常: {e}")
    
    log(f"\n{'='*50}")
    log(f"测试总结: {passed}/{total} 通过")
    log(f"{'='*50}")
    
    if passed == total:
        log("🎉 所有测试通过！")
        return True
    else:
        log("⚠️ 部分测试失败，请检查问题")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1) 