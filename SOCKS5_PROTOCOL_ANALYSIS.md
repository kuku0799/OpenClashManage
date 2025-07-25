# SOCKS5协议链接格式分析

## 📋 **SOCKS5协议概述**

SOCKS5是一种网络代理协议，支持TCP和UDP连接，常用于代理服务器配置。

## 🔗 **链接格式规范**

### **基本格式**
```
socks5://[username:password@]host:port[?参数][#节点名称]
```

### **格式组成部分**
1. **协议标识**: `socks5://` 或 `socks://`
2. **认证信息**: `username:password@` (可选)
3. **服务器地址**: `host:port`
4. **查询参数**: `?参数=值&参数=值` (可选)
5. **节点名称**: `#节点名称` (可选)

## 📝 **具体示例**

### **1. 基本SOCKS5链接**
```bash
# 无认证
socks5://192.168.1.100:1080#我的SOCKS5节点

# 有认证
socks5://user:pass@192.168.1.100:1080#认证SOCKS5节点
```

### **2. 带参数的SOCKS5链接**
```bash
# 带超时参数
socks5://192.168.1.100:1080?timeout=30#超时节点

# 带UDP支持
socks5://192.168.1.100:1080?udp=true#UDP节点

# 带TCP Fast Open
socks5://192.168.1.100:1080?tfo=true#TFO节点

# 组合参数
socks5://user:pass@192.168.1.100:1080?timeout=30&udp=true&tfo=true#完整节点
```

## 🔧 **解析逻辑**

### **1. URL解析**
```python
parsed = urlparse(line)
host = parsed.hostname      # 服务器地址
port = parsed.port or 1080  # 端口，默认1080
username = parsed.username  # 用户名
password = parsed.password  # 密码
query = parse_qs(parsed.query)  # 查询参数
```

### **2. 参数验证**
```python
# 验证必要参数
if not host or not port:
    raise ValueError("SOCKS5服务器地址或端口缺失")
```

### **3. 节点配置生成**
```python
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
```

## 📊 **支持的参数**

### **必需参数**
- `host`: 服务器地址
- `port`: 服务器端口

### **可选参数**
- `username`: 用户名 (认证)
- `password`: 密码 (认证)
- `timeout`: 连接超时时间 (秒)
- `udp`: 是否支持UDP (true/false)
- `tfo`: 是否启用TCP Fast Open (true/false)

## 🎯 **OpenClash配置格式**

解析后的SOCKS5节点在OpenClash中的配置格式：

```yaml
proxies:
  - name: "SOCKS5节点"
    type: socks5
    server: 192.168.1.100
    port: 1080
    username: user          # 可选
    password: pass          # 可选
    timeout: 30            # 可选
    udp: true              # 可选
    tfo: true              # 可选
```

## 🔍 **常见错误处理**

### **1. 格式错误**
```bash
# 错误：缺少端口
socks5://192.168.1.100#节点名称

# 错误：无效的端口号
socks5://192.168.1.100:99999#节点名称
```

### **2. 参数错误**
```bash
# 错误：无效的超时值
socks5://192.168.1.100:1080?timeout=abc#节点名称

# 错误：无效的布尔值
socks5://192.168.1.100:1080?udp=yes#节点名称
```

## ✅ **验证方法**

### **1. 链接格式验证**
```python
def validate_socks5_url(url: str) -> bool:
    """验证SOCKS5链接格式"""
    try:
        parsed = urlparse(url)
        if not parsed.scheme.startswith('socks'):
            return False
        if not parsed.hostname or not parsed.port:
            return False
        if parsed.port < 1 or parsed.port > 65535:
            return False
        return True
    except:
        return False
```

### **2. 参数验证**
```python
def validate_socks5_params(query: dict) -> bool:
    """验证SOCKS5参数"""
    try:
        if 'timeout' in query:
            timeout = int(query['timeout'][0])
            if timeout < 1 or timeout > 300:
                return False
        if 'udp' in query:
            udp = query['udp'][0].lower()
            if udp not in ['true', 'false']:
                return False
        return True
    except:
        return False
```

## 📈 **使用统计**

根据解析器的日志输出，可以统计：
- 成功解析的SOCKS5节点数量
- 解析失败的节点数量
- 各种参数的使用频率

## 🔄 **与其他协议的对比**

| 协议 | 格式 | 认证 | 加密 | UDP支持 |
|------|------|------|------|---------|
| SOCKS5 | `socks5://host:port` | 可选 | 无 | 是 |
| HTTP | `http://host:port` | 可选 | 无 | 否 |
| Shadowsocks | `ss://method:password@host:port` | 必需 | 是 | 是 |
| VMess | `vmess://uuid@host:port` | 必需 | 是 | 是 |

## 🎉 **总结**

SOCKS5协议链接格式相对简单，主要包含：
1. **协议标识**: `socks5://`
2. **认证信息**: 用户名和密码 (可选)
3. **服务器信息**: 地址和端口
4. **可选参数**: 超时、UDP、TFO等
5. **节点名称**: 用于标识

解析器能够正确处理所有这些格式，并生成符合OpenClash要求的配置。 