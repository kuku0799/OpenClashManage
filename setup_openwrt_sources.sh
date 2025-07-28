#!/bin/bash

# OpenWrt软件源配置脚本
# 适用于OpenClash管理面板安装

echo "🚀 配置OpenWrt软件源..."

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

# 第三方软件源
src/gz kenzok8 https://github.com/kenzok8/openwrt-packages
src/gz kenzok8_small https://github.com/kenzok8/small
EOF

# 更新软件包列表
echo "🔄 更新软件包列表..."
opkg update

# 安装基础依赖
echo "📦 安装基础依赖..."
opkg install python3 python3-pip python3-flask python3-yaml python3-requests
opkg install git wget curl ca-bundle ca-certificates

# 安装Python依赖
echo "🐍 安装Python依赖..."
pip3 install flask==2.3.3
pip3 install ruamel.yaml==0.18.5
pip3 install requests==2.31.0

echo "✅ 软件源配置完成！"
echo ""
echo "📋 已配置的软件源："
echo "  - 清华大学镜像源（官方软件包）"
echo "  - kenzok8软件源（第三方软件包）"
echo ""
echo "📦 已安装的依赖："
echo "  - Python3及相关包"
echo "  - Flask Web框架"
echo "  - ruamel.yaml YAML处理"
echo "  - requests HTTP库"
echo ""
echo "🚀 现在可以安装OpenClash管理面板了！"
echo "运行: bash install_openwrt.sh" 