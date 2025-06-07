---
marp: true
theme: default
paginate: true
header: '`install.sh` 完整代码逐行详解'
footer: 'Marp Presentation - Verbatim Code Coverage'
---

# Docker环境安装脚本详解
## install.sh 脚本分析

---

### 1. 脚本标头与错误处理

这部分定义了脚本解释器，并设置了严格的错误处理机制。
- `set -e`: 任何命令执行失败，脚本将立即终止。
- `trap`: 捕获 `ERR` 信号（错误发生时），并打印出错的行号。

```bash
#!/bin/bash
# install.sh (v6 - The Final Fix)

# 设置错误处理
set -e
trap 'echo "Error: Command failed at line $LINENO"' ERR
```

---

### 2. Root 权限检查

确保执行脚本的用户是 root 用户，因为后续操作（如创建用户、修改系统目录）需要超级用户权限。

```bash
# 检查是否以root运行
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi
```

---

### 3. 创建基础目录

创建脚本运行所必需的两个核心目录：
- `/opt/docker_images`: 用于存放为每个用户动态生成的 Dockerfile。
- `/data1/org/user_workspaces`: 作为挂载到容器中的用户工作区数据卷。

```bash
# 创建必要的目录
echo "Creating necessary directories..."
mkdir -p /opt/docker_images
mkdir -p /data1/org/user_workspaces
```

---

### 4. 用户创建与配置 (循环 1/4)

开始循环创建3个用户 (`user1` 到 `user3`)。
首先，定义用户名和家目录变量。接着，检查用户是否已存在，如果存在，则使用 `-r` 选项彻底删除该用户及其家目录，以确保环境的纯净。

```bash
# 创建用户并配置
for i in {1..3}; do
    username="user${i}"
    user_home="/home/$username"

    # 用 -r 选项确保完全删除旧用户
    if id "$username" &>/dev/null; then
        userdel -r "$username" 2>/dev/null || true
    fi
```

[用户创建与配置详解 - 第一部分](marp-level-1/user_creation_part1.md)

---

### 5. 用户创建与配置 (循环 2/4)

继续用户配置流程：
- `useradd`: 创建新用户，并设置其默认 shell 为 `/bin/bash`。
- `openssl rand`: 生成一个随机的高强度密码。
- `chpasswd`: 为用户设置密码。
- `usermod`: 将用户添加到 `docker` 组，使其有权限运行 Docker 命令。

```bash
    useradd -m -s /bin/bash "$username"
    echo "Created user: $username"

    password="$(openssl rand -base64 12 | tr -d '=')"
    echo "$username:$password" | chpasswd
    echo "Password for $username: $password"

    usermod -aG docker "$username"
```

---

### 6. 用户创建与配置 (循环 3/4) - 工作目录设置

设置用户的工作目录：
- 创建专属工作目录并赋予正确的权限
- 在用户家目录下创建符号链接

```bash
    user_work_dir="/data1/org/user_workspaces/$username"
    mkdir -p "$user_work_dir"
    chown "$username":"$username" "$user_work_dir"
    chmod 700 "$user_work_dir"

    ln -sf "$user_work_dir" "$user_home/work"
```

---

### 7. 用户创建与配置 (循环 3/4) - 登录提示配置

配置用户的登录提示信息：
- 创建 `.bash_profile` 文件
- 当用户在主机登录时，提示如何进入 Docker 容器

```bash
    docker_name="${username}-container"
    cat > "$user_home/.bash_profile" <<EOF
if [ -z "\$INSIDE_DOCKER" ]; then
    echo "You are on the host. To enter your Docker container, run:"
    echo "docker exec -it ${docker_name} bash --login"
fi
EOF
    chown "$username":"$username" "$user_home/.bash_profile"
```

[用户登录提示配置详解](marp-level-1/login_prompt_explanation.md)


---

### 8. 用户创建与配置 (循环 4/4)

为主机上的用户生成 SSH 密钥，并结束第一个循环。
- 该密钥的公钥 (`id_ed25519.pub`) 将被注入到该用户的 Docker 容器中，以实现免密码 SSH 登录容器。

```bash
    # 在宿主机上为用户创建SSH密钥
    mkdir -p "$user_home/.ssh"
    chown "$username":"$username" "$user_home/.ssh"
    chmod 700 "$user_home/.ssh"
    if [ ! -f "$user_home/.ssh/id_ed25519" ]; then
        echo "Generating SSH key for host user $username..."
        sudo -u "$username" ssh-keygen -t ed25519 -f "$user_home/.ssh/id_ed25519" -N ""
    fi
done
```

