#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import time
import hashlib
from ruamel.yaml import YAML
from jx import parse_nodes
from zw import inject_proxies
from zc import inject_groups
from log import write_log

lock_file = "/tmp/openclash_update.lock"
if os.path.exists(lock_file):
    write_log("⚠️ 已有运行中的更新任务，已退出避免重复执行。")
    exit(0)
open(lock_file, "w").close()

def verify_config(tmp_path: str) -> bool:
    write_log("🔍 正在验证配置可用性 ...")
    result = os.system(f"/etc/init.d/openclash verify_config {tmp_path} > /dev/null 2>&1")
    return result == 0

try:
    write_log("🚀 [zr] 开始执行同步脚本...")
    
    # 检查OpenClash是否安装
    write_log("🔍 [zr] 检查OpenClash安装状态...")
    openclash_status = os.system("opkg list-installed | grep openclash > /dev/null 2>&1")
    if openclash_status != 0:
        write_log("❌ [zr] OpenClash未安装，请先安装OpenClash")
        exit(1)
    write_log("✅ [zr] OpenClash已安装")
    
    nodes_file = "/root/OpenClashManage/wangluo/nodes.txt"
    md5_record_file = "/root/OpenClashManage/wangluo/nodes_content.md5"
    
    # 获取OpenClash配置文件路径
    write_log("🔍 [zr] 获取OpenClash配置文件路径...")
    config_file = os.popen("uci get openclash.config.config_path").read().strip()
    if not config_file:
        write_log("❌ [zr] 无法获取OpenClash配置文件路径")
        exit(1)
    write_log(f"✅ [zr] 配置文件路径: {config_file}")
    
    # 检查配置文件是否存在
    if not os.path.exists(config_file):
        write_log(f"❌ [zr] 配置文件不存在: {config_file}")
        exit(1)
    write_log("✅ [zr] 配置文件存在")

    write_log("🔍 [zr] 读取节点文件...")
    with open(nodes_file, "r", encoding="utf-8") as f:
        content = f.read()
    current_md5 = hashlib.md5(content.encode()).hexdigest()
    write_log(f"✅ [zr] 节点文件MD5: {current_md5}")

    previous_md5 = ""
    if os.path.exists(md5_record_file):
        with open(md5_record_file, "r") as f:
            previous_md5 = f.read().strip()
        write_log(f"🔍 [zr] 上次MD5: {previous_md5}")

    write_log("🔍 [zr] 读取OpenClash配置文件...")
    yaml = YAML()
    yaml.preserve_quotes = True
    with open(config_file, "r", encoding="utf-8") as f:
        config = yaml.load(f)
    existing_nodes_count = len(config.get("proxies") or [])
    write_log(f"✅ [zr] 当前配置中有 {existing_nodes_count} 个节点")

    if current_md5 == previous_md5:
        write_log(f"✅ [zr] nodes.txt 内容无变化，无需重启 OpenClash，当前节点数：{existing_nodes_count} 个")
        os.remove(lock_file)
        exit(0)
    else:
        write_log("📝 [zr] 检测到 nodes.txt 内容发生变更，准备更新配置 ...")
        with open(md5_record_file, "w") as f:
            f.write(current_md5)
        write_log("✅ [zr] 已更新MD5记录")

    write_log("🔍 [zr] 开始解析节点...")
    new_proxies = parse_nodes(nodes_file)
    if not new_proxies:
        write_log("⚠️ [zr] 未解析到任何有效节点，终止执行。")
        exit(1)
    write_log(f"✅ [zr] 成功解析 {len(new_proxies)} 个节点")

    write_log("🔍 [zr] 开始注入代理节点...")
    # 🔄 修改：完全替换模式 - 先清空现有节点
    config["proxies"] = []
    inject_proxies(config, new_proxies)
    write_log("✅ [zr] 代理节点注入完成")

    write_log("🔍 [zr] 开始注入策略组...")
    inject_groups(config, [p["name"] for p in new_proxies])
    write_log("✅ [zr] 策略组注入完成")

    write_log("🔍 [zr] 开始验证配置...")
    test_file = "/tmp/clash_verify_test.yaml"
    with open(test_file, "w", encoding="utf-8") as f:
        yaml.dump(config, f)
    write_log("✅ [zr] 测试配置文件已生成")

    if not verify_config(test_file):
        write_log("❌ [zr] 配置验证失败，未写入配置，已退出。")
        os.remove(test_file)
        exit(1)
    os.remove(test_file)
    write_log("✅ [zr] 配置验证通过")

    write_log("🔍 [zr] 开始备份原配置...")
    backup_file = f"{config_file}.bak"
    os.system(f"cp {config_file} {backup_file}")
    write_log("✅ [zr] 原配置已备份")

    write_log("🔍 [zr] 开始写入新配置...")
    with open(config_file, "w", encoding="utf-8") as f:
        yaml.dump(config, f)
    write_log("✅ [zr] 新配置已写入")

    write_log("🔍 [zr] 开始重启 OpenClash...")
    os.system("/etc/init.d/openclash restart")
    time.sleep(8)
    write_log("✅ [zr] OpenClash重启完成")

    write_log("🔍 [zr] 检查重启后状态...")
    check_log = os.popen("logread | grep 'Parse config error' | tail -n 5").read()
    if "Parse config error" in check_log:
        write_log("❌ [zr] 检测到配置解析错误，已触发回滚 ...")
        os.system(f"cp {backup_file} {config_file}")
        os.system("/etc/init.d/openclash restart")
        exit(1)
    write_log("✅ [zr] 重启后状态正常")

    write_log(f"🎉 [zr] 本次执行完成，已写入新配置并重启，总节点：{len(new_proxies)} 个")
    write_log("✅ [zr] OpenClash 已重启运行，节点已同步完成")

except Exception as e:
    import traceback
    write_log(f"❌ [zr] 脚本执行出错: {e}")
    write_log(f"❌ [zr] 错误详情: {traceback.format_exc()}")

finally:
    if os.path.exists(lock_file):
        os.remove(lock_file)
        write_log("🔧 [zr] 已清理锁文件")
