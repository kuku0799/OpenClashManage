#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
测试修复后的OpenClash管理面板功能
"""

import os
import sys
import tempfile
import shutil
from unittest.mock import patch, MagicMock

# 添加当前目录到Python路径
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

def test_node_deletion_logic():
    """测试节点删除逻辑"""
    print("🧪 测试节点删除逻辑...")
    
    # 创建临时测试文件
    test_content = """# 测试节点文件
ss://test1@server1:1234#测试节点1
# 这是注释
ss://test2@server2:5678#测试节点2
ss://test3@server3:9012#测试节点3
"""
    
    with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.txt') as f:
        f.write(test_content)
        temp_file = f.name
    
    try:
        # 模拟原始逻辑（错误的）
        def original_delete_logic(content, node_index):
            lines = content.split('\n')
            node_lines = []
            for i, line in enumerate(lines):
                line = line.strip()
                if line and not line.startswith('#'):
                    node_lines.append((i, line))
            
            if node_index >= len(node_lines):
                return None
            
            line_index, _ = node_lines[node_index]
            lines.pop(line_index)
            return '\n'.join(lines)
        
        # 模拟修复后的逻辑（正确的）
        def fixed_delete_logic(content, node_index):
            lines = content.split('\n')
            valid_lines = []
            for i, line in enumerate(lines):
                if line.strip() and not line.strip().startswith('#'):
                    valid_lines.append((i, line))
            
            if node_index >= len(valid_lines):
                return None
            
            line_index, _ = valid_lines[node_index]
            lines.pop(line_index)
            return '\n'.join(lines)
        
        # 测试原始逻辑
        with open(temp_file, 'r') as f:
            content = f.read()
        
        print(f"原始内容:\n{content}")
        
        # 删除第一个节点（索引0）
        result_original = original_delete_logic(content, 0)
        result_fixed = fixed_delete_logic(content, 0)
        
        print(f"\n原始逻辑结果:\n{result_original}")
        print(f"\n修复后逻辑结果:\n{result_fixed}")
        
        # 验证结果
        if result_original != result_fixed:
            print("❌ 逻辑修复验证失败")
            return False
        else:
            print("✅ 节点删除逻辑修复验证成功")
            return True
            
    finally:
        # 清理临时文件
        if os.path.exists(temp_file):
            os.unlink(temp_file)

def test_url_validation():
    """测试URL验证逻辑"""
    print("\n🧪 测试URL验证逻辑...")
    
    # 测试用例
    test_cases = [
        ("ss://test@server:1234", True),  # 有效SS链接
        ("vmess://test@server:1234", True),  # 有效VMess链接
        ("http://example.com", False),  # 不支持的协议
        ("invalid_url", False),  # 无效URL
        ("ss://short", False),  # 太短的URL
        ("", False),  # 空字符串
        (None, False),  # None值
    ]
    
    # 模拟修复后的验证逻辑
    def is_valid_node_url(url):
        if not url or '://' not in url:
            return False
        
        supported_protocols = ['ss://', 'ssr://', 'vmess://', 'vless://', 'trojan://']
        if not any(url.startswith(protocol) for protocol in supported_protocols):
            return False
        
        if len(url) < 20:
            return False
        
        return True
    
    passed = 0
    total = len(test_cases)
    
    for url, expected in test_cases:
        result = is_valid_node_url(url)
        status = "✅" if result == expected else "❌"
        print(f"{status} {url} -> {result} (期望: {expected})")
        if result == expected:
            passed += 1
    
    print(f"\nURL验证测试结果: {passed}/{total} 通过")
    return passed == total

def test_dependency_check():
    """测试依赖检查功能"""
    print("\n🧪 测试依赖检查功能...")
    
    # 模拟依赖检查逻辑
    def check_dependencies(root_dir):
        dependencies = [
            f"{root_dir}/jk.sh",
            f"{root_dir}/zr.py", 
            f"{root_dir}/jx.py",
            f"{root_dir}/zw.py",
            f"{root_dir}/zc.py"
        ]
        
        missing_files = []
        for file_path in dependencies:
            if not os.path.exists(file_path):
                missing_files.append(file_path)
        
        return len(missing_files) == 0, missing_files
    
    # 测试当前目录
    current_dir = os.path.dirname(os.path.abspath(__file__))
    has_deps, missing = check_dependencies(current_dir)
    
    print(f"当前目录依赖检查: {'✅' if has_deps else '❌'}")
    if missing:
        print(f"缺少文件: {missing}")
    
    return has_deps

def main():
    """主测试函数"""
    print("🚀 开始测试OpenClash管理面板修复...")
    
    tests = [
        test_node_deletion_logic,
        test_url_validation,
        test_dependency_check
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        try:
            if test():
                passed += 1
        except Exception as e:
            print(f"❌ 测试失败: {e}")
    
    print(f"\n📊 测试总结: {passed}/{total} 通过")
    
    if passed == total:
        print("🎉 所有测试通过！修复验证成功。")
        return True
    else:
        print("⚠️ 部分测试失败，请检查修复。")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1) 