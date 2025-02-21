# Docker SSH Tunnel (docker-st)

这个脚本用于优化 Docker 镜像的拉取速度。通过 SSH 隧道和本地代理，解决 Docker Hub 访问速度慢的问题。

## 系统要求

- Linux 或 macOS 操作系统
- 已安装 socat
- 本地已配置代理服务(可以访问 Docker Hub)
- sudo/root 权限

## 功能特点

- 自动配置 Docker Hub 相关域名的本地代理
- 支持自定义代理端口
- 支持 Linux 和 macOS 系统
- 支持 SSH 隧道转发
- 一键开启/关闭代理
- 自动备份和恢复 hosts 文件

## 使用场景

### 场景一：本机使用
适用于本机已有代理服务，但不想修改 Docker 配置的情况。

1. 下载脚本：
```bash
curl -O https://raw.githubusercontent.com/cnm4ak/docker-st/refs/heads/main/docker-st.sh
chmod +x docker-st.sh
```

1. 启动代理（默认使用7890端口）：
```bash
sudo ./docker-st.sh
```

1. 如果使用其他代理端口：
```bash
sudo ./docker-st.sh -p 1087
```

1. 停止代理：
```bash
sudo ./docker-st.sh stop
```

### 场景二：远程服务器使用
适用于远程服务器无法访问 Docker Hub，但本地有可用代理的情况。

1. 第一步：建立 SSH 隧道转发
```bash
# 格式：ssh -R [远程主机端口]:[本地主机]:[本地端口] [远程主机]
ssh -R 7890:localhost:7890 user@remote-server

# 例如：将本地 7890 端口转发到远程服务器的 7890 端口
ssh -R 7890:localhost:7890 root@example.com
```

2. 第二步：在远程服务器上运行脚本
```bash
# 下载脚本
curl -O https://raw.githubusercontent.com/cnm4ak/docker-st/refs/heads/main/docker-st.sh
chmod +x docker-st.sh

# 启动代理（使用转发的端口）
sudo ./docker-st.sh -p 7890
```

3. 停止代理：
```bash
sudo ./docker-st.sh stop
```

## 安装依赖

在使用脚本之前，请确保已安装 socat：

### macOS
```bash
brew install socat
```

### Ubuntu/Debian
```bash
sudo apt-get install socat
```

### CentOS/RHEL
```bash
sudo yum install socat
```

## 注意事项

1. 本机使用时：
   - 确保本地代理服务正常运行
   - 确认代理端口配置正确
   - 不需要修改 Docker 配置文件
   - 不需要重启 Docker 服务

2. 远程服务器使用时：
   - 确保本地代理服务正常运行
   - SSH 隧道必须在运行脚本前建立
   - 远程服务器的转发端口需要与脚本配置的端口一致
   - 可能需要在远程服务器的 sshd_config 中启用 `GatewayPorts yes`

## 故障排除

1. 本机使用问题：
   - 检查本地代理服务是否正常运行
   - 确认使用的代理端口是否正确
   - 验证是否有其他服务占用了 80/443 端口

2. 远程服务器问题：
   - 检查 SSH 隧道是否正常建立
   - 确认端口转发是否成功（可使用 netstat、ss 命令检查）
   - 验证远程服务器是否允许端口转发
   - 检查本地到远程服务器的网络连接是否稳定

## 项目背景

### 问题场景
在运维环境中，我们经常遇到这样的情况：
1. 内网服务器或云服务器无法访问 Docker Hub
2. 服务器上的 Docker 正在运行重要的生产容器
3. 不能重启 Docker 服务或修改 Docker 配置
4. 需要紧急拉取新的 Docker 镜像

### 解决思路
1. 利用本地机器的代理能力
2. 通过 SSH 隧道转发，将本地代理能力"转发"到内网服务器
3. 使用脚本在内网服务器上设置本地转发（无需修改 Docker 配置）
4. 实现在不重启 Docker 的情况下正常拉取镜像

这个方案的优势在于：
- 无需修改 Docker 配置文件
- 不需要重启 Docker 服务
- 不影响现有容器的运行
- 随时可以启用或关闭代理

## 许可证

本项目采用 Apache 许可证，详细内容请参见 [LICENSE](https://github.com/cnm4ak/docker-st/blob/main/LICENSE) 文件。

## 贡献

欢迎提交 Issue 和 Pull Request！