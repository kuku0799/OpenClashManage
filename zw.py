# zw.py
from ruamel.yaml import YAML
import copy
import os
import re
from jx import parse_nodes
from log import write_log

yaml = YAML()
yaml.preserve_quotes = True

def get_openclash_config_path() -> str:
    try:
        return os.popen("uci get openclash.config.config_path").read().strip()
    except Exception:
        return ""

def load_config(path: str):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return yaml.load(f)
    except:
        return {}

def is_valid_name(name: str) -> bool:
    # 允许中文、字母、数字、下划线、连字符和点号，与zc.py保持一致
    return bool(re.match(r'^[\u4e00-\u9fa5a-zA-Z0-9_\-\.]+$', name))

def inject_proxies(config, nodes: list) -> tuple:
    write_log(f"🔍 [zw] 开始注入代理节点，共 {len(nodes)} 个节点")
    
    if "proxies" not in config or not isinstance(config["proxies"], list):
        config["proxies"] = []
        write_log("🔧 [zw] 初始化proxies列表")

    # 🔄 修改：完全替换模式，不再检查重复
    new_nodes = []
    injected = 0
    skipped_invalid = 0

    for i, node in enumerate(nodes):
        node = copy.deepcopy(node)
        name = node.get("name", "").strip()
        node_type = node.get("type", "unknown")

        write_log(f"🔍 [zw] 处理节点 {i+1}/{len(nodes)}: {name} ({node_type})")

        if not is_valid_name(name):
            skipped_invalid += 1
            write_log(f"⚠️ [zw] 非法节点名已跳过：{name}")
            continue

        new_nodes.append(node)
        injected += 1
        write_log(f"✅ [zw] 节点 {name} 已添加")

    write_log(f"🔍 [zw] 开始替换proxies列表...")
    # 🔄 修改：直接替换而不是追加
    config["proxies"] = new_nodes
    write_log(f"✅ [zw] proxies列表已更新，共 {injected} 个有效节点，跳过 {skipped_invalid} 个无效节点")
    
    return config, injected, skipped_invalid, 0

def main():
    write_log("📦 [zw] 开始注入 proxies 网络节点...")

    config_path = get_openclash_config_path()
    if not config_path:
        write_log("❌ [zw] 获取配置路径失败，终止执行。")
        return

    config_data = load_config(config_path)
    if not config_data:
        write_log(f"❌ [zw] 配置文件为空或格式错误，请检查：{config_path}")
        return

    nodes = parse_nodes("/root/OpenClashManage/wangluo/nodes.txt")
    if not nodes:
        write_log("⚠️ [zw] 未获取到有效节点，跳过注入。")
        return

    updated_config, injected_count, invalid_count, duplicate_count = inject_proxies(config_data, nodes)
    total_count = len(nodes)

    if injected_count == 0:
        write_log("🔁 [zw] 无新节点注入。")
        return

    try:
        with open(config_path, "w", encoding="utf-8") as f:
            yaml.dump(updated_config, f)
        write_log(f"🎯 成功注入 {injected_count} 个节点（共 {total_count} 个，跳过非法 {invalid_count} 个，重复 {duplicate_count} 个）")
    except Exception as e:
        write_log(f"❌ [zw] 写入配置失败: {e}")

if __name__ == "__main__":
    main()
