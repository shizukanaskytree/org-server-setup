<!-- ---
marp: true
author: wxf
size: 4:3
theme: gaia
--- -->

<!-- I am also using marp so do not delete `---` -->

# 多用户下 Docker 环境设置指南

---

## 0. 项目文件结构

```
slurm_docker_setup/
├── Dockerfile.base              # 基础环境 Dockerfile，包含 CUDA、Python 等基础开发环境
├── Dockerfile.user.template     # 用户镜像模板，用于生成具体用户的 Docker 镜像
├── create_user_docker_shells.sh # 创建用户 Docker 环境，包括 shell 脚本、GPU 分配等
├── install.sh                   # 主安装脚本，用于安装依赖、构建镜像、配置系统
├── migrate_to_org.sh           # 数据迁移脚本，用于迁移用户数据到新的组织结构
├── remove_user_docker.sh       # 清理脚本，用于删除用户容器和镜像
└── README.md                   # 项目说明文档
```

### 0.1 核心文件说明

1. **Dockerfile.base**
   - 作用：构建基础环境镜像
   - 包含：CUDA、Python、基础开发工具等
   - 使用：作为所有用户镜像的基础

2. **Dockerfile.user.template**
   - 作用：用户镜像模板
   - 包含：用户特定的配置
   - 使用：通过替换 USERNAME 创建具体用户镜像

3. **create_user_docker_shells.sh**
   - 作用：创建用户 Docker 环境
   - 功能：
     - 创建用户专属的 Docker shell 脚本
     - 配置 GPU 设备分配
     - 设置挂载点和安全选项

4. **install.sh**
   - 作用：主安装脚本
   - 功能：
     - 安装依赖
     - 构建基础镜像
     - 创建用户环境
     - 配置系统设置

5. **migrate_to_org.sh**
   - 作用：数据迁移脚本
   - 功能：
     - 将用户数据迁移到新的组织结构
     - 保持权限和所有权
     - 验证数据完整性

6. **remove_user_docker.sh**
   - 作用：清理脚本
   - 功能：
     - 删除用户容器
     - 清理用户镜像
     - 移除相关配置

---

## 1. 环境要求
- Docker
- NVIDIA Container Toolkit
- Slurm

---

## 2. 业务流程图

### 2.1 用户环境创建流程
```
[创建用户环境]
    开始
      ↓
[构建基础镜像] → [安装基础软件] → [配置 CUDA] → [设置 Python]
      ↓
[创建用户目录] → [设置权限] → [创建数据目录]
      ↓
[创建用户镜像] → [基于基础镜像] → [添加用户配置]
      ↓
[配置 Shell] → [设置自动登录] → [配置 GPU 访问]
      ↓
    完成
```

---

### 2.2 数据存储路径迁移流程

```
[数据迁移详细流程]
    开始
      ↓
[1. 环境检查]
    ├── 检查 root 权限
    ├── 检查目录位置
    └── 检查用户容器状态
      ↓
[2. 停止并清理]
    ├── 停止所有用户容器
    ├── 删除所有用户容器
    └── 删除所有用户镜像
      ↓
[3. 数据备份]
    ├── 检查源目录是否存在
    ├── 创建备份目录
    └── 复制数据到备份目录
      ↓
[4. 创建新结构]
    ├── 创建 /data1/org 目录
    ├── 为每个用户创建数据目录
    └── 设置正确的权限
      ↓
[5. 移动数据]
    ├── 从旧位置移动数据
    ├── 保持文件权限
    └── 验证数据完整性
      ↓
[6. 重建环境]
    ├── 重新创建用户镜像
    ├── 配置新的挂载点
    └── 创建新的容器
      ↓
[7. 验证迁移]
    ├── 检查目录结构
    ├── 验证数据访问
    └── 测试容器功能
      ↓
    完成

[迁移后的目录结构]
/data1/
  └── org/
      ├── user1_data/  (700权限)
      ├── user2_data/  (700权限)
      ├── user3_data/  (700权限)
      └── user4_data/  (700权限)

[迁移后的容器配置]
容器挂载点:
  - /workspace      -> /home/userX
  - /workspace/data -> /data1/org/userX_data
```

---

### 2.3 用户环境管理流程
```
[用户管理]
    开始
      ↓
[选择操作] → [创建/删除/修改]
      ↓
[创建用户] → [设置目录] → [配置容器]
      ↓
[删除用户] → [清理容器] → [删除数据]
      ↓
[修改配置] → [更新设置] → [重启容器]
      ↓
    完成
```

---

### 2.4 故障恢复流程
```
[故障恢复]
    开始
      ↓
[检测故障] → [容器/数据/权限]
      ↓
[容器故障] → [检查状态] → [重启容器]
      ↓
[数据故障] → [检查备份] → [恢复数据]
      ↓
[权限故障] → [检查权限] → [修复权限]
      ↓
[验证恢复] → [测试功能] → [确认正常]
      ↓
    完成
```

---

## 3. 目录结构
```
slurm_docker_setup/
├── Dockerfile.base  # 基础环境 Dockerfile
├── create_user_docker_shells.sh  # 创建用户 Docker shell 脚本
└── README.md  # 说明文档

系统目录:
/opt/docker_shells/  # Docker shell 脚本存储目录
    ├── create_user_docker_shells.sh  # 主控制脚本
    └── user{1-4}_shell.sh           # 用户专属 shell 脚本
```

### 3.1 为什么需要 /opt/docker_shells？

`/opt/docker_shells` 是整个 Docker 容器化登录系统的核心目录，它的主要作用是：

1. **集中管理**
   - 存放所有与 Docker 容器化登录相关的脚本
   - 便于系统管理员统一管理和维护
   - 符合 Linux 文件系统层次标准（FHS）

2. **安全性**
   - 目录需要 root 权限才能访问
   - 防止普通用户篡改登录行为
   - 确保系统安全性

3. **功能实现**
   - 存放用户专属的 shell 脚本（user{1-4}_shell.sh）
   - 每个脚本负责：
     - 创建和管理用户的 Docker 容器
     - 配置 GPU 设备分配
     - 设置挂载点和安全选项

