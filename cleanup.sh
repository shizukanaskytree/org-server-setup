#!/bin/bash
# cleanup.sh - Safely removes all components created by install.sh

# 脚本任意一步出错则立即退出
set -e

# 检查是否以root运行
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

echo "Starting cleanup process..."

# --- 步骤 1: 停止并删除 Docker 容器 ---
echo "Stopping and removing user containers..."
for i in {1..3}; do
    username="user${i}"
    container_name="${username}-container"
    # 检查容器是否存在，存在则强制删除
    if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        echo "Removing container: ${container_name}"
        docker rm -f "$container_name"
    else
        echo "Container ${container_name} not found, skipping."
    fi
done

# --- 步骤 2: 删除 Docker 镜像 ---
# 必须先删除用户镜像，再删除基础镜像
echo "Removing user-specific Docker images..."
for i in {1..3}; do
    username="user${i}"
    image_name="${username}-env"
    # 检查镜像是否存在，存在则删除
    if docker images -q "$image_name" | grep -q .; then
        echo "Removing image: ${image_name}"
        docker rmi "$image_name"
    else
        echo "Image ${image_name} not found, skipping."
    fi
done

echo "Removing base Docker image..."
if docker images -q "base-env" | grep -q .; then
    echo "Removing image: base-env"
    docker rmi "base-env"
else
    echo "Image base-env not found, skipping."
fi


# --- 步骤 3: 删除宿主机用户 ---
echo "Deleting host users and their home directories..."
for i in {1..3}; do
    username="user${i}"
    # 检查用户是否存在
    if id "$username" &>/dev/null; then
        echo "Deleting user: $username"
        # 为防止有残留进程导致删除失败，先杀死用户所有进程
        pkill -u "$username" || true
        userdel -r "$username"
    else
        echo "User ${username} not found, skipping."
    fi
done

# --- 步骤 4: 删除相关目录 ---
echo "Cleaning up created directories..."

if [ -d "/opt/docker_images" ]; then
    echo "Removing /opt/docker_images..."
    rm -rf "/opt/docker_images"
fi

# !! 这是一个危险操作，因为它会删除所有用户的工作数据 !!
# !! 确保你不再需要这些数据，或者已经备份 !!
echo "--------------------------------------------------------"
echo "WARNING: The next step will delete /data1/org/user_workspaces"
echo "This contains ALL user work data. "
read -p "Type 'yes' to confirm deletion: " confirmation
if [ "$confirmation" == "yes" ]; then
    if [ -d "/data1/org/user_workspaces" ]; then
        echo "Removing /data1/org/user_workspaces..."
        rm -rf "/data1/org/user_workspaces"
    fi
else
    echo "Skipping deletion of /data1/org/user_workspaces."
fi
echo "--------------------------------------------------------"


echo "Cleanup finished successfully!"