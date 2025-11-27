#!/bin/bash
setup_docker_environment() {
    sudo apt update
    sudo apt install docker.io -y
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo mkdir -p /etc/docker
    sudo cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": [
    "https://docker.1panel.live",
    "https://hub.rat.dev"
  ]
}
EOF
    sudo systemctl restart docker
    sudo docker info
    sudo apt install docker-compose -y
}
check_dependencies() {
    local missing_deps=()
    if ! command -v unzip &> /dev/null; then
        missing_deps+=("unzip")
    fi
    if ! command -v wget &> /dev/null; then
        missing_deps+=("wget")
    fi
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "安装缺少的依赖: ${missing_deps[*]}"
        sudo apt update
        sudo apt install -y ${missing_deps[@]}
    fi
    echo "所有依赖已安装"
}
download_and_extract() {
    if [ -f "ARL-plus-docker.zip" ]; then
        echo "检测到已存在的 ARL-plus-docker.zip，跳过下载"
    else
        wget https://github.com/ki9mu/ARL-plus-docker/archive/refs/tags/v3.0.1.zip -O ARL-plus-docker.zip
        if [ $? -ne 0 ]; then
            echo "下载失败，请检查网络连接"
            exit 1
        fi
    fi
    echo "解压源码..."
    if [ -d "ARL-plus-docker-3.0.1" ]; then
        echo "检测到已存在的 ARL-plus-docker-3.0.1 目录，跳过解压"
    else
        unzip -q ARL-plus-docker.zip
        if [ $? -ne 0 ]; then
            echo "解压失败"
            exit 1
        fi
    fi
}
get_ip_address() {
    if command -v python3 &> /dev/null; then
        python3 - << EOF
import socket
import subprocess
import re

def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        print(ip)
        return
    except:
        pass

    try:
        result = subprocess.check_output(["hostname", "-I"], universal_newlines=True)
        ips = result.strip().split()
        if ips:
            print(ips[0])
            return
    except:
        pass

    print("127.0.0.1")

get_local_ip()
EOF
    else
        hostname -I 2>/dev/null | awk '{print $1}' || echo "127.0.0.1"
    fi
}
create_volume() {
    echo "检查数据卷..."
    if ! sudo docker volume ls | grep -q "arl_db"; then
        echo "创建数据卷 arl_db..."
        sudo docker volume create arl_db
        if [ $? -eq 0 ]; then
            echo "数据卷创建成功"
        else
            echo "数据卷创建失败"
            exit 1
        fi
    else
        echo "数据卷 arl_db 已存在"
    fi
}
cleanup() {
    echo "停止现有服务..."
    cd ARL-plus-docker-3.0.1
    sudo docker-compose down
}
start_services() {
    echo "启动 ARL-plus 服务..."
    cd ARL-plus-docker-3.0.1
    sudo docker-compose up -d
    if [ $? -eq 0 ]; then
        echo "服务启动命令执行成功"
    else
        echo "服务启动失败"
        exit 1
    fi
}
check_services() {
    echo "等待服务启动..."
    sleep 30
    echo "检查服务状态..."
    cd ARL-plus-docker-3.0.1
    sudo docker-compose ps
}
main() {
    echo "=== ARL-plus 全自动部署脚本 ==="
    setup_docker_environment
    check_dependencies
    download_and_extract
    LOCAL_IP=$(get_ip_address)
    echo "检测到本机IP: $LOCAL_IP"
    create_volume
    cleanup
    start_services
    check_services
    echo ""
    echo "=================================================="
    echo "🎉 ARL-plus 启动完成！"
    echo "📱 访问地址: https://${LOCAL_IP}:5003"
    echo "👤 默认用户名: admin"
    echo "🔑 默认密码: arlpass"
    echo "💡 重要提示:"
    echo "   1. 首次访问可能需要等待几分钟所有服务完全启动"
    echo "   2. 如果无法访问，请检查防火墙设置"
    echo "   3. 查看日志: cd ARL-plus-docker-3.0.1 && sudo docker-compose logs"
    echo "=================================================="
}
main "$@"