4. **工作流程**
```
[用户登录]
    ↓
[PAM认证]
    ↓
[user{1-4}_shell.sh] ← 存放在 /opt/docker_shells/
    ↓
[创建/启动容器]
    ↓
[用户进入容器环境]
```

5. **实际例子**
```bash
# 当用户 user1 登录时：
1. 系统调用 /opt/docker_shells/user1_shell.sh
2. 脚本检查 user1 的容器状态
3. 创建或启动容器
4. 用户进入容器环境
```

---

## 4. 设置步骤

### 4.1 构建基础镜像
```bash
sudo docker build -t base-env -f Dockerfile.base .
```

### 4.2 创建用户 Docker 环境
```bash
sudo bash create_user_docker_shells.sh
```

---

这个脚本会：
- 为每个用户创建专属的 Docker shell 脚本
- 分配特定的 GPU 设备
- 设置必要的挂载点和安全选项
- 配置用户登录时自动进入 Docker 容器

---

### 4.3 用户环境说明
- 每个用户都有独立的 Docker 容器
- 容器会自动分配特定的 GPU 设备
- 用户数据持久化存储在挂载的目录中
- 容器环境包含必要的开发工具和依赖

---

### 4.4 安全特性
- 容器使用 no-new-privileges 安全选项
- 限制容器权限，只保留必要的能力
- 用户数据通过挂载点隔离
- 限制容器资源使用
- 配置日志监控

> ⚠️ 注意：用户命名空间隔离（--userns-remap）已从容器配置中移除，且 Docker daemon 配置为禁用 userns-remap（`"userns-remap": ""`）。这样可以避免 UID 映射导致的挂载权限问题，确保容器内用户能正常访问挂载的数据目录。数据隔离依然通过目录权限实现。

### 4.5 Docker 守护进程配置

Docker 守护进程配置文件 `/etc/docker/daemon.json` 当前内容如下：

```json
{
    "data-root": "/data/docker",
    "runtimes": {
        "nvidia": {
            "args": [],
            "path": "nvidia-container-runtime"
        }
    },
    "userns-remap": ""
}
```

**说明：**
- `"userns-remap": ""` 表示已禁用 Docker 用户命名空间映射。
- 这样配置后，容器内的 UID/GID 与宿主机一致，避免了因 UID 映射不一致导致的挂载目录权限问题。
- 这样做的目的是保证容器内用户能无障碍访问宿主机挂载的数据目录（如 `/data1/org/userX_data`），同时依然通过目录权限实现用户间数据隔离。
- 只要宿主机的数据目录权限设置为 700 且属主为 userX，其他用户和容器就无法访问。

**影响：**
- 容器内用户与宿主机用户权限一致，便于数据共享和权限管理。
- 牺牲了一定的用户命名空间安全隔离，但对于本场景（多用户数据隔离、管理员可控）是合理权衡。

### 4.6 Slurm 集成
在 Docker 容器中配置 Slurm 客户端：

```bash
# 在 Dockerfile.base 中添加
RUN apt-get install -y slurm-client slurm-wlm

# 配置 Slurm 客户端
RUN mkdir -p /etc/slurm && \
    echo "accounting_storage_host=slurm-master" > /etc/slurm/slurm.conf && \
    echo "accounting_storage_port=6819" >> /etc/slurm/slurm.conf

# 在容器中配置 Slurm 环境变量
ENV SLURM_CONF=/etc/slurm/slurm.conf
```

---

#### 容器生命周期说明

当用户在容器内执行 `exit` 退出后，容器会停止（状态变为 Exited），但容器本身及其数据、环境配置均被保留。下次用户登录时，系统会自动检测到容器已停止，并执行 `docker start` 和 `docker attach`，从而恢复上次的环境。

**ASCII 概览图（Overview）**

```
[容器生命周期]
    开始
      ↓
[创建容器] → [运行容器] → [exit 退出]
      ↓
[容器停止] → [容器保留] → [数据持久化]
      ↓
[下次登录] → [自动启动] → [恢复环境]
      ↓
    完成
```

**验证方法**

1. 登录 user1，进入容器后执行 `exit` 退出。
2. 在主机上运行：
   ```bash
   docker ps -a | grep user1-session
   ```
   状态应为 `Exited`（已停止）。
3. 再次登录 user1，容器会自动启动（状态变为 `Up`），环境恢复。

**关键原理（ASCII 概览）**

```
[登录] → [容器不存在] → 创建并进入
      → [容器已停止] → 启动并进入
      → [容器已运行] → 直接进入
[exit] → [容器停止但保留]
```

如需彻底删除容器，请使用 `docker rm user1-session`。
如只需退出，直接 `exit` 即可，数据和环境都安全！

---

## 5. 使用说明
1. 用户登录后会自动进入其专属的 Docker 容器
2. 容器环境已经配置好 GPU 访问权限
3. 用户可以在 /workspace 目录下进行开发工作
4. 数据持久化存储在 /workspace/data 目录

## 6. 注意事项
- 确保 Docker 和 NVIDIA Container Toolkit 已正确安装
- 检查 GPU 设备分配是否正确
- 定期备份用户数据
- 监控容器资源使用情况

---

## 1. 快速开始

### 1.1 系统要求
- Ubuntu 24.04 LTS
- CUDA 12.8
- Docker
- NVIDIA GPU 驱动
- NVIDIA Container Toolkit
- Slurm

---

### 1.2 安装步骤
```bash
# 1. 克隆仓库
git clone <repository-url>
cd slurm_docker_setup

# 2. 安装 NVIDIA Container Toolkit
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# 3. 构建基础镜像
sudo docker build -t base-env -f Dockerfile.base .

# 4. 创建用户数据目录
sudo mkdir -p /data1/org
for i in {1..4}; do
    sudo mkdir -p /data1/org/user${i}_data
    sudo chown user$i:user$i /data1/org/user${i}_data
    sudo chmod 700 /data1/org/user${i}_data
done

# 5. 设置用户 shell 脚本
sudo bash create_user_docker_shells.sh

# 6. 构建用户镜像
for i in {1..4}; do
    sed "s/USERNAME/user$i/g" Dockerfile.user.template > Dockerfile.user$i
    sudo docker build -t user$i-env -f Dockerfile.user$i .
done
```

