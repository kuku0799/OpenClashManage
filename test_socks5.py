#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import base64
from urllib.parse import urlparse, parse_qs
from jx import decode_base64, process_node_name, extract_custom_name

def test_socks5_parsing():
    # 测试SOCKS5链接
    test_link = "socks://dXNlcmI6cGFzc3dvcmRi@iplc.hulicn.com:40533#ccccc"
    
    print(f"测试SOCKS5链接: {test_link}")
    
    # 解析URL
    parsed = urlparse(test_link)
    host, port = parsed.hostname, parsed.port or 1080
    username = parsed.username or ""
    password = parsed.password or ""
    
    print(f"原始解析结果:")
    print(f"  host: {host}")
    print(f"  port: {port}")
    print(f"  username: {username}")
    print(f"  password: {password}")
    
    # 解码Base64编码的用户名和密码
    try:
        if username:
            decoded_username = decode_base64(username)
            print(f"  解码后username: {decoded_username}")
        if password:
            decoded_password = decode_base64(password)
            print(f"  解码后password: {decoded_password}")
    except Exception as e:
        print(f"  解码失败: {e}")
    
    # 提取节点名称
    existing_names = set()
    name = process_node_name(extract_custom_name(test_link), existing_names)
    print(f"  节点名称: {name}")
    
    # 构建节点配置
    node = {
        "name": name,
        "type": "socks5",
        "server": host,
        "port": int(port)
    }
    
    if username:
        try:
            decoded_username = decode_base64(username)
            # 检查解码后的字符串是否包含冒号分隔的用户名和密码
            if ':' in decoded_username:
                username, password = decoded_username.split(':', 1)
                node.update({
                    "username": username,
                    "password": password
                })
            else:
                node.update({
                    "username": decoded_username
                })
        except Exception as e:
            print(f"  认证信息解码失败: {e}")
    
    print(f"\n最终节点配置:")
    for key, value in node.items():
        print(f"  {key}: {value}")

if __name__ == "__main__":
    test_socks5_parsing() 