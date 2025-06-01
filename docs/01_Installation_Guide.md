<!-- ---
marp: true
author: wxf
size: 4:3
theme: gaia
--- -->

# 安装指南

## 1. 环境要求

### 1.1 系统要求
- Ubuntu 24.04 LTS
- CUDA 12.8
- Docker
- NVIDIA GPU 驱动
- NVIDIA Container Toolkit
- Slurm

### 1.2 硬件要求
- NVIDIA GPU（支持 CUDA 12.8）
- 至少 16GB RAM
- 足够的存储空间（建议 100GB 以上）

## 2. 快速开始

### 2.1 安装步骤

1. **克隆仓库**
```bash
git clone <repository-url>
cd slurm_docker_setup
```

2. **安装 NVIDIA Container Toolkit**
```bash
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

3. **构建基础镜像**
```bash
sudo docker build -t base-env -f Dockerfile.base .
```

4. **创建用户数据目录**
```bash
sudo mkdir -p /data1/org
for i in {1..4}; do
    sudo mkdir -p /data1/org/user${i}_data
    sudo chown user$i:user$i /data1/org/user${i}_data
    sudo chmod 700 /data1/org/user${i}_data
done
```

5. **设置用户 shell 脚本**
```bash
sudo bash create_user_docker_shells.sh
```

6. **构建用户镜像**
```bash
for i in {1..4}; do
    sed "s/USERNAME/user$i/g" Dockerfile.user.template > Dockerfile.user$i
    sudo docker build -t user$i-env -f Dockerfile.user$i .
done
```

### 2.2 验证安装

1. **检查 NVIDIA Container Toolkit**
```bash
docker info | grep -i runtime
# 预期输出：
# Runtimes: io.containerd.runc.v2 nvidia runc
# Default Runtime: runc
```

2. **检查 NVIDIA 驱动**
```bash
nvidia-smi
# 预期输出：显示所有可用的 GPU 及其状态
```

3. **检查 Docker 镜像**
```bash
docker images | grep -E "base-env|user[1-4]-env"
```

4. **检查用户目录和权限**
```bash
ls -l /data1
for i in {1..4}; do
    echo "=== user$i ==="
    ls -l /data1/org/user${i}_data
    groups user$i
done
```

5. **验证 GPU 访问**
```bash
# 测试基础 GPU 访问
docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu24.04 nvidia-smi

# 测试用户容器 GPU 访问
for i in {1..4}; do
    echo "=== Testing user$i container ==="
    docker run --rm --gpus '"device='$((i-1))'"' nvidia/cuda:12.8.0-base-ubuntu24.04 nvidia-smi
done
```

6. **验证用户登录**
```bash
ssh user1@localhost
# 登录后应自动进入 Docker 容器
# 在容器内执行：
nvidia-smi
python -c "import torch; print('Available GPUs:', torch.cuda.device_count())"
```

7. **验证 Slurm 配置**
```bash
# 在容器内执行
sinfo
squeue
```

## 3. 用户首次登录常见问题与修复

### 3.1 Docker 权限问题

**现象**：
```
permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: ...
```

**原因**：新创建的用户默认没有加入 docker 组。

**修复方法**：
```bash
sudo usermod -aG docker user1
```
> ⚠️ 修改后需要重新登录。

### 3.2 Home 目录权限问题

**现象**：
```
ls: cannot open directory '/home/user1': Permission denied
```

**原因**：/home/user1 目录权限或所有者不正确。

**修复方法**：
```bash
sudo chown -R user1:user1 /home/user1
```

### 3.3 容器启动问题

**检查步骤**：
1. 检查 shell 配置：
```bash
getent passwd user1
```

2. 检查脚本权限：
```bash
ls -l /opt/docker_shells/user1_shell.sh
```

3. 检查数据目录权限：
```bash
ls -ld /data1/org/user1_data
```

### 3.4 GPU 访问问题

**检查步骤**：
1. 检查 nvidia-smi：
```bash
nvidia-smi
```

2. 检查 Docker GPU 访问：
```bash
docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu24.04 nvidia-smi
```

## 4. 故障排除

### 4.1 常见错误

1. **Docker 服务问题**
```bash
# 检查 Docker 服务状态
systemctl status docker

# 重启 Docker 服务
sudo systemctl restart docker
```

2. **NVIDIA 驱动问题**
```bash
# 检查 NVIDIA 驱动状态
nvidia-smi

# 检查 CUDA 版本
nvcc --version
```

3. **权限问题**
```bash
# 检查用户组
groups user1

# 检查 Docker socket 权限
ls -l /var/run/docker.sock
```

### 4.2 重置环境

如果需要完全重置环境：

1. **停止所有容器**
```bash
docker stop $(docker ps -aq)
```

2. **删除所有容器**
```bash
docker rm $(docker ps -aq)
```

3. **删除所有镜像**
```bash
docker rmi $(docker images -q)
```

4. **重新运行安装脚本**
```bash
sudo bash install.sh
```

## 5. 下一步

安装完成后，请参考：
- [用户指南](02_User_Guide.md) 了解如何使用环境
- [管理员指南](03_Admin_Guide.md) 了解如何管理系统
- [技术细节](04_Technical_Deep_Dive.md) 了解系统架构