### 1.3 目录迁移（如果需要）
如果是从旧版本升级，需要迁移用户数据目录到新的组织结构：

```bash
# 1. 进入 slurm_docker_setup 目录
cd slurm_docker_setup

# 2. 确保所有用户都已退出容器
# 检查是否有容器在运行
docker ps | grep user

# 3. 执行迁移脚本
sudo bash migrate_to_org.sh

# 迁移脚本会：
# - 检查运行环境（root权限、目录位置）
# - 检查是否有用户容器在运行
# - 创建新的目录结构 /data1/org
# - 停止并删除现有容器
# - 移动用户数据到新位置（自动备份已存在的目录）
# - 重新创建 Docker shell 脚本
# - 验证迁移结果
# - 保持所有数据不变
# - 保持所有权限设置不变

# 4. 迁移完成后，用户需要重新登录
# 新的容器会自动使用新的目录结构
```

#### 迁移后的验证
```bash
# 1. 检查目录结构
ls -l /data1/org/

# 2. 检查目录权限
for i in {1..4}; do
    echo "=== user$i ==="
    ls -ld /data1/org/user${i}_data
done

# 3. 检查 Docker 配置
cat /opt/docker_shells/user1_shell.sh | grep "/data1/org"

# 4. 测试用户登录
ssh user1@localhost  # 替换为实际的服务器地址
# 登录后检查：
# - nvidia-smi 命令是否正常
# - /workspace/data 目录是否正确映射
# - 数据文件是否完整
```

#### 故障排除
如果迁移后遇到问题：

1. **目录权限问题**：
```bash
# 检查并修复权限
sudo chown -R user1:user1 /data1/org/user1_data
sudo chmod 700 /data1/org/user1_data
```

2. **容器启动问题**：
```bash
# 检查容器日志
docker logs user1-session

# 重新创建容器
sudo bash create_user_docker_shells.sh
```

3. **数据访问问题**：
```bash
# 检查挂载点
docker inspect user1-session | grep -A 10 Mounts

# 检查目录映射
ls -l /workspace/data  # 在容器内执行
```

4. **恢复备份**：
```bash
# 如果迁移出现问题，可以恢复备份
sudo mv /data1/org/user1_data.bak.* /data1/org/user1_data
sudo chown -R user1:user1 /data1/org/user1_data
sudo chmod 700 /data1/org/user1_data
```

### 1.4 验证安装
```bash
# 1. 检查 NVIDIA Container Toolkit
docker info | grep -i runtime  # 应显示 nvidia runtime
# 预期输出：
# Runtimes: io.containerd.runc.v2 nvidia runc
# Default Runtime: runc

# 2. 检查 NVIDIA 驱动
nvidia-smi  # 应显示 GPU 信息
# 预期输出：显示所有可用的 GPU 及其状态

# 3. 检查 Docker 镜像
docker images | grep -E "base-env|user[1-4]-env"
# 预期输出：显示所有用户镜像
# 注意：虽然每个镜像显示的大小都是 16.4GB，但实际存储空间要小得多
# 因为 Docker 使用分层存储，基础镜像的层是共享的

# 检查实际使用的磁盘空间
docker system df -v  # 显示 Docker 使用的实际磁盘空间

# 4. 检查用户目录和权限
ls -l /data1  # 检查数据目录权限
for i in {1..4}; do
    echo "=== user$i ==="
    ls -l /data1/org/user${i}_data  # 检查用户数据目录
    groups user$i  # 检查用户组
done

# 5. 验证 GPU 访问
# 测试基础 GPU 访问
docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu24.04 nvidia-smi

# 测试用户容器 GPU 访问
for i in {1..4}; do
    echo "=== Testing user$i container ==="
    docker run --rm --gpus '"device='$((i-1))'"' nvidia/cuda:12.8.0-base-ubuntu24.04 nvidia-smi
done

# 6. 验证用户登录
# 使用 SSH 登录测试
ssh user1@localhost  # 替换为实际的服务器地址
# 登录后应自动进入 Docker 容器
# 在容器内执行：
nvidia-smi  # 应只显示分配的 GPU
python -c "import torch; print('Available GPUs:', torch.cuda.device_count())"  # 应显示 1

# 7. 验证 Slurm 配置
# 在容器内执行
sinfo  # 应显示 Slurm 节点信息
squeue  # 应显示作业队列
```

### 1.5 用户首次登录常见问题与修复

#### 现象一：登录后提示 docker 权限不足

```
permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: ...
```

**原因**：新创建的用户（如 user1）默认没有加入 docker 组，无法访问 Docker 服务。

**修复方法**：
```bash
sudo usermod -aG docker user1
```
> ⚠️ 修改后需要重新登录（或重启服务器），让组权限生效。

#### 现象二：home 目录权限异常

```
ls: cannot open directory '/home/user1': Permission denied
```

**原因**：/home/user1 目录权限或所有者不正确，导致容器挂载时权限异常。

**修复方法**：
```bash
sudo chown -R user1:user1 /home/user1
```

#### 现象三：首次登录后未进入容器或容器报错

- 检查 shell 是否已正确指向 /opt/docker_shells/user1_shell.sh
- 检查 /opt/docker_shells/user1_shell.sh 是否有执行权限
- 检查 /data1/org/user1_data 权限

**修复方法**：
```bash
# 检查 shell
getent passwd user1
# 检查脚本权限
ls -l /opt/docker_shells/user1_shell.sh
# 检查数据目录权限
ls -ld /data1/org/user1_data
```
如有问题，分别用 chown/chmod 修复。

#### 现象四：容器内无法访问 GPU

- 检查 nvidia-smi 是否正常
- 检查 docker run --gpus all 是否能访问 GPU

