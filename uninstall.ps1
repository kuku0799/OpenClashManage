# OpenClashManage Windows 卸载脚本
# 用于完全移除OpenClashManage服务

param(
    [switch]$Force
)

# 颜色定义
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Blue = "Blue"

# 打印函数
function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor $Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor $Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor $Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor $Blue
}

# 停止服务
function Stop-OpenClashManageService {
    Write-Info "正在停止OpenClashManage服务..."
    
    try {
        $service = Get-Service -Name "openclash-manage" -ErrorAction SilentlyContinue
        if ($service) {
            Stop-Service -Name "openclash-manage" -Force
            Write-Success "已停止OpenClashManage服务"
        } else {
            Write-Info "未找到OpenClashManage服务"
        }
    } catch {
        Write-Warning "停止服务时出错: $($_.Exception.Message)"
    }
}

# 删除服务
function Remove-OpenClashManageService {
    Write-Info "正在删除OpenClashManage服务..."
    
    try {
        $service = Get-Service -Name "openclash-manage" -ErrorAction SilentlyContinue
        if ($service) {
            sc.exe delete "openclash-manage"
            Write-Success "已删除OpenClashManage服务"
        } else {
            Write-Info "未找到OpenClashManage服务"
        }
    } catch {
        Write-Warning "删除服务时出错: $($_.Exception.Message)"
    }
}

# 删除应用文件
function Remove-OpenClashManageFiles {
    Write-Info "正在删除应用文件..."
    
    $paths = @(
        "C:\opt\openclash-manage",
        "C:\Program Files\openclash-manage",
        "C:\Program Files (x86)\openclash-manage",
        "$env:USERPROFILE\openclash-manage",
        "$env:LOCALAPPDATA\openclash-manage"
    )
    
    foreach ($path in $paths) {
        if (Test-Path $path) {
            try {
                Remove-Item -Path $path -Recurse -Force
                Write-Success "已删除目录: $path"
            } catch {
                Write-Warning "删除目录失败: $path - $($_.Exception.Message)"
            }
        }
    }
}

# 删除日志文件
function Remove-OpenClashManageLogs {
    Write-Info "正在删除日志文件..."
    
    $logPaths = @(
        "C:\var\log\openclash-manage.log",
        "C:\tmp\openclash-manage.log",
        "$env:TEMP\openclash-manage.log"
    )
    
    foreach ($path in $logPaths) {
        if (Test-Path $path) {
            try {
                Remove-Item -Path $path -Force
                Write-Success "已删除日志文件: $path"
            } catch {
                Write-Warning "删除日志文件失败: $path - $($_.Exception.Message)"
            }
        }
    }
}

# 清理进程
function Cleanup-OpenClashManageProcesses {
    Write-Info "正在清理残留进程..."
    
    try {
        $processes = Get-Process | Where-Object { 
            $_.ProcessName -like "*python*" -and 
            $_.CommandLine -like "*openclash*" -or 
            $_.CommandLine -like "*app.py*"
        }
        
        if ($processes) {
            $processes | Stop-Process -Force
            Write-Success "已清理残留进程"
        } else {
            Write-Info "未发现残留进程"
        }
    } catch {
        Write-Warning "清理进程时出错: $($_.Exception.Message)"
    }
}

# 检查端口占用
function Check-PortUsage {
    Write-Info "正在检查端口占用..."
    
    $ports = @(8888, 8080)
    
    foreach ($port in $ports) {
        try {
            $connection = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
            if ($connection) {
                Write-Warning "端口 $port 仍被占用，可能需要手动清理"
            }
        } catch {
            Write-Info "端口 $port 未被占用"
        }
    }
}

# 清理Python缓存
function Cleanup-PythonCache {
    Write-Info "正在清理Python缓存..."
    
    $cachePaths = @(
        "C:\opt",
        "C:\Program Files",
        "C:\Program Files (x86)",
        "$env:USERPROFILE"
    )
    
    foreach ($path in $cachePaths) {
        if (Test-Path $path) {
            try {
                # 删除 .pyc 文件
                Get-ChildItem -Path $path -Recurse -Name "*.pyc" -ErrorAction SilentlyContinue | 
                    ForEach-Object { Remove-Item -Path "$path\$_" -Force -ErrorAction SilentlyContinue }
                
                # 删除 __pycache__ 目录
                Get-ChildItem -Path $path -Recurse -Directory -Name "__pycache__" -ErrorAction SilentlyContinue | 
                    ForEach-Object { Remove-Item -Path "$path\$_" -Recurse -Force -ErrorAction SilentlyContinue }
            } catch {
                Write-Warning "清理Python缓存时出错: $($_.Exception.Message)"
            }
        }
    }
    
    Write-Success "已清理Python缓存文件"
}

# 显示卸载结果
function Show-UninstallResult {
    Write-Host ""
    Write-Success "=== OpenClashManage 卸载完成 ==="
    Write-Host ""
    Write-Info "已清理的内容："
    Write-Host "  ✅ 服务文件"
    Write-Host "  ✅ 应用文件"
    Write-Host "  ✅ 日志文件"
    Write-Host "  ✅ 残留进程"
    Write-Host "  ✅ Python缓存"
    Write-Host ""
    Write-Warning "注意事项："
    Write-Host "  ⚠️  如果端口仍被占用，请手动检查"
    Write-Host "  ⚠️  如需重新安装，请运行安装脚本"
    Write-Host ""
    Write-Info "重新安装命令："
    Write-Host "  wget -qO- https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/install_wget.sh | bash"
    Write-Host ""
}

# 主函数
function Main {
    Write-Host ""
    Write-Info "=== OpenClashManage Windows 卸载脚本 ==="
    Write-Host ""
    
    # 确认卸载
    if (-not $Force) {
        Write-Warning "此操作将完全移除OpenClashManage服务"
        $confirm = Read-Host "确认卸载？(y/N)"
        if ($confirm -notmatch "^[Yy]$") {
            Write-Info "取消卸载"
            return
        }
    }
    
    Write-Host ""
    Write-Info "开始卸载..."
    
    # 执行卸载步骤
    Stop-OpenClashManageService
    Remove-OpenClashManageService
    Remove-OpenClashManageFiles
    Remove-OpenClashManageLogs
    Cleanup-OpenClashManageProcesses
    Check-PortUsage
    Cleanup-PythonCache
    
    # 显示结果
    Show-UninstallResult
}

# 执行主函数
Main 