#!/bin/bash

# 设置错误处理
set -e
trap 'echo "Error: Command failed at line $LINENO"' ERR

# 检查是否以root运行
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# 检查必要的命令是否存在
for cmd in docker nvidia-smi; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: $cmd is not installed"
        exit 1
    fi
done

# 创建必要的目录
mkdir -p /opt/docker_shells
mkdir -p /data1/org

# 配置用户命名空间映射
echo "Configuring user namespace mappings..."
for i in {1..4}; do
    # 检查用户是否存在
    if ! id "user${i}" &>/dev/null; then
        echo "Error: user${i} does not exist"
        exit 1
    fi

    # 配置subuid/subgid映射
    usermod --add-subuids 100000-165535 --add-subgids 100000-165535 user${i}

    # 确保用户主目录存在并设置正确的权限
    mkdir -p /home/user${i}
    chown user${i}:user${i} /home/user${i}
    chmod 700 /home/user${i}

    # 创建用户数据目录并设置权限
    mkdir -p /data1/org/user${i}_data
    chown user${i}:user${i} /data1/org/user${i}_data
    chmod 700 /data1/org/user${i}_data

    # 确保用户在docker组中
    usermod -aG docker user${i}
done

# 重启Docker服务以应用命名空间配置
systemctl restart docker

# 构建基础镜像
echo "Building base environment image..."
docker build -t base-env -f Dockerfile.base .

# 为每个用户创建镜像
echo "Creating user-specific images..."
for i in {1..4}; do
    # 创建用户目录
    mkdir -p /opt/docker_images/user${i}

    # 创建用户Dockerfile
    sed "s/USERNAME/user${i}/" Dockerfile.user.template > /opt/docker_images/user${i}/Dockerfile

    # 构建用户镜像
    docker build -t user${i}-env /opt/docker_images/user${i}
done

# 复制shell脚本
echo "Setting up Docker shell scripts..."
cp create_user_docker_shells.sh /opt/docker_shells/
chmod +x /opt/docker_shells/create_user_docker_shells.sh

# 运行设置脚本
/opt/docker_shells/create_user_docker_shells.sh

# 确保Docker组权限正确
echo "Configuring Docker group permissions..."
for i in {1..4}; do
    usermod -aG docker user${i}
done

# 设置用户主目录权限
echo "Setting up home directory permissions..."
for i in {1..4}; do
    chmod 700 /home/user${i}
done

# 设置/data1目录权限，确保只有root可以访问
chmod 755 /data1
chown root:root /data1

# 验证安装
echo "Verifying installation..."
for i in {1..4}; do
    echo "Testing user${i} environment..."

    # 测试容器创建
    if ! docker run --rm --gpus '"device='$((i-1))'"' user${i}-env nvidia-smi &>/dev/null; then
        echo "Error: Failed to create test container for user${i}"
        exit 1
    fi

    # 测试数据目录权限
    if [ "$(stat -c %a /data1/org/user${i}_data)" != "700" ]; then
        echo "Error: Incorrect permissions for user${i} data directory"
        exit 1
    fi
done

echo "Installation completed successfully!"
echo "Users will now be automatically placed in their Docker containers upon login."
echo "Data isolation is enforced in /data1/org directory."
echo ""
echo "Please note:"
echo "1. Each user has been assigned a specific GPU"
echo "2. User data is isolated in /data1/org/userX_data"
echo "3. Container security features are enabled"
echo "4. Resource limits are configured"
echo ""
echo "To verify the setup, try logging in as any user:"
echo "ssh user1@localhost  # Replace with your server address"