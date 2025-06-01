<!-- ---
marp: true
author: wxf
size: 4:3
theme: gaia
--- -->

# 管理员指南

## 1. 用户管理

### 1.1 创建新用户

使用单个用户设置脚本：
```bash
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
sudo bash setup_single_user.sh user1 0 mypassword123
sudo bash setup_single_user.sh user2 1 mypassword456
sudo bash setup_single_user.sh user3 2
sudo passwd user3  # 手动设置密码
```

### 1.2 验证用户设置

```bash
# 1. 检查用户创建
id user1

# 2. 检查 Docker 权限
groups user1

# 3. 检查数据目录
ls -l /data1/org/user1_data

# 4. 登录测试
ssh user1@172.30.101.111

# 5. 在容器内验证 GPU 访问
nvidia-smi
python -c "import torch; print('Available GPUs:', torch.cuda.device_count())"
```

### 1.3 删除和重建用户

实际应用场景:
- 用户迁移：当需要将用户迁移到其他服务器时
- 环境重置：当用户的 Docker 环境出现问题时
- 用户删除：在删除用户账号前清理其 Docker 环境
- 系统维护：在系统维护时清理特定用户的 Docker 环境

```bash
# 1. 删除用户环境
sudo bash remove_user_docker.sh userX

# 脚本会执行以下操作：
# - 停止并删除用户的 Docker 容器
# - 删除用户的 Docker 镜像
# - 清理用户的 shell 脚本
# - 询问是否删除用户数据目录
# - 恢复用户的默认 shell
# - 从 Docker 组移除用户

# 2. 重新创建用户环境
sudo bash setup_single_user.sh userX <gpu_id> [password]
```

## 2. 系统维护

### 2.1 日常检查

```bash
# 检查 Docker 状态
docker ps -a  # 查看所有容器
docker ps     # 只查看运行中的容器
docker stats  # 查看容器资源使用情况

# 检查存储空间
df -h /data1
du -sh /data1/org/user*_data
```

### 2.2 容器管理

#### 2.2.1 查看容器状态

```bash
# 查看所有容器
docker ps -a

# 查看运行中的容器
docker ps

# 查看特定用户的容器
docker ps -a | grep user1-session

# 查看容器资源使用情况
docker stats --no-stream
```

#### 2.2.2 容器生命周期管理

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

#### 2.2.3 容器资源管理

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

### 2.3 数据迁移

#### 2.3.1 迁移步骤

```bash
# 1. 进入 slurm_docker_setup 目录
cd slurm_docker_setup

# 2. 确保所有用户都已退出容器
docker ps | grep user

# 3. 执行迁移脚本
sudo bash migrate_to_org.sh
```

#### 2.3.2 迁移验证

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
ssh user1@localhost
```

#### 2.3.3 故障排除

1. **目录权限问题**
```bash
# 检查并修复权限
sudo chown -R user1:user1 /data1/org/user1_data
sudo chmod 700 /data1/org/user1_data
```

2. **容器启动问题**
```bash
# 检查容器日志
docker logs user1-session

# 重新创建容器
sudo bash create_user_docker_shells.sh
```

3. **数据访问问题**
```bash
# 检查挂载点
docker inspect user1-session | grep -A 10 Mounts

# 检查目录映射
ls -l /workspace/data  # 在容器内执行
```

4. **恢复备份**
```bash
# 如果迁移出现问题，可以恢复备份
sudo mv /data1/org/user1_data.bak.* /data1/org/user1_data
sudo chown -R user1:user1 /data1/org/user1_data
sudo chmod 700 /data1/org/user1_data
```

## 3. 故障排除

### 3.1 系统检查

```bash
# 检查 Docker 服务
systemctl status docker

# 检查用户容器
docker ps -a | grep userX

# 检查用户权限
ls -l /data1
ls -l /opt/docker_shells

# 检查 Docker 组权限
groups userX
ls -l /var/run/docker.sock

# 检查 NVIDIA Container Toolkit
sudo nvidia-ctk runtime list
docker info | grep -i runtime
```

### 3.2 环境重置

```bash
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

## 5. 监控和日志

### 5.1 系统监控

1. **资源监控**
```bash
# 监控 GPU 使用
nvidia-smi dmon

# 监控容器资源
docker stats
```

2. **存储监控**
```bash
# 监控磁盘使用
df -h
du -sh /data1/org/user*_data
```

### 5.2 日志管理

1. **Docker 日志**
```bash
# 查看容器日志
docker logs user1-session

# 查看 Docker 守护进程日志
journalctl -u docker
```

2. **系统日志**
```bash
# 查看系统日志
journalctl

# 查看认证日志
journalctl -u ssh
```

## 6. 安全建议

### 6.1 访问控制

1. **用户权限**
- 定期检查用户权限
- 及时移除不需要的权限
- 遵循最小权限原则

2. **Docker 安全**
- 限制容器权限
- 使用安全选项
- 定期更新 Docker

### 6.2 数据安全

1. **备份策略**
- 定期备份重要数据
- 测试备份恢复
- 保持多个备份副本

2. **数据隔离**
- 确保用户数据隔离
- 定期检查权限设置
- 监控异常访问