**修复方法**：
参考 1.4 验证安装部分。

#### 现象五：主机上无法直接访问 /data1/org/userX_data 目录

**管理员访问方法**：

- **临时访问**：使用 `sudo -s` 或 `sudo -i` 切换到 root 用户，然后进入目录：
  ```bash
  sudo -s
  cd /data1/org/user1_data
  ```

- **永久访问**：将目录权限修改为 755，允许所有用户读取：
  ```bash
  sudo chmod 755 /data1/org/user1_data
  ```
  > ⚠️ 注意：修改权限可能影响安全性，请谨慎操作。

---

## 2. 用户管理

---

### 2.1 创建新用户
```bash
# 使用单个用户设置脚本（推荐）
sudo bash setup_single_user.sh <username> <gpu_id> [password]

# 参数说明：
# - username: 用户名（例如：user1, user2 等）
# - gpu_id: 分配的 GPU ID (0-5)
# - password: 可选的用户密码（如果不提供，需要手动设置）

# GPU 分配说明：
# 0: RTX 4090 D (24GB) - 适合 user1
# 1: RTX 4090 D (24GB) - 适合 user2
# 2: RTX 4090 D (24GB) - 适合 user3
# 3: RTX 4090 D (24GB) - 适合 user4
# 4: H100 (80GB) - 保留给系统使用
# 5: A100 (80GB) - 保留给系统使用

# 使用示例：
# 创建 user1，使用 GPU 0
sudo bash setup_single_user.sh user1 0 mypassword123

# 创建 user2，使用 GPU 1
sudo bash setup_single_user.sh user2 1 mypassword456

# 创建 user3，使用 GPU 2（不设置密码，稍后手动设置）
sudo bash setup_single_user.sh user3 2
sudo passwd user3  # 手动设置密码
```

---

### 2.2 验证用户设置
```bash
# 1. 检查用户创建
id user1  # 应显示用户信息

# 2. 检查 Docker 权限
groups user1  # 应包含 docker 组

# 3. 检查数据目录
ls -l /data1/org/user1_data  # 应显示正确的权限和所有者

# 4. 登录测试
ssh user1@172.30.101.111

# 5. 在容器内验证 GPU 访问
nvidia-smi  # 应只显示分配的 GPU
python -c "import torch; print('Available GPUs:', torch.cuda.device_count())"  # 应显示 1
```

---

### 2.3 删除和重建用户

```bash
# 1. 删除用户环境
sudo bash remove_user_docker.sh userX

# 脚本会执行以下操作：
# - 停止并删除用户的 Docker 容器
# - 删除用户的 Docker 镜像
# - 清理用户的 shell 脚本
# - 询问是否删除用户数据目录（输入 y 确认删除）
# - 恢复用户的默认 shell
# - 从 Docker 组移除用户

# 2. 重新创建用户环境
sudo bash setup_single_user.sh userX <gpu_id> [password]

# 例如：重新创建 user1，限制只能使用 GPU 0
sudo bash setup_single_user.sh user1 0 mypassword123
```

---

### 2.4 用户环境说明

每个用户的环境包括：

1. 系统用户：
   - 用户名：userX
   - 主目录：/home/userX
   - 默认 shell：自定义 Docker shell

---

2. Docker 环境：
   - 容器名：userX-session
   - 镜像名：userX-env
   - 基于：base-env 镜像
   - GPU 访问：限制为指定的 GPU ID

---

3. 存储空间：
   - 代码目录：/workspace（映射自 /home/userX）
   - 数据目录：/workspace/data（映射自 /data1/org/userX_data）

---

4. GPU 访问：
   - 每个用户只能访问分配的 GPU
   - 通过 NVIDIA Container Toolkit 实现隔离
   - 可以通过 nvidia-smi 命令验证 GPU 访问限制

---

### 2.5 常见问题

Q: 如何更改用户的 GPU 分配？
A: 需要重新创建用户环境：
```bash
# 1. 删除现有环境
sudo bash remove_user_docker.sh userX
# 当询问是否删除数据目录时，根据需求选择：
# - 输入 y：完全删除用户数据（测试环境）
# - 输入 n：保留用户数据（生产环境）

# 2. 重新创建环境（使用新的 GPU ID）
sudo bash setup_single_user.sh userX <new_gpu_id> [password]
```

---

Q: 如何验证 GPU 访问限制？
A: 在容器内执行以下命令：
```bash
# 1. 查看可用的 GPU
nvidia-smi  # 应只显示分配的 GPU

# 2. 验证 PyTorch 中的 GPU 访问
python -c "import torch; print('Available GPUs:', torch.cuda.device_count())"  # 应显示 1

# 3. 尝试访问其他 GPU（应该失败）
python -c "import torch; torch.cuda.set_device(1)"  # 如果分配的是 GPU 0，这应该报错
```

---

Q: 如何备份用户数据？
A: 用户数据存储在 /data1/org/userX_data 目录：
```bash
# 备份数据
sudo tar -czf userX_backup.tar.gz /data1/org/userX_data

# 恢复数据
sudo tar -xzf userX_backup.tar.gz -C /data1/org/
sudo chown -R userX:userX /data1/org/userX_data
```

---

Q: 如何查看用户的 GPU 使用情况？
A: 在容器内使用 nvidia-smi 命令：
```bash
# 在容器内执行
nvidia-smi  # 显示 GPU 使用情况
nvidia-smi dmon  # 实时监控 GPU 使用情况
```

---

## 3. 系统维护

### 3.1 日常检查
```bash
# 检查 Docker 状态
docker ps -a  # 查看所有容器（包括运行中和已停止的）
docker ps     # 只查看运行中的容器
docker stats  # 查看容器资源使用情况

# 检查存储空间
df -h /data1
du -sh /data1/org/user*_data
```

### 3.2 容器管理指南

#### 3.2.1 查看容器状态

