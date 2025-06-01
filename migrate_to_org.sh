#!/bin/bash

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
    echo "请使用 sudo 运行此脚本"
    exit 1
fi

# 检查是否在正确的目录
if [ ! -f "create_user_docker_shells.sh" ]; then
    echo "错误：请在 slurm_docker_setup 目录下运行此脚本"
    exit 1
fi

# 创建新的目录结构
echo "创建新的目录结构..."
mkdir -p /data1/org

# 检查是否有用户正在使用容器
echo "检查容器状态..."
for i in {1..4}; do
    if docker ps | grep -q "user${i}-session"; then
        echo "警告：user$i 的容器正在运行，请确保用户已退出容器"
        read -p "是否继续？(y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "操作已取消"
            exit 1
        fi
    fi
done

# 停止并删除现有容器
echo "停止并删除现有容器..."
for i in {1..4}; do
    echo "处理 user$i..."
    # 停止容器
    docker stop user${i}-session 2>/dev/null
    # 删除容器
    docker rm user${i}-session 2>/dev/null
done

# 移动数据目录
echo "移动数据目录到新的位置..."
for i in {1..4}; do
    if [ -d "/data1/user${i}_data" ]; then
        echo "移动 user$i 的数据..."
        # 如果目标目录已存在，先备份
        if [ -d "/data1/org/user${i}_data" ]; then
            echo "备份已存在的目录..."
            mv "/data1/org/user${i}_data" "/data1/org/user${i}_data.bak.$(date +%Y%m%d_%H%M%S)"
        fi
        mv "/data1/user${i}_data" "/data1/org/"
        chown -R user$i:user$i "/data1/org/user${i}_data"
        chmod 700 "/data1/org/user${i}_data"
    else
        echo "创建 user$i 的新数据目录..."
        mkdir -p "/data1/org/user${i}_data"
        chown user$i:user$i "/data1/org/user${i}_data"
        chmod 700 "/data1/org/user${i}_data"
    fi
done

# 重新创建 Docker shell 脚本
echo "重新创建 Docker shell 脚本..."
bash create_user_docker_shells.sh

# 验证迁移结果
echo "验证迁移结果..."
for i in {1..4}; do
    echo "检查 user$i 的目录..."
    if [ -d "/data1/org/user${i}_data" ]; then
        echo "✓ 目录已创建"
        ls -ld "/data1/org/user${i}_data"
    else
        echo "✗ 目录创建失败"
    fi
done

echo "迁移完成！"
echo "请让用户重新登录以进入新的容器环境。"
echo "注意：所有数据都已移动到 /data1/org 目录下。"
echo "如果遇到问题，请检查："
echo "1. 目录权限是否正确"
echo "2. 用户是否可以访问新目录"
echo "3. Docker 容器是否可以正常启动"