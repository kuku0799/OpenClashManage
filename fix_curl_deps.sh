#!/bin/bash

# OpenClash 管理面板 - curl依赖修复脚本
# 作者: OpenClashManage
# 版本: 1.0.0

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "此脚本需要root权限运行"
        print_message "请使用: bash fix_curl_deps.sh"
        exit 1
    fi
}

# 修复curl依赖问题
fix_curl_deps() {
    print_step "修复curl依赖问题..."
    
    # 检查curl版本
    CURL_VERSION=$(curl --version 2>/dev/null | head -1 | awk '{print $2}' || echo "unknown")
    print_message "当前curl版本: $CURL_VERSION"
    
    # 检查缺失的库文件
    print_message "检查缺失的库文件..."
    
    MISSING_LIBS=()
    
    if [[ ! -f "/usr/lib/libmbedtls.so.21" ]]; then
        MISSING_LIBS+=("libmbedtls.so.21")
    fi
    
    if [[ ! -f "/usr/lib/libmbedx509.so.7" ]]; then
        MISSING_LIBS+=("libmbedx509.so.7")
    fi
    
    if [[ ! -f "/usr/lib/libmbedcrypto.so.16" ]]; then
        MISSING_LIBS+=("libmbedcrypto.so.16")
    fi
    
    if [[ ${#MISSING_LIBS[@]} -gt 0 ]]; then
        print_warning "发现缺失的库文件: ${MISSING_LIBS[*]}"
        
        # 尝试安装mbedtls相关包
        print_message "尝试安装mbedtls依赖..."
        
        # 更新软件包列表
        opkg update
        
        # 尝试安装mbedtls包
        if opkg install libmbedtls 2>/dev/null; then
            print_message "✅ libmbedtls安装成功"
        else
            print_warning "⚠️  libmbedtls安装失败，尝试其他方案"
        fi
        
        # 尝试安装mbedtls12包
        if opkg install libmbedtls12 2>/dev/null; then
            print_message "✅ libmbedtls12安装成功"
        else
            print_warning "⚠️  libmbedtls12安装失败"
        fi
        
        # 尝试安装mbedtls13包
        if opkg install libmbedtls13 2>/dev/null; then
            print_message "✅ libmbedtls13安装成功"
        else
            print_warning "⚠️  libmbedtls13安装失败"
        fi
        
        # 尝试降级curl到稳定版本
        print_message "尝试降级curl到稳定版本..."
        if opkg install --force-downgrade curl=8.11.1-1 2>/dev/null; then
            print_message "✅ curl降级成功"
        else
            print_warning "⚠️  curl降级失败"
        fi
    else
        print_message "✅ 所有库文件都存在"
    fi
}

# 测试curl功能
test_curl() {
    print_step "测试curl功能..."
    
    if curl --version >/dev/null 2>&1; then
        print_message "✅ curl工作正常"
        
        # 测试下载功能
        if curl -sSL --max-time 10 https://httpbin.org/get >/dev/null 2>&1; then
            print_message "✅ curl下载功能正常"
            return 0
        else
            print_warning "⚠️  curl下载功能异常"
            return 1
        fi
    else
        print_error "❌ curl无法正常工作"
        return 1
    fi
}

# 提供替代方案
provide_alternatives() {
    print_step "提供替代方案..."
    
    print_message "如果curl仍然有问题，可以尝试以下方案："
    echo ""
    echo "1. 使用wget替代curl:"
    echo "   wget -O file https://example.com/file"
    echo ""
    echo "2. 重新安装curl:"
    echo "   opkg remove curl"
    echo "   opkg install curl"
    echo ""
    echo "3. 使用busybox的wget:"
    echo "   busybox wget -O file https://example.com/file"
    echo ""
    echo "4. 手动下载文件:"
    echo "   在本地下载文件后通过scp上传到OpenWrt"
}

# 主函数
main() {
    echo "=========================================="
    echo "    OpenClash 管理面板 - curl依赖修复"
    echo "=========================================="
    echo ""
    
    check_root
    fix_curl_deps
    test_curl
    
    if [[ $? -eq 0 ]]; then
        print_message "✅ curl依赖修复完成！"
        echo ""
        print_message "现在可以重新运行安装脚本："
        echo "curl -sSL https://raw.githubusercontent.com/kuku0799/OpenClashManage/main/install_openwrt_robust.sh | bash"
    else
        print_warning "⚠️  curl仍有问题，请尝试替代方案"
        provide_alternatives
    fi
}

# 运行主函数
main "$@" 