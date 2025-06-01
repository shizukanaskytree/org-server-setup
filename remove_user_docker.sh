#!/bin/bash

# 设置错误处理
set -e
trap 'echo "Error: Command failed at line $LINENO"' ERR

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
    echo "请使用 sudo 运行此脚本"
    exit 1
fi

# 检查参数
if [ $# -ne 1 ]; then
    echo "用法: $0 <username>"
    echo "示例: $0 user1"
    exit 1
fi

USERNAME=$1

# 检查用户是否存在
if ! id "$USERNAME" &>/dev/null; then
    echo "错误：用户 $USERNAME 不存在"
    exit 1
fi

# 检查用户是否正在使用系统
if who | grep -q "^$USERNAME"; then
    echo "警告：用户 $USERNAME 当前已登录"
    read -p "是否继续？(y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "操作已取消"
        exit 1
    fi
fi

echo "开始清理 $USERNAME 的 Docker 环境..."

# 1. 停止并删除容器
echo "停止并删除容器..."
if docker ps -a | grep -q "${USERNAME}-session"; then
    docker stop ${USERNAME}-session 2>/dev/null || true
    docker rm ${USERNAME}-session 2>/dev/null || true
    echo "容器已清理"
else
    echo "未找到用户容器"
fi

# 2. 询问是否删除 Docker 镜像
echo "检查 Docker 镜像..."
if docker images | grep -q "${USERNAME}-env"; then
    echo "注意：删除镜像后需要重新构建，这可能需要较长时间"
    read -p "是否删除用户 Docker 镜像？(y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "删除 Docker 镜像..."
        docker rmi ${USERNAME}-env 2>/dev/null || true
        echo "镜像已删除"
    else
        echo "保留 Docker 镜像"
    fi
else
    echo "未找到用户镜像"
fi

# 3. 清理 shell 脚本
echo "清理 shell 脚本..."
if [ -f "/opt/docker_shells/${USERNAME}_shell.sh" ]; then
    rm -f /opt/docker_shells/${USERNAME}_shell.sh
    echo "Shell 脚本已删除"
else
    echo "未找到用户 Shell 脚本"
fi

# 4. 询问是否删除数据目录
if [ -d "/data1/org/${USERNAME}_data" ]; then
    read -p "是否删除用户数据目录？(y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "删除数据目录..."
        rm -rf /data1/org/${USERNAME}_data
        echo "数据目录已删除"
    else
        echo "保留数据目录"
    fi
else
    echo "未找到用户数据目录"
fi

# 5. 恢复用户的默认 shell
echo "恢复用户的默认 shell..."
if [ "$(getent passwd $USERNAME | cut -d: -f7)" != "/bin/bash" ]; then
    usermod --shell /bin/bash $USERNAME
    echo "默认 Shell 已恢复"
else
    echo "用户已使用默认 Shell"
fi

# 6. 从 Docker 组移除用户
echo "从 Docker 组移除用户..."
if groups $USERNAME | grep -q docker; then
    gpasswd -d $USERNAME docker
    echo "用户已从 Docker 组移除"
else
    echo "用户不在 Docker 组中"
fi

# 7. 清理用户命名空间映射
echo "清理用户命名空间映射..."
if grep -q "^$USERNAME:" /etc/subuid; then
    sed -i "/^$USERNAME:/d" /etc/subuid
    sed -i "/^$USERNAME:/d" /etc/subgid
    echo "用户命名空间映射已清理"
else
    echo "未找到用户命名空间映射"
fi

echo "清理完成！"
echo "用户 $USERNAME 的 Docker 环境已完全移除"
echo "注意：如果选择了保留数据目录，数据仍然在 /data1/org/${USERNAME}_data"
echo ""
echo "验证步骤："
echo "1. 检查用户 shell: getent passwd $USERNAME"
echo "2. 检查 Docker 组: groups $USERNAME"
echo "3. 检查数据目录: ls -l /data1/org/${USERNAME}_data"