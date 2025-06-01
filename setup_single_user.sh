#!/bin/bash

# 检查参数数量
if [ $# -lt 2 ]; then
    echo "Usage: $0 <username> <gpu_id> [password]"
    echo "Example: $0 user1 0 mypassword123"
    echo "GPU IDs:"
    echo "  0: RTX 4090 D (24GB)"
    echo "  1: RTX 4090 D (24GB)"
    echo "  2: RTX 4090 D (24GB)"
    echo "  3: RTX 4090 D (24GB)"
    echo "  4: H100 (80GB)"
    echo "  5: A100 (80GB)"
    exit 1
fi

# 设置变量
USERNAME=$1
GPU_ID=$2
PASSWORD=$3

# 验证 GPU ID
if ! [[ "$GPU_ID" =~ ^[0-5]$ ]]; then
    echo "Error: GPU ID must be between 0 and 5"
    exit 1
fi

echo "Setting up user: $USERNAME"
echo "Assigned GPU: $GPU_ID"

# 创建系统用户
if ! id "$USERNAME" &>/dev/null; then
    echo "Creating system user: $USERNAME"
    sudo useradd -m $USERNAME

    # 设置密码（如果提供）
    if [ ! -z "$PASSWORD" ]; then
        echo "$USERNAME:$PASSWORD" | sudo chpasswd
        echo "Password set for $USERNAME"
    else
        echo "Please set password for $USERNAME using: sudo passwd $USERNAME"
    fi
else
    echo "User $USERNAME already exists"
fi

# 添加 Docker 权限
echo "Adding Docker permissions for $USERNAME"
sudo usermod -aG docker $USERNAME

# 创建用户数据目录
echo "Creating data directory for $USERNAME"
sudo mkdir -p /data1/${USERNAME}_data
sudo chown $USERNAME:$USERNAME /data1/${USERNAME}_data
sudo chmod 700 /data1/${USERNAME}_data

# 创建 Docker shell 脚本目录
sudo mkdir -p /opt/docker_shells

# 创建用户的 Docker shell 脚本
cat > /opt/docker_shells/${USERNAME}_shell.sh << EOF
#!/bin/bash
# 获取当前用户的Docker镜像
DOCKER_IMAGE="${USERNAME}-env"

# 检查容器是否已存在
if ! docker ps -a | grep -q "${USERNAME}-session"; then
    # 如果容器不存在，创建新容器
    docker run -it \\
        --name ${USERNAME}-session \\
        --restart unless-stopped \\
        --gpus '"device=${GPU_ID}"' \\
        --security-opt no-new-privileges \\
        --cap-drop=ALL \\
        --cap-add=SYS_PTRACE \\
        --cap-add=NET_ADMIN \\
        -v /home/${USERNAME}:/workspace \\
        -v /data1/${USERNAME}_data:/workspace/data \\
        -v /var/run/docker.sock:/var/run/docker.sock \\
        -v /usr/bin/docker:/usr/bin/docker \\
        -v /usr/lib/x86_64-linux-gnu/libltdl.so.7:/usr/lib/x86_64-linux-gnu/libltdl.so.7 \\
        -w /workspace \\
        --hostname ${USERNAME}-container \\
        --group-add docker \\
        \${DOCKER_IMAGE} \\
        /bin/bash
else
    # 如果容器存在，重新连接到容器
    docker start ${USERNAME}-session
    docker attach ${USERNAME}-session
fi
EOF

# 设置执行权限
sudo chmod +x /opt/docker_shells/${USERNAME}_shell.sh

# 修改用户的 shell
sudo usermod --shell /opt/docker_shells/${USERNAME}_shell.sh ${USERNAME}

# 创建用户 Dockerfile
cat > Dockerfile.${USERNAME} << EOF
FROM base-env

# 设置用户名
ENV USERNAME=${USERNAME}

# 创建用户目录
RUN mkdir -p /home/${USERNAME} && \\
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}

# 设置工作目录
WORKDIR /workspace

# 设置默认命令
CMD ["bash"]
EOF

# 构建用户镜像
echo "Building Docker image for $USERNAME"
sudo docker build -t ${USERNAME}-env -f Dockerfile.${USERNAME} .

echo "Setup completed for $USERNAME"
echo "User can now login using: ssh ${USERNAME}@172.30.101.111"
echo "Assigned GPU: $GPU_ID"