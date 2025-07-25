# zc.py
import os
import re
from datetime import datetime

def inject_groups(config, node_names: list) -> tuple:
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
    
    if not proxy_groups:
        write_log("❌ [zc] 未找到任何策略组")
        return config, 0

    injected_total = 0
    injected_groups = 0
    skipped_groups = 0

    # 🔄 修改：遍历所有策略组，而不是固定的策略组名称
    for group in proxy_groups:
        group_name = group.get("name", "")
        
        # 跳过一些特殊策略组（可选）
        skip_groups = ["DIRECT", "REJECT", "GLOBAL", "Proxy", "Final"]
        if group_name in skip_groups:
            write_log(f"⏭️ [zc] 跳过特殊策略组：{group_name}")
            skipped_groups += 1
            continue

        # 检查策略组类型，只处理需要代理的策略组
        group_type = group.get("type", "")
        if group_type in ["select", "url-test", "fallback", "load-balance"]:
            # 过滤掉可能导致循环引用的节点名称
            safe_names = [name for name in valid_names if name != group_name]
            
            if safe_names:
                # 保留原有的 REJECT 和 DIRECT，然后添加所有节点
                original_proxies = group.get("proxies", [])
                keep_proxies = [p for p in original_proxies if p in ["REJECT", "DIRECT"]]
                updated = keep_proxies + safe_names

                added = len([n for n in safe_names if n not in original_proxies])
                group["proxies"] = updated

                injected_total += added
                injected_groups += 1
                write_log(f"✅ [zc] 策略组 [{group_name}] 注入 {added} 个节点")
            else:
                write_log(f"⚠️ [zc] 策略组 [{group_name}] 没有有效节点可注入")
        else:
            write_log(f"⏭️ [zc] 跳过不支持类型的策略组 [{group_name}] (类型: {group_type})")
            skipped_groups += 1

    config["proxy-groups"] = proxy_groups
    
    # 验证配置，检查是否有循环引用
    for group in proxy_groups:
        if "proxies" in group:
            group_name = group.get("name", "")
            proxies = group.get("proxies", [])
            if group_name in proxies:
                write_log(f"⚠️ [zc] 检测到策略组 [{group_name}] 存在自引用，已移除")
                group["proxies"] = [p for p in proxies if p != group_name]
    
    write_log(f"🎯 [zc] 成功注入 {injected_groups} 个策略组，总计 {injected_total} 个节点，跳过非法节点 {skipped} 个，跳过策略组 {skipped_groups} 个\n")
    return config, injected_total
