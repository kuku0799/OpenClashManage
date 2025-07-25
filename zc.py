# zc.py
import os
import re
from datetime import datetime

def inject_groups(config, node_names: list) -> tuple:
    # 生成手机002 到 手机254
    target_groups = [f"手机{i}" for i in range(2, 255)]

    # 日志路径
    log_path = os.getenv("ZC_LOG_PATH", "/root/OpenClashManage/wangluo/log.txt")
    def write_log(msg):
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        with open(log_path, "a", encoding="utf-8") as f:
            f.write(f"[{timestamp}] {msg}\n")

    def is_valid_name(name: str) -> bool:
        # 更严格的名称验证，排除可能导致循环引用的字符
        return bool(re.match(r'^[a-zA-Z0-9_\-\.]+$', name))

    # ✅ 节点名称合法性校验
    valid_names = []
    skipped = 0
    for name in node_names:
        name = name.strip()
        if is_valid_name(name):
            valid_names.append(name)
        else:
            skipped += 1
            write_log(f"⚠️ [zc] 非法节点名已跳过：{name}")

    proxy_groups = config.get("proxy-groups", [])
    group_map = {g["name"]: g for g in proxy_groups}

    injected_total = 0
    injected_groups = 0

    for group_name in target_groups:
        group = group_map.get(group_name)
        if not group:
            write_log(f"⚠️ 策略组 [{group_name}] 不存在，跳过注入")
            continue

        # 🔄 修改：完全替换策略组中的节点，不保留旧节点
        # 过滤掉可能导致循环引用的节点名称
        safe_names = [name for name in valid_names if name != group_name]
        updated = ["REJECT", "DIRECT"] + safe_names

        added = len([n for n in safe_names if n not in group.get("proxies", [])])
        group["proxies"] = updated

        injected_total += added
        injected_groups += 1

    config["proxy-groups"] = proxy_groups
    
    # 验证配置，检查是否有循环引用
    for group in proxy_groups:
        if "proxies" in group:
            group_name = group.get("name", "")
            proxies = group.get("proxies", [])
            if group_name in proxies:
                write_log(f"⚠️ [zc] 检测到策略组 [{group_name}] 存在自引用，已移除")
                group["proxies"] = [p for p in proxies if p != group_name]
    
    write_log(f"🎯 成功注入 {injected_groups} 个策略组，总计 {injected_total} 个节点，跳过非法节点 {skipped} 个\n")
    return config, injected_total
