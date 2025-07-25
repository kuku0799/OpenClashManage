# OpenClash管理面板 - GitHub上传脚本
# 使用方法: .\upload_to_github.ps1

param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubUsername,
    
    [Parameter(Mandatory=$false)]
    [string]$RepositoryName = "OpenClashManage"
)

Write-Host "🚀 OpenClash管理面板 - GitHub上传脚本" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

# 检查Git是否安装
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Git未安装，请先安装Git" -ForegroundColor Red
    exit 1
}

# 检查当前目录是否为Git仓库
if (-not (Test-Path ".git")) {
    Write-Host "❌ 当前目录不是Git仓库" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Git环境检查通过" -ForegroundColor Green

# 检查是否有未提交的更改
$status = git status --porcelain
if ($status) {
    Write-Host "⚠️  发现未提交的更改，正在提交..." -ForegroundColor Yellow
    git add .
    git commit -m "Update files before GitHub upload"
}

# 设置远程仓库
$remoteUrl = "https://github.com/$GitHubUsername/$RepositoryName.git"
Write-Host "📡 设置远程仓库: $remoteUrl" -ForegroundColor Blue

# 移除现有的origin（如果存在）
git remote remove origin 2>$null

# 添加新的origin
git remote add origin $remoteUrl

# 重命名分支为main
git branch -M main

# 推送到GitHub
Write-Host "📤 正在推送到GitHub..." -ForegroundColor Blue
try {
    git push -u origin main
    Write-Host "✅ 代码上传成功！" -ForegroundColor Green
} catch {
    Write-Host "❌ 上传失败: $_" -ForegroundColor Red
    exit 1
}

# 更新安装脚本中的仓库地址
Write-Host "🔧 更新安装脚本中的仓库地址..." -ForegroundColor Blue
$installScriptPath = "install.sh"
if (Test-Path $installScriptPath) {
    $content = Get-Content $installScriptPath -Raw
    $content = $content -replace "GITHUB_REPO=`"https://raw\.githubusercontent\.com/OpenClashManage/OpenClashManage/main`"", "GITHUB_REPO=`"https://raw.githubusercontent.com/$GitHubUsername/$RepositoryName/main`""
    Set-Content $installScriptPath $content -Encoding UTF8
    
    # 提交更新
    git add $installScriptPath
    git commit -m "Update GitHub repository URL in install script"
    git push
    
    Write-Host "✅ 安装脚本已更新" -ForegroundColor Green
}

# 显示结果
Write-Host ""
Write-Host "🎉 上传完成！" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host "📱 项目地址: https://github.com/$GitHubUsername/$RepositoryName" -ForegroundColor Cyan
Write-Host "🔗 一键安装: curl -sSL https://raw.githubusercontent.com/$GitHubUsername/$RepositoryName/main/install.sh | sudo bash" -ForegroundColor Cyan
Write-Host "📦 下载地址: https://github.com/$GitHubUsername/$RepositoryName/archive/main.zip" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 下一步操作:" -ForegroundColor Yellow
Write-Host "1. 访问项目地址确认文件已上传" -ForegroundColor White
Write-Host "2. 测试一键安装命令" -ForegroundColor White
Write-Host "3. 分享项目链接给其他用户" -ForegroundColor White
Write-Host "" 