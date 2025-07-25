#!/bin/bash

# OpenClash 管理面板启动脚本

# 检查Python3是否安装
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 未安装，请先安装 Python3"
    exit 1
fi

# 检查Flask是否安装
if ! python3 -c "import flask" &> /dev/null; then
    echo "📦 正在安装依赖..."
    pip3 install -r requirements.txt
fi

# 创建必要的目录
mkdir -p /root/OpenClashManage/wangluo
mkdir -p templates

# 检查配置文件
if [ ! -f "/etc/openclash/config.yaml" ]; then
    echo "⚠️ 警告: OpenClash 配置文件不存在"
    echo "请确保 OpenClash 已正确安装"
fi

# 启动Web面板
echo "🚀 启动 OpenClash 管理面板..."
echo "📱 访问地址: http://$(hostname -I | awk '{print $1}'):8080"
echo "⏹️  按 Ctrl+C 停止服务"
echo ""

python3 app.py 