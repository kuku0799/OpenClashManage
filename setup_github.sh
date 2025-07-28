#!/bin/bash

# GitHub仓库设置脚本
# 用于配置GitHub远程仓库和推送代码

echo "🚀 设置GitHub仓库..."

# 获取GitHub用户名
read -p "请输入您的GitHub用户名: " GITHUB_USERNAME

if [ -z "$GITHUB_USERNAME" ]; then
    echo "❌ 用户名不能为空"
    exit 1
fi

# 仓库名称
REPO_NAME="OpenClashManage"

# 设置远程仓库
echo "📝 设置远程仓库..."
git remote add origin https://github.com/$GITHUB_USERNAME/$REPO_NAME.git

# 推送代码
echo "📤 推送代码到GitHub..."
git branch -M main
git push -u origin main

echo "✅ 代码已推送到GitHub!"
echo ""
echo "🌐 仓库地址: https://github.com/$GITHUB_USERNAME/$REPO_NAME"
echo ""
echo "📋 一键部署链接:"
echo "wget -O - https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME/main/一键部署.sh | sh"
echo ""
echo "🔧 手动安装链接:"
echo "wget https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME/main/install_openwrt.sh"
echo "chmod +x install_openwrt.sh"
echo "./install_openwrt.sh install" 