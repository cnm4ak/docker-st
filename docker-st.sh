#!/bin/bash

# 默认代理端口
PROXY_PORT=7890

# 解析命令行参数
if [ "$1" = "stop" ]; then
    STOP_PROXY=true
else
    while getopts "p:" opt; do
        case $opt in
            p) PROXY_PORT="$OPTARG" ;;
            \?) echo "无效的选项: -$OPTARG" >&2; exit 1 ;;
        esac
    done
fi

# 检查是否以root/sudo权限运行
if [ "$EUID" -ne 0 ]; then 
  echo "请使用sudo运行此脚本"
  exit 1
fi

# 检查操作系统类型
OS="$(uname)"
if [ "$OS" != "Linux" ] && [ "$OS" != "Darwin" ]; then
    echo "错误: 不支持的操作系统。仅支持 Linux 和 macOS。"
    exit 1
fi

# PID文件路径
PIDFILE="/tmp/docker-proxy-socat.pid"

# 停止代理的函数
stop_proxy() {
    if [ -f "$PIDFILE" ]; then
        echo "正在关闭 socat 代理进程..."
        while read pid; do
            kill $pid 2>/dev/null || true
        done < "$PIDFILE"
        rm -f "$PIDFILE"
    else
        echo "正在查找并关闭 socat 代理进程..."
        pkill -f "socat TCP-LISTEN:80" 2>/dev/null || true
        pkill -f "socat TCP-LISTEN:443" 2>/dev/null || true
    fi

    if [ -f /etc/hosts.backup.2628 ]; then
        echo "正在恢复原始hosts文件..."
        cp /etc/hosts.backup.2628 /etc/hosts
        rm -f /etc/hosts.backup.2628
    else
        echo "未找到hosts备份文件，正在清理hosts文件中的docker条目..."
        if [ "$OS" = "Darwin" ]; then
            sed -i '' '/docker\.io/d' /etc/hosts
        else
            sed -i '/docker\.io/d' /etc/hosts
        fi
    fi

    echo "代理已关闭"
    exit 0
}

# 启动代理的函数
start_proxy() {
    # 检查是否已安装 socat
    if ! command -v socat &> /dev/null; then
        echo "错误: 未安装 socat。请先安装 socat:"
        if [ "$OS" = "Darwin" ]; then
            echo "macOS: brew install socat"
        else
            echo "Ubuntu/Debian: sudo apt-get install socat"
            echo "CentOS/RHEL: sudo yum install socat"
        fi
        exit 1
    fi

    # 备份hosts文件
    cp /etc/hosts /etc/hosts.backup.2628

    # 添加Docker域名解析
    cat << EOF >> /etc/hosts
127.0.0.1 registry-1.docker.io
127.0.0.1 auth.docker.io
127.0.0.1 registry.docker.io
127.0.0.1 production.cloudflare.docker.com
127.0.0.1 docker.io
EOF

    # 启动 socat 转发并保存进程ID
    socat TCP-LISTEN:80,fork,reuseaddr PROXY:127.0.0.1:docker.io:80,proxyport=$PROXY_PORT & 
    echo $! >> "$PIDFILE"
    socat TCP-LISTEN:443,fork,reuseaddr PROXY:127.0.0.1:docker.io:443,proxyport=$PROXY_PORT &
    echo $! >> "$PIDFILE"

    echo "代理已启动，现在可以使用 docker pull 了"
    echo "使用的代理端口: $PROXY_PORT"
    if [ -n "$0" ] && [ "$0" != "bash" ]; then
        echo "如需停止代理，请运行: sudo $0 stop"
    else
        echo "如需停止代理，请下载脚本后运行: sudo ./docker-proxy.sh stop"
    fi
}

# 主逻辑
if [ "$STOP_PROXY" = true ]; then
    stop_proxy
else
    start_proxy
fi