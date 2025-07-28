#!/bin/bash

# OpenClash同步监控启动脚本

ROOT_DIR="/root/OpenClashManage"
LOG_FILE="$ROOT_DIR/wangluo/log.txt"

echo "🔍 OpenClash同步流程监控器"
echo "================================"
echo ""

# 检查Python环境
echo "🔍 检查Python环境..."
if command -v python3 &> /dev/null; then
    echo "✅ Python3 已安装"
else
    echo "❌ Python3 未安装"
    exit 1
fi

# 检查项目目录
echo "🔍 检查项目目录..."
if [ -d "$ROOT_DIR" ]; then
    echo "✅ 项目目录存在: $ROOT_DIR"
else
    echo "❌ 项目目录不存在: $ROOT_DIR"
    exit 1
fi

# 检查监控脚本
echo "🔍 检查监控脚本..."
if [ -f "$ROOT_DIR/monitor_sync.py" ]; then
    echo "✅ 监控脚本存在"
else
    echo "❌ 监控脚本不存在"
    exit 1
fi

# 检查测试脚本
echo "🔍 检查测试脚本..."
if [ -f "$ROOT_DIR/test_sync.py" ]; then
    echo "✅ 测试脚本存在"
else
    echo "❌ 测试脚本不存在"
    exit 1
fi

echo ""
echo "📊 可用的监控选项:"
echo "1. 运行完整测试 (test_sync.py)"
echo "2. 启动实时监控 (monitor_sync.py)"
echo "3. 手动执行同步 (zr.py)"
echo "4. 启动守护进程 (jk.sh)"
echo "5. 查看最新日志"
echo ""

read -p "请选择操作 (1-5): " choice

case $choice in
    1)
        echo "🚀 运行完整测试..."
        cd "$ROOT_DIR"
        python3 test_sync.py
        ;;
    2)
        echo "🚀 启动实时监控..."
        cd "$ROOT_DIR"
        python3 monitor_sync.py
        ;;
    3)
        echo "🚀 手动执行同步..."
        cd "$ROOT_DIR"
        python3 zr.py
        ;;
    4)
        echo "🚀 启动守护进程..."
        cd "$ROOT_DIR"
        bash jk.sh &
        echo "✅ 守护进程已启动 (PID: $!)"
        ;;
    5)
        echo "📋 最新日志:"
        if [ -f "$LOG_FILE" ]; then
            tail -n 20 "$LOG_FILE"
        else
            echo "❌ 日志文件不存在"
        fi
        ;;
    *)
        echo "❌ 无效选择"
        exit 1
        ;;
esac 