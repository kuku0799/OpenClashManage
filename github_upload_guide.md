# GitHub 上传指南

## 步骤1：在GitHub上创建仓库

1. 访问 https://github.com
2. 点击右上角的 "+" 号，选择 "New repository"
3. 填写仓库信息：
   - **Repository name**: `OpenClashManage`
   - **Description**: `OpenClash 节点管理面板 - 基于Web的可视化管理工具`
   - **Visibility**: 选择 Public（公开）
   - **不要**勾选 "Add a README file"（因为我们已经有了）
   - **不要**勾选 "Add .gitignore"（因为我们已经有了）
   - **不要**勾选 "Choose a license"（因为我们已经有了）

4. 点击 "Create repository"

## 步骤2：上传代码到GitHub

在您的本地终端中运行以下命令：

```bash
# 添加远程仓库
git remote add origin https://github.com/YOUR_USERNAME/OpenClashManage.git

# 推送到GitHub
git branch -M main
git push -u origin main
```

**注意**: 请将 `YOUR_USERNAME` 替换为您的GitHub用户名。

## 步骤3：创建Release（可选）

1. 在GitHub仓库页面，点击 "Releases"
2. 点击 "Create a new release"
3. 填写信息：
   - **Tag version**: `v1.0.0`
   - **Release title**: `OpenClash Management Panel v1.0.0`
   - **Description**: 添加项目说明
4. 点击 "Publish release"

## 步骤4：更新安装脚本

上传成功后，需要更新 `install.sh` 文件中的GitHub仓库地址：

```bash
# 编辑 install.sh 文件
# 将第 95 行的仓库地址更新为您的实际仓库地址
GITHUB_REPO="https://raw.githubusercontent.com/YOUR_USERNAME/OpenClashManage/main"
```

然后重新提交和推送：

```bash
git add install.sh
git commit -m "Update GitHub repository URL in install script"
git push
```

## 一键安装链接

上传完成后，用户可以使用以下命令进行一键安装：

```bash
# 方法1：直接运行
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/OpenClashManage/main/install.sh | sudo bash

# 方法2：下载后运行
wget -O install.sh https://raw.githubusercontent.com/YOUR_USERNAME/OpenClashManage/main/install.sh && chmod +x install.sh && sudo ./install.sh
```

## 项目结构

上传后的项目将包含以下文件：

```
OpenClashManage/
├── app.py                 # Flask应用主文件
├── requirements.txt       # Python依赖
├── README.md             # 项目说明
├── install.sh            # 一键安装脚本
├── start.sh              # 启动脚本
├── LICENSE               # MIT许可证
├── .gitignore           # Git忽略文件
├── templates/
│   └── index.html       # Web界面模板
├── jk.sh                # 守护进程脚本
├── jx.py                # 节点解析器
├── log.py               # 日志模块
├── zc.py                # 策略组注入器
├── zr.py                # 主同步脚本
├── zw.py                # 代理节点注入器
└── wangluo/
    ├── nodes.txt        # 节点文件模板
    └── log.txt          # 日志文件
```

## 注意事项

1. **权限设置**: 确保仓库为公开，这样用户才能访问安装脚本
2. **文件路径**: 确保所有文件路径正确
3. **依赖检查**: 确保 `requirements.txt` 包含所有必要依赖
4. **文档更新**: 确保 README.md 包含完整的使用说明

## 测试安装

上传完成后，可以在一个新的环境中测试安装脚本：

```bash
# 在测试环境中运行
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/OpenClashManage/main/install.sh | sudo bash
```

## 推广链接

项目上传成功后，您可以分享以下链接：

- **项目地址**: `https://github.com/YOUR_USERNAME/OpenClashManage`
- **一键安装**: `curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/OpenClashManage/main/install.sh | sudo bash`
- **下载地址**: `https://github.com/YOUR_USERNAME/OpenClashManage/archive/main.zip` 