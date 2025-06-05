#!/bin/bash
# install.sh (v6 - The Final Fix)

# 设置错误处理
set -e
trap 'echo "Error: Command failed at line $LINENO"' ERR

# 检查是否以root运行
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

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

    # --- [最终修正] ---
    # 删除了所有的 `USER` 指令。让容器以 root 身份启动 sshd 服务。
    cat > "$dockerfile_path" <<EOF
# User-specific Dockerfile (Final Version)
FROM base-env

# 创建用户和组 (以 root 权限)
RUN groupadd -g ${gid} ${username} \\
    && useradd -u ${uid} -g ${gid} -m -s /bin/bash ${username} \\
    && echo "${username} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${username} \\
    && chmod 0440 /etc/sudoers.d/${username}

# 创建用户的 SSH 环境 (仍然以 root 权限)
RUN mkdir -p /home/${username}/.ssh && \\
    echo "${user_pubkey}" > /home/${username}/.ssh/authorized_keys && \\
    chown -R ${uid}:${gid} /home/${username}/.ssh && \\
    chmod 700 /home/${username}/.ssh && \\
    chmod 600 /home/${username}/.ssh/authorized_keys

# 不再需要 USER, WORKDIR, ENV 指令，sshd 会自动处理
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
        -p "${ssh_port}:22" \
        "${username}-env"
        # 注意：这里不再需要 CMD，因为它已经在 base Dockerfile 中定义了
done

echo "Installation script finished. The setup should now be complete and correct."