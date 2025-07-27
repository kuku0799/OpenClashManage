#!/bin/bash

# OpenWrt软件源完整配置脚本
# 适用于OpenClash管理面板安装

echo "🔧 配置OpenWrt软件源..."
echo "=========================="

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo "❌ 请使用root权限运行此脚本"
    exit 1
fi

# 备份原配置文件
echo "📦 备份原配置文件..."
cp /etc/opkg/customfeeds.conf /etc/opkg/customfeeds.conf.bak 2>/dev/null || true

# 创建新的软件源配置
echo "📝 创建软件源配置..."
cat > /etc/opkg/customfeeds.conf << 'EOF'
# OpenWrt软件源配置
# 使用清华大学镜像源（推荐）

# 核心软件包
src/gz openwrt_core https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/23.05.3/packages/x86_64/core
src/gz openwrt_base https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/23.05.3/packages/x86_64/base
src/gz openwrt_luci https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/23.05.3/packages/x86_64/luci
src/gz openwrt_packages https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/23.05.3/packages/x86_64/packages
src/gz openwrt_routing https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/23.05.3/packages/x86_64/routing
src/gz openwrt_telephony https://mirrors.tuna.tsinghua.edu.cn/openwrt/releases/23.05.3/packages/x86_64/telephony

# kenzo8软件源（包含OpenClash）
src/gz kenzo https://op.supes.top/packages/x86_64
src/gz kenzo_luci https://op.supes.top/luci/x86_64
EOF

# 更新软件包列表
echo "📦 更新软件包列表..."
opkg update

# 安装OpenClash
echo "📦 安装OpenClash..."
opkg install luci-app-openclash

# 安装Python相关软件包
echo "📦 安装Python相关软件包..."
opkg install python3 python3-pip python3-flask python3-yaml python3-requests

# 安装其他必要软件包
echo "📦 安装其他必要软件包..."
opkg install git wget curl

echo ""
echo "✅ 软件源配置完成！"
echo "================================================"
echo "📦 已安装的软件包："
echo "  - OpenClash"
echo "  - Python3及相关依赖"
echo "  - Git, Wget, Curl"
echo ""
echo "🚀 现在可以运行安装脚本："
echo "  bash install_openwrt_complete.sh" 