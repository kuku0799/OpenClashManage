# 更新GitHub仓库地址

## 步骤1：获取您的GitHub用户名

请告诉我您的GitHub用户名，我将帮您更新安装脚本中的仓库地址。

## 步骤2：更新安装脚本

上传成功后，需要更新 `install.sh` 文件中的第95行：

```bash
# 当前地址（需要更新）
GITHUB_REPO="https://raw.githubusercontent.com/OpenClashManage/OpenClashManage/main"

# 更新为您的实际仓库地址
GITHUB_REPO="https://raw.githubusercontent.com/YOUR_USERNAME/OpenClashManage/main"
```

## 步骤3：重新提交和推送

更新后，重新提交和推送：

```bash
git add install.sh
git commit -m "Update GitHub repository URL"
git push
```

## 步骤4：测试一键安装

更新完成后，测试一键安装命令：

```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/OpenClashManage/main/install.sh | sudo bash
```

## 最终的一键安装链接

更新完成后，用户可以使用以下命令进行一键安装：

```bash
# 方法1：直接运行
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/OpenClashManage/main/install.sh | sudo bash

# 方法2：下载后运行
wget -O install.sh https://raw.githubusercontent.com/YOUR_USERNAME/OpenClashManage/main/install.sh && chmod +x install.sh && sudo ./install.sh

# 方法3：使用PowerShell（Windows）
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/YOUR_USERNAME/OpenClashManage/main/install.sh" -OutFile "install.sh"
```

## 项目特性

上传成功后，您的项目将具有以下特性：

✅ **现代化Web界面**：基于Bootstrap 5的响应式设计
✅ **自动化管理**：守护进程自动监控节点变化
✅ **多协议支持**：ss:// vmess:// vless:// trojan://
✅ **系统服务**：自动创建systemd服务
✅ **实时监控**：状态监控和日志管理
✅ **一键安装**：支持多种Linux发行版

## 推广链接

项目上传成功后，您可以分享以下链接：

- **项目地址**: `https://github.com/YOUR_USERNAME/OpenClashManage`
- **一键安装**: `curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/OpenClashManage/main/install.sh | sudo bash`
- **下载地址**: `https://github.com/YOUR_USERNAME/OpenClashManage/archive/main.zip` 