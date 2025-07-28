#!/bin/bash

# 快速修复脚本 - 从GitHub下载并运行修复

echo "🚀 OpenClash管理面板快速修复"
echo "=============================="
echo ""

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请使用root用户运行此脚本"
    exit 1
fi

# 设置变量
REPO_URL="https://github.com/kuku0799/OpenClashManage.git"
INSTALL_DIR="/root/OpenClashManage"
BACKUP_DIR="/root/OpenClashManage_backup_$(date +%Y%m%d_%H%M%S)"

echo "📥 开始下载最新修复版本..."

# 备份现有安装（如果存在）
if [ -d "$INSTALL_DIR" ]; then
    echo "📦 备份现有安装到: $BACKUP_DIR"
    cp -r "$INSTALL_DIR" "$BACKUP_DIR"
fi

# 下载最新代码
if [ -d "$INSTALL_DIR" ]; then
    echo "🔄 更新现有安装..."
    cd "$INSTALL_DIR"
    git fetch origin
    git reset --hard origin/main
else
    echo "📥 下载新安装..."
    cd /root
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

# 进入安装目录
cd "$INSTALL_DIR"

# 设置权限
echo "🔧 设置脚本权限..."
chmod +x *.sh *.py

# 运行一键修复
echo "🚀 运行一键修复..."
bash 一键修复.sh

echo ""
echo "✅ 快速修复完成！"
echo "📋 使用说明:"
echo "1. 查看监控: tail -f $INSTALL_DIR/logs/monitor.log"
echo "2. 查看日志: tail -f $INSTALL_DIR/wangluo/log.txt"
echo "3. 手动同步: cd $INSTALL_DIR && python3 zr.py"
echo "4. 运行测试: cd $INSTALL_DIR && python3 test_sync.py"
echo "" 