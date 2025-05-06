#!/bin/bash
DOMAINS=(
    "registry-1.docker.io"
    "auth.docker.io"
    "registry.docker.io"
    "production.cloudflare.docker.com"
    "docker.io"
)
PROXY_PORT=7890
LOCAL_HTTP_PORT=80
LOCAL_HTTPS_PORT=443
PIDFILE="/tmp/docker-proxy-socat.pid"

start_proxy() {
    # 检查是否已安装 socat
    if ! command -v socat &> /dev/null; then
        echo "错误: 未安装 socat。请先安装 socat"
        exit 1
    fi

    # 启动所有域名的代理
    # 只启动一个 socat 实例，使用 %h 来自动处理不同域名
    echo "设置 HTTP 转发规则：所有域名:80 -> 代理"
    socat TCP-LISTEN:$LOCAL_HTTP_PORT,fork,reuseaddr PROXY:127.0.0.1:%h:80,proxyport=$PROXY_PORT & 
    echo $! >> "$PIDFILE"
    
    echo "设置 HTTPS 转发规则：所有域名:443 -> 代理"
    socat TCP-LISTEN:$LOCAL_HTTPS_PORT,fork,reuseaddr PROXY:127.0.0.1:%h:443,proxyport=$PROXY_PORT &
    echo $! >> "$PIDFILE"

    # 添加 hosts 文件条目
    for domain in "${DOMAINS[@]}"; do
        echo "127.0.0.1 $domain" >> /etc/hosts
    done

    echo "代理已启动"
    echo "使用的代理端口: $PROXY_PORT"
    echo "本地 HTTP 端口: $LOCAL_HTTP_PORT"
    echo "本地 HTTPS 端口: $LOCAL_HTTPS_PORT"
}

stop_proxy() {
    if [ -f "$PIDFILE" ]; then
        echo "正在关闭 socat 代理进程..."
        while read pid; do
            kill $pid 2>/dev/null || true
        done < "$PIDFILE"
        rm -f "$PIDFILE"
    else
        echo "正在查找并关闭 socat 代理进程..."
        pkill -f "socat TCP-LISTEN:$LOCAL_HTTP_PORT" 2>/dev/null || true
        pkill -f "socat TCP-LISTEN:$LOCAL_HTTPS_PORT" 2>/dev/null || true
    fi

    # 清理 hosts 文件
    for domain in "${DOMAINS[@]}"; do
        sed -i.bak "/$domain/d" /etc/hosts
    done

    echo "代理已关闭"
}

# 解析命令行参数
case "$1" in
    start)
        start_proxy
        ;;
    stop)
        stop_proxy
        ;;
    *)
        echo "用法: $0 {start|stop}"
        exit 1
        ;;
esac