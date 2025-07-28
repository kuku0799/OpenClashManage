# GitHub仓库设置脚本 (PowerShell版本)
# 用于配置GitHub远程仓库和推送代码

Write-Host "🚀 设置GitHub仓库..." -ForegroundColor Green

# 获取GitHub用户名
$GITHUB_USERNAME = Read-Host "请输入您的GitHub用户名"

if ([string]::IsNullOrEmpty($GITHUB_USERNAME)) {
    Write-Host "❌ 用户名不能为空" -ForegroundColor Red
    return
}

# 仓库名称
$REPO_NAME = "OpenClashManage"

# 设置远程仓库
Write-Host "📝 设置远程仓库..." -ForegroundColor Yellow
git remote add origin "https://github.com/$GITHUB_USERNAME/$REPO_NAME.git"

# 推送代码
Write-Host "📤 推送代码到GitHub..." -ForegroundColor Yellow
git branch -M main
git push -u origin main

Write-Host "✅ 代码已推送到GitHub!" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 仓库地址: https://github.com/$GITHUB_USERNAME/$REPO_NAME" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 一键部署链接:" -ForegroundColor Yellow
Write-Host "wget -O - https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME/main/一键部署.sh | sh" -ForegroundColor White
Write-Host ""
Write-Host "🔧 手动安装链接:" -ForegroundColor Yellow
Write-Host "wget https://raw.githubusercontent.com/$GITHUB_USERNAME/$REPO_NAME/main/install_openwrt.sh" -ForegroundColor White
Write-Host "chmod +x install_openwrt.sh" -ForegroundColor White
Write-Host "./install_openwrt.sh install" -ForegroundColor White 