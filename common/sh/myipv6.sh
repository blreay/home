#!/bin/bash
# 综合检查IPv6支持

echo "=== IPv6支持检查 ==="

# 检查内核配置
if [ -f /boot/config-$(uname -r) ]; then
    if grep -q "CONFIG_IPV6=[ym]" /boot/config-$(uname -r); then
        echo "✓ 内核配置支持IPv6"
    else
        echo "✗ 内核配置不支持IPv6"
    fi
else
    echo "? 无法找到内核配置文件"
fi

# 检查模块
if lsmod | grep -q "^ipv6"; then
    echo "✓ IPv6模块已加载"
else
    echo "? IPv6模块未加载（可能内置或未启用）"
fi

# 检查/proc
if [ -f /proc/net/ipv6_route ]; then
    echo "✓ /proc/net/ipv6文件存在"
else
    echo "✗ /proc/net/ipv6文件不存在"
fi

# 测试回环地址
if ping6 -c 1 ::1 >/dev/null 2>&1; then
    echo "✓ 可以ping通IPv6回环地址"
else
    echo "✗ 无法ping通IPv6回环地址"
fi
