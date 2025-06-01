<!-- ---
marp: true
author: wxf
size: 4:3
theme: gaia
--- -->

# 技术细节与设计

## 1. 系统架构

### 1.1 架构概览

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

### 1.2 文件结构

```
slurm_docker_setup/
├── Dockerfile.base           # 基础Docker镜像配置
├── Dockerfile.user.template  # 用户Docker镜像模板
├── setup_docker_shell.sh     # 设置用户shell脚本
├── install.sh               # 主安装脚本
└── README.md               # 说明文档
```

### 1.3 Docker镜像设计

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

### 1.4 存储结构

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

## 2. 业务流程

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
```

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

## 3. 安全特性

### 3.1 权限控制

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

### 3.2 容器安全

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

### 3.3 安全选项

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

## 4. 容器隔离验证

### 4.1 验证脚本说明

我们提供了一个验证脚本 `verify_isolation.sh` 来测试容器的隔离配置：

```bash
# 设置执行权限
chmod +x verify_isolation.sh

# 运行验证脚本
sudo bash verify_isolation.sh
```

### 4.2 验证项目

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

### 4.3 验证结果说明

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

### 4.4 故障排除

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

## 5. 脚本分析与改进建议

### 5.1 问题分析与修复

#### 1. 用户命名空间隔离问题
```bash
--userns-remap="user${i}:user${i}"
```
**问题**：
- Docker需要预先配置用户命名空间映射
- 直接这样使用会导致容器无法启动
- 需要在主机上设置`/etc/subuid`和`/etc/subgid`

**解决方案**：
```bash
# 在脚本开头添加配置
for i in {1..4}; do
    sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 user${i}
done
sudo systemctl restart docker
```

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

### 5.2 改进后的完整脚本

```bash
#!/bin/bash

# 创建目录
sudo mkdir -p /opt/docker_shells

# 配置用户命名空间映射 (必须在容器创建前)
for i in {1..4}; do
    sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 user${i}
done
sudo systemctl restart docker

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
        --userns-remap="user${i}" \
        --gpus '"device=${GPU_DEVICE}"' \
        --ulimit memlock=-1 \
        --ulimit stack=67108864 \
        --security-opt no-new-privileges \
        --cap-drop=ALL \
        --cap-add=SYS_PTRACE \
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

### 5.3 关键改进说明

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

### 5.4 额外建议

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

### 5.5 验证脚本

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