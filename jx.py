import os
import re
import json
import base64
from urllib.parse import unquote, urlparse, parse_qs
from typing import List, Dict
from log import write_log  # ✅ 使用统一日志输出

def decode_base64(data: str) -> str:
    try:
        data += '=' * (-len(data) % 4)
        return base64.urlsafe_b64decode(data).decode(errors="ignore")
    except Exception:
        return ""

def clean_name(name: str, existing_names: set) -> str:
    # 处理URL编码的节点名称
    try:
        name = unquote(name)
    except:
        pass
    
    # 移除特殊字符，保留中文、字母、数字、下划线、连字符
    name = re.sub(r'[^一-龥a-zA-Z0-9_\-\.]', '', name.strip())
    
    # 如果名称为空或只包含特殊字符，使用默认名称
    if not name or name.isspace():
        name = "Unnamed"
    
    # 限制长度
    name = name[:24]
    
    original = name
    count = 1
    while name in existing_names:
        name = f"{original}_{count}"
        count += 1
    existing_names.add(name)
    return name

def extract_custom_name(link: str) -> str:
    match = re.search(r'#(.+)', link)
    if match:
        name = match.group(1)
        # 处理URL编码的节点名称
        try:
            name = unquote(name)
        except:
            pass
        bracket_match = re.search(r'[（(](.*?)[)）]', name)
        return bracket_match.group(1) if bracket_match else name
    return "Unnamed"

def process_node_name(raw_name: str, existing_names: set) -> str:
    """处理节点名称，包括URL解码和清理"""
    # 处理URL编码
    try:
        decoded_name = unquote(raw_name)
        if decoded_name != raw_name and len(decoded_name) > 0:
            raw_name = decoded_name
    except:
        pass
    
    # 清理名称
    name = clean_name(raw_name, existing_names)
    return name

def parse_plugin_params(query: str) -> Dict:
    params = parse_qs(query)
    plugin_opts = {}
    if 'plugin' in params:
        plugin_opts['plugin'] = params['plugin'][0]
    return plugin_opts

def extract_host_port(hostport: str) -> (str, int):
    # 剥离 /、?、# 等尾部干扰字符，仅保留 host:port
    hostport = hostport.strip().split('/')[0].split('?')[0].split('#')[0]
    match = re.match(r"^(.*):(\d+)$", hostport)
    if not match:
        raise ValueError(f"无效 host:port 格式: {hostport}")
    return match.group(1), int(match.group(2))