1. **查看所有容器**
```bash
docker ps -a
# 输出示例：
# CONTAINER ID   IMAGE       COMMAND                  CREATED          STATUS         PORTS     NAMES
# bd18fc919ff0   user1-env   "/opt/nvidia/nvidia_…"   18 minutes ago   Up 5 minutes             user1-session
```

2. **查看运行中的容器**
```bash
docker ps
```

3. **查看特定用户的容器**
```bash
docker ps -a | grep user1-session
```

4. **查看容器资源使用情况**
```bash
docker stats --no-stream
# 输出示例：
# CONTAINER ID   NAME            CPU %     MEM USAGE / LIMIT     MEM %     NET I/O         BLOCK I/O   PIDS
# bd18fc919ff0   user1-session   0.00%     1.543MiB / 251.5GiB   0.00%     3.61kB / 126B   0B / 0B     1
```

#### 3.2.2 容器生命周期管理

```
[容器生命周期]
    开始
      ↓
[创建容器] → [运行容器] → [exit 退出]
      ↓
[容器停止] → [容器保留] → [数据持久化]
      ↓
[下次登录] → [自动启动] → [恢复环境]
      ↓
    完成
```

1. **清理已停止的容器**
```bash
# 清理所有已停止的容器
docker container prune -f

# 清理特定用户的容器
docker rm $(docker ps -a | grep user1-session | awk '{print $1}')
```

2. **重启容器**
```bash
# 重启特定容器
docker restart user1-session

# 重启所有用户容器
for i in {1..4}; do
    docker restart user${i}-session
done
```

3. **查看容器日志**
```bash
# 查看容器日志
docker logs user1-session

# 实时查看日志
docker logs -f user1-session
```

#### 3.2.3 容器资源管理

1. **查看容器详细信息**
```bash
# 查看容器配置
docker inspect user1-session

# 查看容器网络
docker network inspect bridge
```

2. **资源限制设置**
```bash
# 限制容器内存使用
docker run --memory=2g ...

# 限制 CPU 使用
docker run --cpus=2 ...
```

#### 3.2.4 最佳实践

1. **日常监控**
   - 每天检查容器状态
   - 每周清理旧容器
   - 每月检查资源使用趋势

2. **资源管理**
   - 合理分配资源
   - 设置资源限制
   - 监控资源使用

3. **安全考虑**
   - 定期更新容器
   - 限制容器权限
   - 监控异常行为

4. **故障排查**
   - 检查容器状态
   - 查看容器日志
   - 监控资源使用

### 3.3 故障排除
```bash
# 检查 Docker 服务
systemctl status docker

# 检查用户容器
docker ps -a | grep userX

# 检查用户权限
ls -l /data1
ls -l /opt/docker_shells

# 检查 Docker 组权限
groups userX  # 应显示 docker 组
ls -l /var/run/docker.sock  # 应显示 docker 组有权限

# 检查 NVIDIA Container Toolkit
sudo nvidia-ctk runtime list
docker info | grep -i runtime

# 重置用户环境
sudo bash remove_user_docker.sh userX
sudo bash install.sh
```

## 4. 最佳实践

### 4.1 定期维护
- 每周检查系统状态
- 每月更新基础镜像
- 定期清理未使用的 Docker 资源

### 4.2 安全维护
- 定期更新系统
- 保持日志记录
- 定期检查权限设置

### 4.3 数据管理
- 定期备份重要数据
- 监控存储空间使用情况
- 及时清理不需要的数据

## 附录

### A. 系统架构
```
[系统架构概览]
用户登录 (SSH)
    ↓
自动进入 Docker 容器
    ↓
容器环境
├── 基础环境 (CUDA 12.8 + Python 3.12)
├── 数据存储
│   ├── /workspace (用户主目录映射)
│   └── /workspace/data (数据目录映射)
└── Docker in Docker 支持

[GPU 分配]
user1 -> GPU 0 (RTX 4090 D, 24GB)
user2 -> GPU 1 (RTX 4090 D, 24GB)
user3 -> GPU 2 (RTX 4090 D, 24GB)
user4 -> GPU 3 (RTX 4090 D, 24GB)
GPU 4 (H100, 80GB) 和 GPU 5 (A100, 80GB) 保留给系统使用
```

### B. 文件结构
```
slurm_docker_setup/
├── Dockerfile.base           # 基础Docker镜像配置
├── Dockerfile.user.template  # 用户Docker镜像模板
├── setup_docker_shell.sh     # 设置用户shell脚本
├── install.sh               # 主安装脚本
└── README.md               # 说明文档
```

### C. Docker镜像设计
系统采用两层Docker镜像设计：

1. `Dockerfile.base`：
   - 构建基础环境镜像（base-env）
   - 包含所有用户共享的基础组件：
     * CUDA 12.8 环境
     * Python 3.12
     * PyTorch 及其依赖
     * Docker 支持
     * Slurm 客户端

2. `Dockerfile.user.template`：
   - 用户镜像模板
   - 基于 base-env 镜像构建
   - 为每个用户创建独立的镜像
   - 包含用户特定的配置

### D. 存储结构
```
[存储结构]
/home/userX/              # 用户主目录
  |
  +-> 代码、配置文件等小型文件
  |
  +-> 在容器中映射为 /workspace

/data1/                   # 数据存储目录（root所有）
  |
  +-- org/               # 组织目录
  |   |
  |   +-- user1_data/   # user1的数据目录（700权限）
  |   |   |
  |   |   +-> 大型数据集
  |   |   +-> 模型文件
  |   |   +-> 在容器中映射为 /workspace/data
  |   |
  |   +-- user2_data/   # user2的数据目录（700权限）
  |   |
  |   +-- user3_data/   # user3的数据目录（700权限）
  |   |
  |   +-- user4_data/   # user4的数据目录（700权限）
```

### E. 权限控制
1. `/data1` 目录：
   - 权限：755 (rwxr-xr-x)
   - 所有者：root:root
   - 只有root可以修改目录内容

2. `/data1/org` 目录：
   - 权限：755 (rwxr-xr-x)
   - 所有者：root:root
   - 用于组织管理用户数据目录

