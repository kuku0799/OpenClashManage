#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from flask import Flask, render_template
import os

app = Flask(__name__)

@app.route('/')
def index():
    try:
        # 检查模板文件
        template_path = os.path.join(os.path.dirname(__file__), 'templates', 'index.html')
        if os.path.exists(template_path):
            print(f"✅ 模板文件存在: {template_path}")
        else:
            print(f"❌ 模板文件不存在: {template_path}")
            return "模板文件不存在"
        
        # 简单的测试数据
        nodes_content = "# 测试节点\nss://test@example.com:1234#测试节点"
        log_content = "2024-01-01 12:00:00 测试日志"
        
        print("📄 开始渲染模板")
        return render_template('index.html', nodes_content=nodes_content, log_content=log_content)
    except Exception as e:
        print(f"❌ 渲染失败: {e}")
        import traceback
        return f"渲染失败: {e}<br>详情: {traceback.format_exc()}"

if __name__ == '__main__':
    print("🚀 启动测试服务器...")
    app.run(host='0.0.0.0', port=8888, debug=True) 