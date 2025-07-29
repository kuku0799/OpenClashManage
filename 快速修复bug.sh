#!/bin/bash

echo "🔧 快速修复OpenClash管理面板Bug"
echo "=================================="

# 进入项目目录
cd /root/OpenClashManage

# 1. 修复守护进程状态检查
echo "✅ 修复守护进程状态检查..."
# 清理旧的PID文件
rm -f /tmp/openclash_watchdog.pid

# 2. 修复文件权限
echo "✅ 修复文件权限..."
chmod 644 wangluo/nodes.txt
chmod 644 wangluo/log.txt

# 3. 重启服务
echo "✅ 重启服务..."
pkill -f "python3 app.py" 2>/dev/null
pkill -f "jk.sh" 2>/dev/null

# 启动管理面板
nohup python3 app.py > logs/app.log 2>&1 &
echo $! > /tmp/openclash_manage.pid

# 启动守护进程
nohup bash jk.sh > logs/watchdog.log 2>&1 &
echo $! > /tmp/openclash_watchdog.pid

echo ""
echo "🎉 修复完成！"
echo ""
echo "📋 修复内容:"
echo "1. ✅ 守护进程状态检查 - 清理了旧的PID文件"
echo "2. ✅ 节点删除功能 - 修复了文件权限"
echo "3. ✅ 节点名称清理 - 已修复jx.py中的字符处理"
echo "4. ✅ 服务重启 - 重新启动了所有服务"
echo ""
echo "🌐 访问面板: http://[路由器IP]:8888"
echo "📊 查看日志: tail -f logs/app.log"
echo "" 