3. 用户数据目录（如 `/data1/org/user1_data`）：
   - 权限：700 (rwx------)
   - 所有者：user1:user1
   - 只有对应用户可以访问

### F. 软件版本
- 基础镜像：`nvcr.io/nvidia/cuda-dl-base:25.03-cuda12.8-runtime-ubuntu24.04`
- Python：3.12 (在虚拟环境中)
- PyTorch：最新版本（支持 CUDA 12.8）
- Docker：最新版本
- Slurm：最新版本

### G. 环境验证
1. 基础环境验证：
```bash
# 检查 Python 版本
python --version  # 应显示 Python 3.12.x

# 检查 CUDA 版本
nvidia-smi  # 应显示 CUDA 12.8

# 检查 PyTorch 安装
python -c "import torch; print(torch.__version__); print(torch.cuda.is_available())"  # 应显示 True

# 检查 Slurm 配置
sinfo  # 应显示 Slurm 节点信息
squeue  # 应显示作业队列
```

2. 用户环境验证：
```bash
# 登录用户
ssh user1@server

# 检查容器环境
echo $USER  # 应显示 user1
pwd  # 应显示 /workspace
ls -l /workspace/data  # 应显示用户数据目录
```

3. Docker 功能验证：
```bash
# 在容器内运行 Docker 命令
docker ps
docker images

# 测试 GPU 访问
nvidia-smi
```

## 5. 用户指南

### 5.1 基本使用
1. 登录系统：
```bash
# 在本地机器上配置 SSH（~/.ssh/config）
Host lab
    HostName 172.30.101.111
    Port 22
    User user1  # 替换为对应的用户名 (user1, user2, user3, user4)

# 登录服务器
ssh lab
# 或直接使用
ssh user1@172.30.101.111  # 替换 user1 为对应的用户名

# 首次登录需要输入密码
# 密码要求：
# - 至少8个字符
# - 不能是常见字典词
# - 建议使用字母、数字和特殊字符的组合

# 登录成功后，会自动进入 Docker 容器
# 提示符会变成：user1@user1-container:~$
```

2. 容器状态说明：
```bash
# 退出容器
exit  # 或按 Ctrl+D

# 容器状态：
# - 执行 exit 后，容器会停止但不会被删除
# - 所有数据都会保持不变
# - 下次登录时会自动重新启动并连接到同一个容器
# - 这意味着你的工作环境会保持连续性

# 查看容器状态（在主机上执行）
docker ps -a | grep user1-session
# 输出示例：
# CONTAINER ID   IMAGE        STATUS                     NAMES
# abc123def456   user1-env   Exited (0) 2 hours ago     user1-session
```

3. 验证环境（在容器内执行）：
```bash
# 检查 GPU 状态
nvidia-smi

# 检查 Python 版本
python --version

# 检查 PyTorch 和 CUDA
python -c "import torch; print('PyTorch version:', torch.__version__); print('CUDA available:', torch.cuda.is_available()); print('CUDA device count:', torch.cuda.device_count())"

# 检查 Slurm 配置
sinfo
squeue
```

### 5.2 数据存储
- 小型文件（代码、配置等）放在 `/workspace` 目录
- 大型数据文件（数据集、模型等）放在 `/workspace/data` 目录（映射自 `/data1/org/userX_data`）

### 5.3 常用操作（在容器内执行）
1. 运行 Python 程序：
```bash
cd /workspace
python my_script.py
```

2. 使用 GPU 训练：
```bash
cd /workspace/data
python train.py
```

3. 使用 Docker：
```bash
# 在容器内使用 Docker（Docker in Docker）
# 注意：容器内已经配置了 Docker 访问权限
# 不需要使用 sudo，直接使用 docker 命令即可

# 拉取镜像
docker pull ubuntu

# 运行容器
docker run -it ubuntu

# 构建镜像
docker build -t my-project .

# 查看 Docker 信息
docker info
docker ps
docker images
```

4. 使用 Slurm：
```bash
# 提交作业
sbatch my_job.sh

# 查看作业状态
squeue

# 取消作业
scancel <job_id>

# 查看节点信息
sinfo
```

5. 常见 Docker 问题：
```bash
# 如果遇到权限问题，检查：
groups  # 应显示 docker 组
ls -l /var/run/docker.sock  # 应显示 docker 组有权限

# 如果仍然有问题，可以：
# 1. 退出容器
exit

# 2. 在主机上检查用户权限
sudo usermod -aG docker $USER

# 3. 重新登录
ssh user1@172.30.101.111
```

## 6. 常见问题

### 6.1 用户问题
Q: 如何安装新的Python包？
A: 在容器内使用pip安装：
```bash
pip install package_name
```

Q: 如何访问GPU？
A: 容器已配置GPU支持，直接使用即可：
```bash
nvidia-smi  # 查看GPU状态
```

Q: 如何使用Slurm提交作业？
A: 在容器内创建作业脚本并提交：
```bash
# 创建作业脚本
cat > my_job.sh << EOF
#!/bin/bash
#SBATCH --job-name=my_job
#SBATCH --output=my_job.out
#SBATCH --error=my_job.err
#SBATCH --time=01:00:00
#SBATCH --mem=4G
#SBATCH --gres=gpu:1

python my_script.py
EOF

# 提交作业
sbatch my_job.sh
```

### 6.2 管理员问题
Q: 如何备份数据？
A: 建议定期将重要数据备份到外部存储：
```bash
# 备份数据目录
tar -czf backup.tar.gz /workspace/data
```

Q: 如何更新系统？
A: 系统更新包括：
- 基础镜像更新
- Python包更新
- 系统配置更新
- Slurm配置更新

### 4.6 容器隔离验证

#### 4.6.1 验证脚本说明

我们提供了一个验证脚本 `verify_isolation.sh` 来测试容器的隔离配置：

```bash
# 设置执行权限
chmod +x verify_isolation.sh

# 运行验证脚本
sudo bash verify_isolation.sh
```

#### 4.6.2 验证项目