def parse_nodes(file_path: str) -> List[Dict]:
    parsed_nodes = []
    existing_names = set()
    success_count = 0
    error_count = 0

    try:
        with open(file_path, "r", encoding="utf-8") as f:
            lines = [line.strip() for line in f if line.strip() and not line.startswith("#")]
    except Exception as e:
        write_log(f"❌ [parse] 无法读取节点文件: {e}")
        return []

    for line in lines:
        try:
            # Shadowsocks
            if line.startswith("ss://"):
                raw = line[5:]
                name = process_node_name(extract_custom_name(line), existing_names)
                if '@' in raw:
                    info, server = raw.split("@", 1)
                    info = decode_base64(info)
                    if not info:
                        raise ValueError("Base64解码失败")
                    method, password = info.split(":", 1)
                    hostport = server.split("#")[0].split("?")[0]
                    host, port = extract_host_port(hostport)
                    query = urlparse(line).query
                    plugin_opts = parse_plugin_params(query)
                    if not all([host, port, method, password]):
                        raise ValueError("字段缺失")

                    node = {
                        "name": name,
                        "type": "ss",
                        "server": host,
                        "port": port,
                        "cipher": method,
                        "password": password
                    }
                    if plugin_opts:
                        node.update(plugin_opts)
                    parsed_nodes.append(node)
                else:
                    decoded = decode_base64(raw.split("#")[0].split("?")[0])
                    if not decoded:
                        raise ValueError("Base64解码失败")
                    method_password, server = decoded.split("@")
                    method, password = method_password.split(":")
                    host, port = extract_host_port(server)
                    if not all([host, port, method, password]):
                        raise ValueError("字段缺失")
                    parsed_nodes.append({
                        "name": name,
                        "type": "ss",
                        "server": host,
                        "port": port,
                        "cipher": method,
                        "password": password
                    })
                success_count += 1

            # VMess
            elif line.startswith("vmess://"):
                decoded = decode_base64(line[8:].split("#")[0])
                if not decoded:
                    raise ValueError("Base64解码失败")
                node = json.loads(decoded)
                name = process_node_name(extract_custom_name(line), existing_names)
                if not all([node.get("add"), node.get("port"), node.get("id")]):
                    raise ValueError("字段缺失")
                parsed_nodes.append({
                    "name": name,
                    "type": "vmess",
                    "server": node["add"],
                    "port": int(node["port"]),
                    "uuid": node["id"],
                    "alterId": int(node.get("aid", 0)),
                    "cipher": node.get("type", "auto"),
                    "tls": node.get("tls", "").lower() == "tls",
                    "network": node.get("net"),
                    "ws-opts": {
                        "path": node.get("path", ""),
                        "headers": {"Host": node.get("host", "")}
                    } if node.get("net") == "ws" else {}
                })
                success_count += 1

            # VLESS
            elif line.startswith("vless://"):
                info = line[8:].split("#")[0]
                name = process_node_name(extract_custom_name(line), existing_names)
                parts = info.split("@")
                if len(parts) != 2:
                    raise ValueError("字段格式不正确")
                uuid = parts[0]
                parsed = urlparse("//" + parts[1])
                host, port = parsed.hostname, parsed.port
                query = parse_qs(parsed.query)
                if not all([host, port, uuid]):
                    raise ValueError("字段缺失")
                parsed_nodes.append({
                    "name": name,
                    "type": "vless",
                    "server": host,
                    "port": int(port),
                    "uuid": uuid,
                    "encryption": query.get("encryption", ["none"])[0],
                    "flow": query.get("flow", [None])[0],
                    "tls": query.get("security", ["none"])[0] == "tls"
                })
                success_count += 1

            # Trojan
            elif line.startswith("trojan://"):
                body = line[9:].split("#")[0]
                parsed = urlparse("//" + body)
                password = parsed.username
                host, port = parsed.hostname, parsed.port
                query = parse_qs(parsed.query)
                name = process_node_name(extract_custom_name(line), existing_names)
                if not all([host, port, password]):
                    raise ValueError("字段缺失")
                parsed_nodes.append({
                    "name": name,
                    "type": "trojan",
                    "server": host,
                    "port": int(port),
                    "password": password,
                    "sni": query.get("sni", [""])[0],
                    "alpn": query.get("alpn", []),
                    "skip-cert-verify": query.get("allowInsecure", ["false"])[0].lower() == "true"
                })
                success_count += 1

            # HTTP代理
            elif line.startswith("http://"):
                parsed = urlparse(line)
                host, port = parsed.hostname, parsed.port or 80
                username = parsed.username or ""
                password = parsed.password or ""
                name = process_node_name(extract_custom_name(line), existing_names)
                
                node = {
                    "name": name,
                    "type": "http",
                    "server": host,
                    "port": int(port)
                }
                if username and password:
                    node.update({
                        "username": username,
                        "password": password
                    })
                parsed_nodes.append(node)
                success_count += 1

            # HTTPS代理
            elif line.startswith("https://"):
                parsed = urlparse(line)
                host, port = parsed.hostname, parsed.port or 443
                username = parsed.username or ""
                password = parsed.password or ""
                name = process_node_name(extract_custom_name(line), existing_names)
                
                node = {
                    "name": name,
                    "type": "http",
                    "server": host,
                    "port": int(port),
                    "tls": True
                }
                if username and password:
                    node.update({
                        "username": username,
                        "password": password
                    })
                parsed_nodes.append(node)
                success_count += 1

            # SOCKS代理
            elif line.startswith("socks://") or line.startswith("socks5://"):
                parsed = urlparse(line)
                host, port = parsed.hostname, parsed.port or 1080
                username = parsed.username or ""
                password = parsed.password or ""
                query = parse_qs(parsed.query)
                name = process_node_name(extract_custom_name(line), existing_names)
                
                # 验证必要参数
                if not host or not port:
                    raise ValueError("SOCKS5服务器地址或端口缺失")
                
                node = {
                    "name": name,
                    "type": "socks5",
                    "server": host,
                    "port": int(port)
                }
                
                # 添加认证信息
                if username and password:
                    node.update({
                        "username": username,
                        "password": password
                    })
                
                # 添加可选参数
                if query.get("timeout"):
                    node["timeout"] = int(query["timeout"][0])
                if query.get("udp"):
                    node["udp"] = query["udp"][0].lower() == "true"
                if query.get("tfo"):
                    node["tfo"] = query["tfo"][0].lower() == "true"
                
                parsed_nodes.append(node)
                success_count += 1

            # ShadowsocksR
            elif line.startswith("ssr://"):
                decoded = decode_base64(line[6:].split("#")[0])
                if not decoded:
                    raise ValueError("Base64解码失败")
                
                # SSR格式: server:port:protocol:method:obfs:password_base64/?obfsparam=xxx&protoparam=xxx&remarks=xxx&group=xxx
                parts = decoded.split("/?")
                if len(parts) != 2:
                    raise ValueError("SSR格式不正确")
                
                server_part = parts[0]
                params_part = parts[1]
                
                # 解析服务器部分
                server_parts = server_part.split(":")
                if len(server_parts) < 6:
                    raise ValueError("SSR服务器参数不足")
                
                host, port, protocol, method, obfs, password_b64 = server_parts[:6]
                
                # 解析参数
                params = parse_qs(params_part)
                remarks = unquote(params.get("remarks", [""])[0])
                obfsparam = unquote(params.get("obfsparam", [""])[0])
                protoparam = unquote(params.get("protoparam", [""])[0])
                
                name = process_node_name(remarks or extract_custom_name(line), existing_names)
                password = decode_base64(password_b64)
                
                parsed_nodes.append({
                    "name": name,
                    "type": "ssr",
                    "server": host,
                    "port": int(port),
                    "cipher": method,
                    "password": password,
                    "protocol": protocol,
                    "protocol-param": protoparam,
                    "obfs": obfs,
                    "obfs-param": obfsparam
                })
                success_count += 1

            # Snell
            elif line.startswith("snell://"):
                parsed = urlparse(line)
                host, port = parsed.hostname, parsed.port or 443
                password = parsed.username or ""
                query = parse_qs(parsed.query)
                name = process_node_name(extract_custom_name(line), existing_names)
                
                node = {
                    "name": name,
                    "type": "snell",
                    "server": host,
                    "port": int(port),
                    "psk": password,
                    "version": int(query.get("version", ["1"])[0])
                }
                
                if query.get("obfs"):
                    node["obfs-opts"] = {
                        "mode": query["obfs"][0],
                        "host": query.get("obfs-host", [""])[0]
                    }
                
                parsed_nodes.append(node)
                success_count += 1

            # Hysteria
            elif line.startswith("hysteria://"):
                parsed = urlparse(line)
                host, port = parsed.hostname, parsed.port or 443
                query = parse_qs(parsed.query)
                name = process_node_name(extract_custom_name(line), existing_names)
                
                node = {
                    "name": name,
                    "type": "hysteria",
                    "server": host,
                    "port": int(port),
                    "protocol": query.get("protocol", ["udp"])[0],
                    "up_mbps": int(query.get("upmbps", ["10"])[0]),
                    "down_mbps": int(query.get("downmbps", ["50"])[0])
                }
                
                if query.get("auth"):
                    node["auth"] = query["auth"][0]
                if query.get("peer"):
                    node["server_name"] = query["peer"][0]
                if query.get("insecure"):
                    node["skip-cert-verify"] = query["insecure"][0].lower() == "true"
                
                parsed_nodes.append(node)
                success_count += 1

            # TUIC
            elif line.startswith("tuic://"):
                parsed = urlparse(line)
                host, port = parsed.hostname, parsed.port or 443
                query = parse_qs(parsed.query)
                name = process_node_name(extract_custom_name(line), existing_names)
                
                node = {
                    "name": name,
                    "type": "tuic",
                    "server": host,
                    "port": int(port),
                    "uuid": parsed.username,
                    "password": parsed.password or "",
                    "congestion_control": query.get("congestion_control", ["bbr"])[0],
                    "udp_relay_mode": query.get("udp_relay_mode", ["native"])[0]
                }
                
                if query.get("alpn"):
                    node["alpn"] = query["alpn"]
                if query.get("disable_sni"):
                    node["disable_sni"] = query["disable_sni"][0].lower() == "true"
                
                parsed_nodes.append(node)
                success_count += 1

            else:
                write_log(f"⚠️ [parse] 不支持的协议: {line[:30]}")
                error_count += 1

        except Exception as e:
            write_log(f"❌ [parse] 解析失败 ({line[:30]}) → {e}")
            error_count += 1

    write_log(f"✅ [parse] 成功解析 {success_count} 条，失败 {error_count} 条")
    write_log("------------------------------------------------------------")
    return parsed_nodes
