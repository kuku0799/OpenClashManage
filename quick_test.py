#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import subprocess
import time
import webbrowser

def check_dependencies():
    """检查依赖是否安装"""
    print("🔍 检查依赖...")
    
    try:
        import flask
        print("✅ Flask 已安装")
    except ImportError:
        print("❌ Flask 未安装，请运行: pip install flask")
        return False
    
    try:
        import ruamel.yaml
        print("✅ ruamel.yaml 已安装")
    except ImportError:
        print("❌ ruamel.yaml 未安装，请运行: pip install ruamel.yaml")
        return False
    
    return True

def check_files():
    """检查必要文件是否存在"""
    print("\n📁 检查文件...")
    
    required_files = [
        'app.py',
        'jx.py',
        'zw.py',
        'zc.py',
        'log.py',
        'templates/index.html',
        'wangluo/nodes.txt'
    ]
    
    for file in required_files:
        if os.path.exists(file):
            print(f"✅ {file}")
        else:
            print(f"❌ {file} 不存在")
            return False
    
    return True

def start_server():
    """启动Flask服务器"""
    print("\n🚀 启动Web服务器...")
    
    try:
        # 启动Flask应用
        process = subprocess.Popen([sys.executable, 'app.py'], 
                                 stdout=subprocess.PIPE, 
                                 stderr=subprocess.PIPE)
        
        # 等待服务器启动
        time.sleep(3)
        
        # 检查进程是否还在运行
        if process.poll() is None:
            print("✅ 服务器启动成功")
            print("🌐 访问地址: http://localhost:8888")
            return process
        else:
            stdout, stderr = process.communicate()
            print(f"❌ 服务器启动失败:")
            print(f"错误信息: {stderr.decode()}")
            return None
            
    except Exception as e:
        print(f"❌ 启动服务器时出错: {e}")
        return None

def open_browser():
    """打开浏览器"""
    print("\n🌐 打开浏览器...")
    try:
        webbrowser.open('http://localhost:8888')
        print("✅ 浏览器已打开")
    except Exception as e:
        print(f"❌ 无法自动打开浏览器: {e}")
        print("请手动访问: http://localhost:8888")

def run_quick_tests():
    """运行快速测试"""
    print("\n🧪 运行快速测试...")
    
    # 测试1: 检查节点文件
    try:
        with open('wangluo/nodes.txt', 'r', encoding='utf-8') as f:
            content = f.read()
            lines = [line.strip() for line in content.split('\n') if line.strip() and not line.strip().startswith('#')]
            print(f"✅ 节点文件检查: 找到 {len(lines)} 个节点")
    except Exception as e:
        print(f"❌ 节点文件检查失败: {e}")
    
    # 测试2: 检查模板文件
    try:
        with open('templates/index.html', 'r', encoding='utf-8') as f:
            content = f.read()
            if 'nodeEditModal' in content:
                print("✅ 编辑对话框模板检查通过")
            else:
                print("❌ 编辑对话框模板未找到")
    except Exception as e:
        print(f"❌ 模板文件检查失败: {e}")
    
    # 测试3: 检查API接口
    print("✅ API接口检查: 需要手动测试")

def main():
    """主函数"""
    print("🧪 OpenClash 节点编辑功能快速测试")
    print("=" * 50)
    
    # 检查依赖
    if not check_dependencies():
        print("\n❌ 依赖检查失败，请安装缺失的包")
        return
    
    # 检查文件
    if not check_files():
        print("\n❌ 文件检查失败，请确保所有必要文件存在")
        return
    
    # 运行快速测试
    run_quick_tests()
    
    # 启动服务器
    process = start_server()
    if process:
        # 打开浏览器
        open_browser()
        
        print("\n🎯 测试指南:")
        print("1. 在浏览器中访问 http://localhost:8888")
        print("2. 添加一些测试节点")
        print("3. 切换到'节点列表'选项卡")
        print("4. 点击节点右侧的'编辑'按钮测试单个编辑")
        print("5. 选择多个节点后点击工具栏的'编辑'按钮测试批量编辑")
        print("6. 测试各种编辑功能")
        
        print("\n⏹️  按 Ctrl+C 停止服务器")
        
        try:
            process.wait()
        except KeyboardInterrupt:
            print("\n🛑 正在停止服务器...")
            process.terminate()
            process.wait()
            print("✅ 服务器已停止")
    else:
        print("\n❌ 无法启动服务器，请检查错误信息")

if __name__ == "__main__":
    main() 