---

### 9. 构建基础 Docker 镜像

使用 `Dockerfile.base` 文件构建一个名为 `base-env` 的基础镜像。这个镜像包含了所有用户容器共享的通用环境和工具（例如 SSH 服务）。

```bash
# 构建基础镜像
echo "Building base environment image..."
docker build -t base-env -f Dockerfile.base .
```

---

### 10. 用户专属镜像创建 (循环 1/3)

开始第二个循环，为每个用户创建一个专属的 Docker 镜像。
- 首先获取用户的 UID、GID 和先前生成的 SSH 公钥内容。这些变量将被用于动态生成 Dockerfile。

```bash
# 为每个用户创建镜像
for i in {1..3}; do
    username="user${i}"
    uid=$(id -u "$username")
    gid=$(id -g "$username")
    user_pubkey=$(cat "/home/$username/.ssh/id_ed25519.pub")
```

---

### 11. 用户专属镜像创建 (循环 2/3)

准备生成 Dockerfile 的路径，并使用 `cat` 和 `EOF` (Here Document) 的方式动态写入 Dockerfile 内容。

```bash
    echo "Creating image for $username (UID=$uid, GID=$gid)..."
    image_dir="/opt/docker_images/$username"
    mkdir -p "$image_dir"
    dockerfile_path="$image_dir/Dockerfile"

    # --- [最终修正] ---
    # 删除了所有的 `USER` 指令。让容器以 root 身份启动 sshd 服务。
    cat > "$dockerfile_path" <<EOF
# User-specific Dockerfile (Final Version)
FROM base-env
```
*(Dockerfile 内容在下一页)*

---

### 12. 动态 Dockerfile 内容概述

Dockerfile 的核心指令主要分为两个部分：
1. 用户和组配置
2. SSH 环境设置

容器将以 root 启动 `sshd`，用户通过 SSH 登录后会自动切换到自己的身份。

---

### 13. Dockerfile 用户配置部分

这部分配置确保容器内的用户与主机系统保持一致：
- 创建与主机相同 UID/GID 的用户和组
- 配置 sudo 权限
- 设置用户的基本环境

```dockerfile
# 创建用户和组 (以 root 权限)
RUN groupadd -g ${gid} ${username} \\
    && useradd -u ${uid} -g ${gid} -m -s /bin/bash ${username} \\
    && echo "${username} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${username} \\
    && chmod 0440 /etc/sudoers.d/${username}
```

[Dockerfile 用户配置详解](marp-level-1/dockerfile_user_config.md)

---

### 14. Dockerfile SSH 配置部分

这部分设置用户的 SSH 访问环境：
- 创建 SSH 目录结构
- 配置授权密钥
- 设置正确的权限

```dockerfile
# 创建用户的 SSH 环境 (仍然以 root 权限)
RUN mkdir -p /home/${username}/.ssh && \\
    echo "${user_pubkey}" > /home/${username}/.ssh/authorized_keys && \\
    chown -R ${uid}:${gid} /home/${username}/.ssh && \\
    chmod 700 /home/${username}/.ssh && \\
    chmod 600 /home/${username}/.ssh/authorized_keys
```

---

### 15. Dockerfile 配置说明

关于 Dockerfile 的一些重要说明：
- 不再需要 `USER` 指令，因为容器以 root 身份运行 sshd
- 不需要 `WORKDIR` 指令，因为 sshd 会自动处理工作目录
- 不需要 `ENV` 指令，因为环境变量会在用户登录时自动设置

```dockerfile
# 不再需要 USER, WORKDIR, ENV 指令，sshd 会自动处理
EOF
```

---

### 16. 用户专属镜像创建 (循环 3/3)

使用刚刚生成的 Dockerfile，构建一个以用户名命名的专属 Docker 镜像 (`user1-env`, `user2-env` 等)，并结束第二个循环。

```bash
    # 构建命令
    docker build -t "${username}-env" "$image_dir"
done
```

---

### 17. 容器创建与启动 (循环 1/3)

开始第三个循环，为每个用户启动一个容器。
- 设置容器名称、SSH 端口号。
- 使用 `case` 语句为每个用户分配不同的 GPU 设备。

