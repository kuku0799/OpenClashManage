# OpenClash管理面板 - 自动化上传脚本
# 使用方法: .\auto_upload.ps1 -Username "your-github-username"

param(
    [Parameter(Mandatory=$true)]
    [string]$Username,
    
    [Parameter(Mandatory=$false)]
    [string]$RepoName = "OpenClashManage"
)

Write-Host "🚀 OpenClash管理面板 - 自动化上传" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

# 检查Git状态
Write-Host "📋 检查Git状态..." -ForegroundColor Blue
$status = git status --porcelain
if ($status) {
    Write-Host "⚠️  发现未提交的更改，正在提交..." -ForegroundColor Yellow
    git add .
    git commit -m "Auto commit before upload"
}

# 设置远程仓库
$remoteUrl = "https://github.com/$Username/$RepoName.git"
Write-Host "📡 设置远程仓库: $remoteUrl" -ForegroundColor Blue

# 移除现有origin并添加新的
git remote remove origin 2>$null
git remote add origin $remoteUrl

# 重命名分支并推送
git branch -M main
Write-Host "📤 正在推送到GitHub..." -ForegroundColor Blue

try {
    git push -u origin main
    Write-Host "✅ 代码上传成功！" -ForegroundColor Green
} catch {
    Write-Host "❌ 上传失败，请检查:" -ForegroundColor Red
    Write-Host "1. GitHub用户名是否正确" -ForegroundColor Yellow
    Write-Host "2. 是否已在GitHub上创建仓库" -ForegroundColor Yellow
    Write-Host "3. 网络连接是否正常" -ForegroundColor Yellow
    exit 1
}

# 更新安装脚本
Write-Host "🔧 更新安装脚本..." -ForegroundColor Blue
$installContent = Get-Content "install.sh" -Raw
$installContent = $installContent -replace 'GITHUB_REPO="https://raw\.githubusercontent\.com/OpenClashManage/OpenClashManage/main"', "GITHUB_REPO=`"https://raw.githubusercontent.com/$Username/$RepoName/main`""
Set-Content "install.sh" $installContent -Encoding UTF8

# 提交更新
git add install.sh
git commit -m "Update repository URL in install script"
git push

Write-Host ""
Write-Host "🎉 上传完成！" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host "📱 项目地址: https://github.com/$Username/$RepoName" -ForegroundColor Cyan
Write-Host "🔗 一键安装: curl -sSL https://raw.githubusercontent.com/$Username/$RepoName/main/install.sh | sudo bash" -ForegroundColor Cyan
Write-Host "📦 下载地址: https://github.com/$Username/$RepoName/archive/main.zip" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 下一步:" -ForegroundColor Yellow
Write-Host "1. 访问项目地址确认上传成功" -ForegroundColor White
Write-Host "2. 测试一键安装命令" -ForegroundColor White
Write-Host "3. 分享给其他用户" -ForegroundColor White 