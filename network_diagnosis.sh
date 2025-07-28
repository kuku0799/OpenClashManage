#!/bin/bash

echo "🔍 网络诊断工具"
echo "=================="

# 检查当前IP地址
echo "📡 当前网络配置："
echo "本机IP地址："
ip addr show | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | cut -d'/' -f1

echo ""
echo "🌐 网络接口："
ip link show | grep "UP" | awk '{print $2}' | sed 's/://'

echo ""
echo "🔌 检查端口5000是否被占用："
netstat -tlnp | grep :5000 || echo "端口5000未被占用"

echo ""
echo "📊 检查Flask进程："
ps aux | grep python | grep app.py || echo "未找到Flask进程"

echo ""
echo "🌍 测试网络连接："
echo "尝试ping 192.168.5.1..."
ping -c 3 192.168.5.1

echo ""
echo "🔧 建议的访问地址："
echo "1. 如果Flask运行在本机：http://localhost:5000"
echo "2. 如果Flask运行在路由器：http://192.168.5.1:5000"
echo "3. 其他可能的地址："
for ip in $(ip addr show | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | cut -d'/' -f1); do
    echo "   http://$ip:5000"
done

echo ""
echo "💡 故障排除步骤："
echo "1. 确保Flask服务器正在运行"
echo "2. 检查防火墙是否阻止了端口5000"
echo "3. 确认IP地址是否正确"
echo "4. 尝试使用localhost:5000访问" 