```bash
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
```

---

### 18. 容器创建与启动 (循环 2/3)

在启动前，先检查是否存在同名的旧容器，如果存在，则强制删除它，确保每次运行的都是最新的配置。

```bash
    if docker ps -a --format '{{.Names}}' | grep -q "^${docker_name}"; then
        docker rm -f "$docker_name" >/dev/null 2>&1 || true
    fi
```

---

### 19. 容器创建与启动 (循环 3/3)

执行 `docker run` 命令，创建并以后台模式 (`-dit`) 启动容器。
- `--name`, `--hostname`: 设置容器名和主机名。
- `--restart`: 设置重启策略。
- `--gpus`, `--cpus`, `--memory`: 分配硬件资源。
- `-v`: 将主机的工作目录挂载到容器内。
- `-p`: 将主机的端口映射到容器的22端口 (SSH)。

```bash
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
```

---

### 20. 脚本执行完毕

所有循环都已完成，打印最后的成功信息，脚本正常退出。

```bash
echo "Installation script finished. The setup should now be complete and correct."
```

---

# 谢谢观看
## All code from `install.sh` has been covered verbatim.

---

# 脚本概述

- 主要功能：自动化部署Docker环境
- 目标：为多个用户创建隔离的Docker容器环境

---

# 基础设置部分

```bash
#!/bin/bash
# install.sh (v6 - The Final Fix)

# 设置错误处理
set -e
trap 'echo "Error: Command failed at line $LINENO"' ERR
```

- `set -e`: 遇到错误立即退出
- `trap`: 错误处理机制，显示错误行号

---

# 权限检查

```bash
# 检查是否以root运行
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi
```

- 确保脚本以root权限运行
- 非root用户将无法执行安装

---

# 目录创建

```bash
# 创建必要的目录
echo "Creating necessary directories..."
mkdir -p /opt/docker_images
mkdir -p /data1/org/user_workspaces
```

- 创建Docker镜像存储目录
- 创建用户工作空间目录

---

# 用户创建流程

```bash
for i in {1..3}; do
    username="user${i}"
    user_home="/home/$username"

    # 删除已存在的用户
    if id "$username" &>/dev/null; then
        userdel -r "$username" 2>/dev/null || true
    fi
```

- 循环创建3个用户
- 确保用户不存在，避免冲突

---

# 用户配置

```bash
    useradd -m -s /bin/bash "$username"
    password="$(openssl rand -base64 12 | tr -d '=')"
    echo "$username:$password" | chpasswd
    usermod -aG docker "$username"
```

- 创建用户并设置bash shell
- 生成随机密码
- 将用户添加到docker组

---

# 工作目录设置

```bash
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
```

- 创建用户工作目录
- 设置正确的权限
- 创建符号链接
- 定义Docker容器名称
- 配置用户登录提示信息

---

# SSH配置

```bash
    mkdir -p "$user_home/.ssh"
    chown "$username":"$username" "$user_home/.ssh"
    chmod 700 "$user_home/.ssh"
    if [ ! -f "$user_home/.ssh/id_ed25519" ]; then
        sudo -u "$username" ssh-keygen -t ed25519 -f "$user_home/.ssh/id_ed25519" -N ""
    fi
```

- 配置SSH密钥
- 设置安全的SSH目录权限

---

# Docker镜像构建

```bash
# 构建基础镜像
echo "Building base environment image..."
docker build -t base-env -f Dockerfile.base .
```

- 构建基础Docker镜像
- 为后续用户镜像提供基础环境

---

# 用户镜像创建

```bash
for i in {1..3}; do
    username="user${i}"
    uid=$(id -u "$username")
    gid=$(id -g "$username")
    user_pubkey=$(cat "/home/$username/.ssh/id_ed25519.pub")
```

- 为每个用户创建专属Docker镜像
- 获取用户ID和SSH公钥

---

# Dockerfile生成

```bash
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
```

- 生成用户特定的Dockerfile
- 配置用户权限和环境
- 设置SSH访问权限
- 配置sudo权限

---

# 容器创建和启动

```bash
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
```

- 创建并启动用户容器
- 配置资源限制和挂载点
- 设置GPU分配和端口映射

---

# 总结

- 自动化部署Docker环境
- 多用户隔离
- 资源分配管理
- 安全性考虑
- 完整的错误处理

---

# 谢谢观看
## 如有问题，欢迎讨论
