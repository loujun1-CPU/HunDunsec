#!/bin/bash
DVWA_COMPOSE="/root/HunDunsec/dvwa.yaml"
PIKACHU_COMPOSE="/root/HunDunsec/pikachu.yaml"
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
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "错误: Docker 未安装"
        return 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        echo "错误: Docker Compose 未安装"
        return 1
    fi
    return 0
}
check_yaml_files() {
    if [ ! -f "$DVWA_COMPOSE" ]; then
        echo "错误: DVWA YAML 文件不存在: $DVWA_COMPOSE"
        return 1
    fi
    if [ ! -f "$PIKACHU_COMPOSE" ]; then
        echo "错误: Pikachu YAML 文件不存在: $PIKACHU_COMPOSE"
        return 1
    fi
    echo "YAML 文件检查通过"
    return 0
}
pull_image() {
    local image=$1
    local name=$2
    echo "拉取 $name 镜像..."
    sudo docker pull $image
}
deploy_dvwa() {
    echo "=== 部署 DVWA 靶场 ==="
    if [ ! -f "$DVWA_COMPOSE" ]; then
        echo "错误: DVWA YAML 文件不存在: $DVWA_COMPOSE"
        return 1
    fi
    pull_image "vulnerables/web-dvwa:latest" "DVWA"
    echo "启动 DVWA 服务..."
    sudo docker-compose -f $DVWA_COMPOSE up -d
    
    if [ $? -eq 0 ]; then
        echo "DVWA 部署成功！"
    else
        echo "DVWA 部署失败！"
        return 1
    fi
}
deploy_pikachu() {
    echo "=== 部署 Pikachu 靶场 ==="
    if [ ! -f "$PIKACHU_COMPOSE" ]; then
        echo "错误: Pikachu YAML 文件不存在: $PIKACHU_COMPOSE"
        return 1
    fi
    pull_image "area39/pikachu:latest" "Pikachu"
    echo "启动 Pikachu 服务..."
    sudo docker-compose -f $PIKACHU_COMPOSE up -d
    if [ $? -eq 0 ]; then
        echo "Pikachu 部署成功！"
    else
        echo "Pikachu 部署失败！"
        return 1
    fi
}
stop_dvwa() {
    echo "停止 DVWA 服务..."
    if [ -f "$DVWA_COMPOSE" ]; then
        sudo docker-compose -f $DVWA_COMPOSE down
        echo "DVWA 已停止"
    else
        echo "DVWA YAML 文件不存在，尝试直接停止容器..."
        sudo docker stop dvwa 2>/dev/null && sudo docker rm dvwa 2>/dev/null
        echo "DVWA 容器已停止"
    fi
}
stop_pikachu() {
    echo "停止 Pikachu 服务..."
    if [ -f "$PIKACHU_COMPOSE" ]; then
        sudo docker-compose -f $PIKACHU_COMPOSE down
        echo "Pikachu 已停止"
    else
        echo "Pikachu YAML 文件不存在，尝试直接停止容器..."
        sudo docker stop pikachu 2>/dev/null && sudo docker rm pikachu 2>/dev/null
        echo "Pikachu 容器已停止"
    fi
}
check_status() {
    echo "=== 靶场服务状态 ==="
    LOCAL_IP=$(get_ip_address)
    echo ""
    echo "DVWA 状态:"
    if sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q "dvwa"; then
        sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "dvwa"
        echo "访问地址: http://${LOCAL_IP}:8000"
        echo "默认账号: admin / password"
    else
        echo "DVWA: 未运行"
    fi
    echo ""
    echo "Pikachu 状态:"
    if sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -q "pikachu"; then
        sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep "pikachu"
        echo "访问地址: http://${LOCAL_IP}:8001"
        echo "无需登录，直接访问"
    else
        echo "Pikachu: 未运行"
    fi
}
show_menu() {
    echo ""
    echo "=== 靶场管理菜单 ==="
    echo "1) 部署 DVWA 靶场"
    echo "2) 部署 Pikachu 靶场"
    echo "3) 部署所有靶场"
    echo "4) 停止 DVWA 靶场"
    echo "5) 停止 Pikachu 靶场"
    echo "6) 停止所有靶场"
    echo "7) 查看服务状态"
    echo "8) 查看访问信息"
    echo "9) 检查 YAML 文件"
    echo "10) 退出"
    echo ""
}
show_access_info() {
    LOCAL_IP=$(get_ip_address)
    echo "=================================================="
    echo "🎯 靶场访问信息"
    echo "📱 DVWA 靶场:"
    echo "   访问地址: http://${LOCAL_IP}:8000"
    echo "   默认账号: admin"
    echo "   默认密码: password"
    echo "   首次访问需要点击 'Create / Reset Database' 初始化"
    echo "   YAML 文件: $DVWA_COMPOSE"
    echo "📱 Pikachu 靶场:"
    echo "   访问地址: http://${LOCAL_IP}:8001"
    echo "   无需登录，直接访问"
    echo "   YAML 文件: $PIKACHU_COMPOSE"
    echo "💡 管理命令:"
    echo "   启动DVWA: docker-compose -f $DVWA_COMPOSE up -d"
    echo "   停止DVWA: docker-compose -f $DVWA_COMPOSE down"
    echo "   启动Pikachu: docker-compose -f $PIKACHU_COMPOSE up -d"
    echo "   停止Pikachu: docker-compose -f $PIKACHU_COMPOSE down"
    echo "=================================================="
}
check_yaml_files_menu() {
    echo "=== 检查 YAML 文件 ==="
    if [ -f "$DVWA_COMPOSE" ]; then
        echo "✓ DVWA YAML 文件存在: $DVWA_COMPOSE"
        echo "  文件内容预览:"
        head -n 10 "$DVWA_COMPOSE"
    else
        echo "✗ DVWA YAML 文件不存在: $DVWA_COMPOSE"
    fi
    echo ""
    if [ -f "$PIKACHU_COMPOSE" ]; then
        echo "✓ Pikachu YAML 文件存在: $PIKACHU_COMPOSE"
        echo "  文件内容预览:"
        head -n 10 "$PIKACHU_COMPOSE"
    else
        echo "✗ Pikachu YAML 文件不存在: $PIKACHU_COMPOSE"
    fi
}
main() {
    if ! check_docker; then
        echo "请先安装 Docker 和 Docker Compose"
        exit 1
    fi
    if ! check_yaml_files; then
        echo "请确保 YAML 文件存在或修改脚本中的路径变量"
    fi
    while true; do
        show_menu
        read -p "请选择操作 (1-10): " choice
        
        case $choice in
            1)
                deploy_dvwa
                ;;
            2)
                deploy_pikachu
                ;;
            3)
                deploy_dvwa
                deploy_pikachu
                ;;
            4)
                stop_dvwa
                ;;
            5)
                stop_pikachu
                ;;
            6)
                stop_dvwa
                stop_pikachu
                ;;
            7)
                check_status
                ;;
            8)
                show_access_info
                ;;
            9)
                check_yaml_files_menu
                ;;
            10)
                echo "退出"
                exit 0
                ;;
            *)
                echo "无效选择，请重新输入"
                ;;
        esac
        read -p "按回车键继续..."
    done
}
main "$@"
