#!/bin/bash
# install.sh (v7 - DooD Enabled)

# 设置错误处理
set -e
trap 'echo "Error: Command failed at line $LINENO"' ERR

# 检查是否以root运行
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# 获取宿主机上 docker 组的 GID
DOCKER_HOST_GID=$(getent group docker | cut -d: -f3)
if [ -z "$DOCKER_HOST_GID" ]; then
    echo "Error: docker group not found on host. Please install Docker properly."
    exit 1
fi
echo "Host Docker group GID is: $DOCKER_HOST_GID"

# 创建必要的目录
echo "Creating necessary directories..."
mkdir -p /opt/docker_images
mkdir -p /data1/org/user_workspaces

# 创建用户并配置
for i in {1..3}; do
    username="user${i}"
    user_home="/home/$username"

    # 用 -r 选项确保完全删除旧用户
    if id "$username" &>/dev/null; then
        userdel -r "$username" 2>/dev/null || true
    fi

    useradd -m -s /bin/bash "$username"
    echo "Created user: $username"

    password="$(openssl rand -base64 12 | tr -d '=')"
    echo "$username:$password" | chpasswd
    echo "Password for $username: $password"

    usermod -aG docker "$username"

    user_work_dir="/data1/org/user_workspaces/$username"
    mkdir -p "$user_work_dir"
    chown "$username":"$username" "$user_work_dir"
    chmod 700 "$user_work_dir"

    ln -sf "$user_work_dir" "$user_home/work"

    docker_name="${username}-container"
    cat > "$user_home/.bash_profile" <<EOF
if [ -z "\$INSIDE_DOCKER" ]; then
    echo "You are on the host. To enter your Docker container, run:"
    echo "docker exec -it ${docker_name} bash --login"
fi
EOF
    chown "$username":"$username" "$user_home/.bash_profile"

    # 在宿主机上为用户创建SSH密钥
    mkdir -p "$user_home/.ssh"
    chown "$username":"$username" "$user_home/.ssh"
    chmod 700 "$user_home/.ssh"
    if [ ! -f "$user_home/.ssh/id_ed25519" ]; then
        echo "Generating SSH key for host user $username..."
        sudo -u "$username" ssh-keygen -t ed25519 -f "$user_home/.ssh/id_ed25519" -N ""
    fi
done

# 构建基础镜像
echo "Building base environment image..."
docker build -t base-env -f Dockerfile.base .

# 为每个用户创建镜像
for i in {1..3}; do
    username="user${i}"
    uid=$(id -u "$username")
    gid=$(id -g "$username")
    user_pubkey=$(cat "/home/$username/.ssh/id_ed25519.pub")

    echo "Creating image for $username (UID=$uid, GID=$gid)..."
    image_dir="/opt/docker_images/$username"
    mkdir -p "$image_dir"
    dockerfile_path="$image_dir/Dockerfile"

    cat > "$dockerfile_path" <<EOF
# User-specific Dockerfile (DooD Version)
FROM base-env

# 创建与宿主机 docker 组 GID 相同的组
RUN groupadd -g ${DOCKER_HOST_GID} docker_host

# 创建用户和组，并将其加入 docker_host 组
RUN groupadd -g ${gid} ${username} \\
    && useradd -u ${uid} -g ${gid} -m -s /bin/bash -G docker_host ${username} \\
    && echo "${username} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${username} \\
    && chmod 0440 /etc/sudoers.d/${username}

# 创建用户的 SSH 环境
RUN mkdir -p /home/${username}/.ssh && \\
    echo "${user_pubkey}" > /home/${username}/.ssh/authorized_keys && \\
    chown -R ${uid}:${gid} /home/${username}/.ssh && \\
    chmod 700 /home/${username}/.ssh && \\
    chmod 600 /home/${username}/.ssh/authorized_keys
EOF

    # 构建命令
    docker build -t "${username}-env" "$image_dir"
done

# 创建并启动用户容器
for i in {1..3}; do
    username="user${i}"
    docker_name="${username}-container"
    ssh_port=$((2200 + i))

    case $i in
        1) gpu_device="0" ;;
        2) gpu_device="1" ;;
        3) gpu_device="2" ;;
    esac

    if docker ps -a --format '{{.Names}}' | grep -q "^${docker_name}$"; then
        docker rm -f "$docker_name" >/dev/null 2>&1 || true
    fi

    echo "Creating container for $username on GPU $gpu_device, SSH port $ssh_port"
    docker run -dit \
        --name "$docker_name" \
        --hostname "${username}-session" \
        --restart unless-stopped \
        --gpus "device=$gpu_device" \
        --cpus=8 \
        --memory=64g \
        --ipc=host \
        -v "/data1/org/user_workspaces/$username:/home/$username/work" \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -p "${ssh_port}:22" \
        "${username}-env"
done

echo "Installation script finished. Users can now use Docker inside their containers."