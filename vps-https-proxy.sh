#!/bin/bash

# 检查是否提供了足够的参数
if [ "$#" -ne 3 ]; then
    echo "用法: $0 <端口号> <用户名> <密码>"
    exit 1
fi

# 获取命令行参数
PORT=$1
USERNAME=$2
PASSWORD=$3

# 更新系统
sudo apt-get update -y
sudo apt-get upgrade -y

# 安装 Squid 和 Apache2-utils（用于创建密码文件）
sudo apt-get install squid apache2-utils -y

# 备份原始的 Squid 配置文件
sudo cp /etc/squid/squid.conf /etc/squid/squid.conf.backup

# 创建用于存储用户名和密码的文件
sudo touch /etc/squid/passwords

# 设置代理用户名和密码
sudo htpasswd -b -c /etc/squid/passwords "$USERNAME" "$PASSWORD"

# 配置 Squid 使用用户名和密码认证并允许所有IP访问
sudo bash -c "cat > /etc/squid/squid.conf <<EOL
http_port $PORT

# 启用认证配置
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwords
auth_param basic children 5
auth_param basic realm Squid proxy-caching web server
auth_param basic credentialsttl 2 hours
acl authenticated proxy_auth REQUIRED

# 允许所有IP地址访问代理服务器
http_access allow authenticated
http_access deny all
EOL"

# 重启 Squid 服务
sudo systemctl restart squid

# 开放防火墙端口
sudo ufw allow "$PORT"/tcp

# 显示 Squid 服务状态
sudo systemctl status squid

echo "Squid HTTP 代理已安装并配置完成。"
echo "代理服务器地址: http://$(curl -s ifconfig.me):$PORT"
echo "用户名: $USERNAME"
echo "密码: $PASSWORD"
echo "请在代理设置中使用此用户名和密码进行验证。"