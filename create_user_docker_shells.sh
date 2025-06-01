#!/bin/bash

# 设置错误处理
set -e
trap 'echo "Error: Command failed at line $LINENO"' ERR

# 创建目录
sudo mkdir -p /opt/docker_shells

# 为每个用户创建Docker shell脚本
for i in {1..4}; do
    # 根据用户分配特定的 GPU
    case $i in
        1) GPU_DEVICE="0" ;;  # user1 使用 GPU 0 (RTX 4090 D)
        2) GPU_DEVICE="1" ;;  # user2 使用 GPU 1 (RTX 4090 D)
        3) GPU_DEVICE="2" ;;  # user3 使用 GPU 2 (RTX 4090 D)
        4) GPU_DEVICE="3" ;;  # user4 使用 GPU 3 (RTX 4090 D)
    esac

    cat > /opt/docker_shells/user${i}_shell.sh << EOF
#!/bin/bash

# 设置错误处理
set -e
trap 'echo "Error: Command failed at line \$LINENO"' ERR

# 获取当前用户的Docker镜像
DOCKER_IMAGE="user${i}-env"

# 检查容器是否已存在
if ! docker ps -a | grep -q "user${i}-session"; then
    # 如果容器不存在，创建新容器
    docker run -it \\
        --name user${i}-session \\
        --gpus '"device=${GPU_DEVICE}"' \\
        --cpus=8 \\
        --memory=64g \\
        --ulimit memlock=-1 \\
        --ulimit stack=67108864 \\
        --security-opt no-new-privileges \\
        --cap-drop=ALL \\
        --cap-add=SYS_PTRACE \\
        --health-cmd="nvidia-smi || exit 1" \\
        --health-interval=5m \\
        --log-driver=json-file \\
        --log-opt max-size=100m \\
        --log-opt max-file=3 \\
        -v /home/user${i}:/workspace \\
        -v /data1/org/user${i}_data:/workspace/data:rw \\
        -w /workspace \\
        --hostname user${i}-container \\
        --user user${i} \\
        \${DOCKER_IMAGE} \\
        /bin/bash
else
    # 检查容器状态
    CONTAINER_STATUS=\$(docker inspect -f '{{.State.Status}}' user${i}-session)

    if [ "\$CONTAINER_STATUS" == "exited" ]; then
        # 如果容器已停止，启动它
        docker start user${i}-session
    fi

    # 附加到运行中的容器
    docker attach user${i}-session
fi
EOF

    # 设置执行权限
    sudo chmod +x /opt/docker_shells/user${i}_shell.sh

    # 修改用户的shell
    sudo usermod --shell /opt/docker_shells/user${i}_shell.sh user${i}
done

echo "Docker shell 脚本创建完成！"