脚本会验证以下五个关键方面：

1. **用户命名空间检查**
   - 验证每个容器的用户命名空间映射
   - 检查容器 ID 和用户映射关系
   - 确保用户权限正确隔离

2. **文件系统隔离测试**
   - 测试容器内对系统目录的访问限制
   - 验证文件系统权限隔离
   - 确保用户无法访问其他用户的数据

3. **GPU 隔离验证**
   - 检查每个容器的 GPU 访问权限
   - 验证 GPU 设备分配是否正确
   - 确保用户只能访问分配的 GPU

4. **用户权限测试**
   - 验证容器内用户身份
   - 检查用户权限设置
   - 确保权限隔离生效

5. **容器间隔离测试**
   - 测试容器间的数据访问限制
   - 验证用户数据隔离
   - 确保用户无法访问其他用户的数据

#### 4.6.3 验证结果说明

验证脚本会输出详细的测试结果，包括：

```
=== 验证容器隔离配置 ===
1. 检查用户命名空间
   检查 user1 容器:
   容器 ID: abc123def456
   用户映射: 0 1000 1

2. 测试文件系统隔离
   测试 user1 容器文件系统隔离:
   文件系统隔离正常

3. 测试 GPU 隔离
   测试 user1 容器 GPU 访问:
   +-----------------------------------------------------------------------------+
   | NVIDIA-SMI 535.54.03              Driver Version: 535.54.03                 |
   |-------------------------------+----------------------+----------------------+
   | GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
   | Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
   |                               |                      |               MIG M. |
   |===============================+======================+======================|
   |   0  NVIDIA RTX 4090    Off  | 00000000:00:00.0  Off |                  N/A |
   |  0%   35C    P8    12W / 450W|      0MiB / 24576MiB |      0%      Default |
   |                               |                      |                  N/A |
   +-------------------------------+----------------------+----------------------+

4. 测试用户权限
   测试 user1 容器用户权限:
   user1
   uid=1000(user1) gid=1000(user1) groups=1000(user1),27(sudo)

5. 测试容器间隔离
   测试 user1 访问 user2 的数据:
   容器间隔离正常
```

#### 4.6.4 隔离机制说明

1. **用户命名空间隔离**
   ```
   [主机]                    [容器]
   root (uid 0)  → 映射到 → 非特权用户
   user1 (uid 1000) → 映射到 → user1 (uid 1000)
   ```

2. **文件系统隔离**
   ```
   [主机目录]                [容器目录]
   /home/user1    → 映射到 → /workspace
   /data1/org/user1_data → 映射到 → /workspace/data
   ```

3. **GPU 隔离**
   ```
   [GPU 分配]
   user1 → GPU 0
   user2 → GPU 1
   user3 → GPU 2
   user4 → GPU 3
   ```

#### 4.6.5 安全特性

1. **权限控制**
   - 容器内 root 用户被映射到非特权用户
   - 用户只能访问自己的数据目录
   - 文件系统访问被限制在映射目录内

2. **资源隔离**
   - GPU 设备访问限制
   - 内存和 CPU 使用限制
   - 网络访问控制

3. **安全选项**
   - 使用 no-new-privileges 安全选项
   - 限制容器权限
   - 启用用户命名空间隔离

#### 4.6.6 故障排除

如果验证失败，请检查：

1. **用户命名空间问题**
   ```bash
   # 检查 Docker 配置
   cat /etc/docker/daemon.json

   # 检查内核支持
   cat /proc/sys/kernel/unprivileged_userns_clone
   ```

2. **文件系统权限问题**
   ```bash
   # 检查目录权限
   ls -l /data1/org/user*_data

   # 检查挂载点
   docker inspect user1-session | grep -A 10 Mounts
   ```

3. **GPU 访问问题**
   ```bash
   # 检查 NVIDIA 驱动
   nvidia-smi

   # 检查容器 GPU 配置
   docker inspect user1-session | grep -A 5 Devices
   ```

4. **容器间隔离问题**
   ```bash
   # 检查容器网络
   docker network inspect bridge

   # 检查容器安全选项
   docker inspect user1-session | grep -A 5 SecurityOpt
   ```
```

## 7. 脚本分析与改进建议

### 7.1 问题分析与修复

#### 1. 用户命名空间隔离问题
```bash
--userns-remap="user${i}:user${i}"
```
**问题**：
- Docker 需要预先配置用户命名空间映射
- 直接这样使用会导致容器无法启动
- 需要在主机上设置 `/etc/subuid` 和 `/etc/subgid`

**解决方案**：
- 移除容器级别的 `--userns-remap` 选项
- 使用 Docker daemon 的全局 `userns-remap` 配置
- 在 `/etc/docker/daemon.json` 中设置 `"userns-remap": "default"`

#### 2. 安全漏洞：Docker套接字挂载
```bash
-v /var/run/docker.sock:/var/run/docker.sock \
-v /usr/bin/docker:/usr/bin/docker \
```
**风险**：
- 容器内用户可获得主机Docker控制权
- 可能逃逸到主机系统
- 违反最小权限原则

**解决方案**：
```bash
# 完全移除这些挂载
# 或仅对需要Docker-in-Docker功能的用户限制性使用
```

#### 3. 能力(capabilities)配置问题
```bash
--cap-drop=ALL \
--cap-add=SYS_PTRACE \
--cap-add=NET_ADMIN \
```
**问题**：
- `NET_ADMIN`能力过大，允许修改网络配置
- `SYS_PTRACE`可用于调试但也可能被滥用

**优化建议**：
```bash
--cap-drop=ALL \
--cap-add=SYS_PTRACE \  # 如果确实需要调试
```

#### 4. 容器重启策略
```bash
--restart unless-stopped \
```
**问题**：
- 用户退出后容器会不断重启
- 与交互式容器的设计不符

**解决方案**：
```bash
# 完全移除这行
# 或改为 --restart no (默认值)
```

#### 5. 共享库挂载问题
```bash
-v /usr/lib/x86_64-linux-gnu/libltdl.so.7:/usr/lib/x86_64-linux-gnu/libltdl.so.7 \
```
**问题**：
- 不同系统版本库文件可能不同
- 可能导致兼容性问题
- 不是最佳解决方案

### 7.2 改进后的完整脚本

```bash
#!/bin/bash

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
# 获取当前用户的Docker镜像
DOCKER_IMAGE="user${i}-env"

# 检查容器是否已存在
if ! docker ps -a | grep -q "user${i}-session"; then
    # 如果容器不存在，创建新容器
    docker run -itd \
        --name user${i}-session \
        --gpus '"device=${GPU_DEVICE}"' \
        --cpus=8 \
        --memory=64g \
        --ulimit memlock=-1 \
        --ulimit stack=67108864 \
        --security-opt no-new-privileges \
        --cap-drop=ALL \
        --cap-add=SYS_PTRACE \
        --health-cmd="nvidia-smi || exit 1" \
        --health-interval=5m \
        --log-driver=json-file \
        --log-opt max-size=100m \
        --log-opt max-file=3 \
        -v /home/user${i}:/workspace \
        -v /data1/org/user${i}_data:/workspace/data \
        -w /workspace \
        --hostname user${i}-container \
        \${DOCKER_IMAGE} \
        /bin/bash -c "tail -f /dev/null"  # 保持容器运行

    # 附加到新创建的容器
    docker attach user${i}-session
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
```

### 7.3 关键改进说明

#### 1. 用户命名空间配置
```bash
# 预先配置subuid/subgid
sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 user${i}
sudo systemctl restart docker

# 容器中使用
--userns-remap="user${i}" \
```

#### 2. 容器生命周期管理优化
```bash
# 创建容器时使用-d分离模式
docker run -itd ... tail -f /dev/null

# 然后附加
docker attach user${i}-session

# 状态检查逻辑
CONTAINER_STATUS=$(docker inspect -f '{{.State.Status}}' user${i}-session)
```

#### 3. 安全增强
```bash
# 移除危险挂载
# 移除NET_ADMIN能力
# 保持最小能力集
--cap-drop=ALL \
--cap-add=SYS_PTRACE \  # 仅当需要调试时
```

#### 4. 解决库依赖问题
```bash
# 移除特定库挂载
# 改为在Dockerfile中正确安装依赖
```

### 7.4 额外建议

#### 1. 在Dockerfile中设置非root用户
```dockerfile
# 在Dockerfile.user.template中添加
RUN useradd -m -u 1000 userX
USER userX
```

#### 2. 添加健康检查
```bash
# 在容器创建时添加
--health-cmd="nvidia-smi || exit 1" \
--health-interval=5m \
```

#### 3. 资源限制
```bash
# 添加资源限制防止滥用
--cpus=8 \
--memory=64g \
--device-read-bps=/dev/nvidia0:50mb \
```

#### 4. 日志配置
```bash
# 添加日志管理
--log-driver=json-file \
--log-opt max-size=100m \
--log-opt max-file=3 \
```

### 7.5 验证脚本

创建后执行：
```bash
# 测试用户1
sudo -u user1 /opt/docker_shells/user1_shell.sh

# 检查容器状态
docker ps -f "name=user1-session"

# 检查用户映射
docker inspect -f '{{.HostConfig.UsernsMode}}' user1-session
```

这个改进版本提供了更安全的隔离环境，同时保持了用户友好的交互体验。用户命名空间隔离现在能正确工作，安全风险显著降低，且容器生命周期管理更加健壮。

## 8. remove_user_docker.sh 脚本详解

### 8.1 脚本执行流程

```
[开始执行]
    │
    ▼
[权限检查] → [参数检查] → [用户存在性检查] → [用户登录状态检查]
    │
    ▼
[清理 Docker 环境]
    │
    ├─── 停止并删除容器
    ├─── 删除 Docker 镜像
    ├─── 清理 shell 脚本
    ├─── 处理数据目录
    ├─── 恢复默认 shell
    ├─── 从 Docker 组移除用户
    └─── 清理命名空间映射
    │
    ▼
[验证步骤]
    │
    └─── 检查用户配置
```

### 8.2 详细步骤说明

#### 1. 前置检查
- 检查是否以 root 权限运行
- 检查是否提供了用户名参数
- 检查用户是否存在
- 检查用户是否正在登录（如果在登录会询问是否继续）

#### 2. 清理过程
- 停止并删除用户的 Docker 容器（`${USERNAME}-session`）
- 删除用户的 Docker 镜像（`${USERNAME}-env`）
- 删除用户的 shell 脚本（`/opt/docker_shells/${USERNAME}_shell.sh`）
- 询问是否删除用户数据目录（`/data1/org/${USERNAME}_data`）
- 恢复用户的默认 shell 为 `/bin/bash`
- 从 Docker 组中移除用户
- 清理用户的命名空间映射（从 `/etc/subuid` 和 `/etc/subgid` 中删除）

#### 3. 执行结果
- 用户将无法再使用 Docker 环境
- 用户将恢复到普通的系统用户状态
- 用户的数据目录可能被保留或删除（取决于你的选择）

#### 4. 验证步骤
脚本最后会提示你检查：
- 用户的 shell 设置
- 用户的 Docker 组成员身份
- 用户的数据目录状态

### 8.3 使用示例
```bash
sudo ./remove_user_docker.sh user1
```

### 8.4 适用场景
这个脚本特别适合以下场景：
1. 用户离职或不再需要 Docker 环境
2. 需要重置用户的 Docker 环境
3. 系统维护或清理时

### 8.5 注意事项
- 脚本需要 root 权限运行
- 如果用户正在登录，会询问是否继续
- 数据目录的删除是可选的，需要手动确认
- 所有操作都是可逆的，除了数据目录的删除（如果选择删除）

### 8.6 与其他脚本的关系
这个脚本是整个 Docker 用户环境管理工具集的一部分，与 `create_user_docker_shells.sh` 和 `install.sh` 等脚本配合使用，用于完整管理用户的 Docker 环境生命周期。