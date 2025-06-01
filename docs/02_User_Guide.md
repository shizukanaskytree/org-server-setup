<!-- ---
marp: true
author: wxf
size: 4:3
theme: gaia
--- -->

# 用户指南

## 1. 基本使用

### 1.1 登录系统

1. **配置 SSH**
```bash
# 在本地机器上配置 SSH（~/.ssh/config）
Host lab
    HostName 172.30.101.111
    Port 22
    User user1  # 替换为对应的用户名
```

2. **登录服务器**
```bash
ssh lab
# 或直接使用
ssh user1@172.30.101.111
```

3. **密码要求**
- 至少 8 个字符
- 不能是常见字典词
- 建议使用字母、数字和特殊字符的组合

### 1.2 容器环境

1. **容器状态**
- 登录后自动进入 Docker 容器
- 提示符格式：`user1@user1-container:~$`

2. **退出容器**
```bash
exit  # 或按 Ctrl+D
```

3. **容器生命周期**
- 执行 `exit` 后，容器会停止但不会被删除
- 所有数据都会保持不变
- 下次登录时会自动重新启动并连接到同一个容器
- 工作环境会保持连续性

4. **查看容器状态**
```bash
# 在主机上执行
docker ps -a | grep user1-session
```

## 2. 数据存储

### 2.1 目录结构

```
[容器内目录结构]
/workspace/           # 用户主目录（映射自 /home/userX）
  ├── 代码文件
  ├── 配置文件
  └── 其他小型文件

/workspace/data/     # 数据目录（映射自 /data1/org/userX_data）
  ├── 数据集
  ├── 模型文件
  └── 其他大型文件
```

### 2.2 存储建议

1. **小型文件**
- 代码、配置文件等放在 `/workspace` 目录
- 这些文件会同步到主机上的 `/home/userX` 目录

2. **大型文件**
- 数据集、模型等放在 `/workspace/data` 目录
- 这些文件会存储在 `/data1/org/userX_data` 目录
- 有更好的 I/O 性能

## 3. 常用操作

### 3.1 Python 开发

1. **运行 Python 程序**
```bash
cd /workspace
python my_script.py
```

2. **使用 GPU 训练**
```bash
cd /workspace/data
python train.py
```

3. **安装 Python 包**
```bash
pip install package_name
```

### 3.2 Docker 操作

1. **查看 Docker 信息**
```bash
docker info
docker ps
docker images
```

2. **运行容器**
```bash
docker run -it ubuntu
```

3. **构建镜像**
```bash
docker build -t my-project .
```

### 3.3 Slurm 作业管理

1. **提交作业**
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

2. **查看作业状态**
```bash
squeue  # 查看所有作业
squeue -u $USER  # 查看自己的作业
```

3. **取消作业**
```bash
scancel <job_id>
```

4. **查看节点信息**
```bash
sinfo
```

## 4. 常见问题

### 4.1 权限问题

1. **Docker 权限**
```bash
# 检查 Docker 组权限
groups  # 应显示 docker 组
ls -l /var/run/docker.sock  # 应显示 docker 组有权限
```

2. **文件权限**
```bash
# 检查目录权限
ls -l /workspace
ls -l /workspace/data
```

### 4.2 GPU 问题

1. **检查 GPU 状态**
```bash
nvidia-smi
```

2. **验证 PyTorch GPU 访问**
```bash
python -c "import torch; print('Available GPUs:', torch.cuda.device_count())"
```

3. **GPU 内存问题**
```bash
# 查看 GPU 内存使用
nvidia-smi

# 清理 GPU 内存
nvidia-smi --gpu-reset
```

### 4.3 存储问题

1. **检查磁盘空间**
```bash
df -h
du -sh /workspace
du -sh /workspace/data
```

2. **清理空间**
```bash
# 清理 Docker 资源
docker system prune -a

# 清理 Python 缓存
find /workspace -name "__pycache__" -type d -exec rm -r {} +
```

## 5. 最佳实践

### 5.1 开发建议

1. **代码管理**
- 使用版本控制系统（如 Git）
- 定期提交代码
- 保持代码结构清晰

2. **环境管理**
- 使用虚拟环境
- 记录依赖版本
- 保持环境一致性

3. **资源使用**
- 合理使用 GPU 资源
- 及时释放不需要的资源
- 避免资源浪费

### 5.2 数据管理

1. **数据组织**
- 使用清晰的目录结构
- 保持数据命名规范
- 定期备份重要数据

2. **性能优化**
- 大型数据集放在 `/workspace/data`
- 使用数据预加载
- 优化数据访问模式

## 6. 获取帮助

1. **查看文档**
- 项目文档
- 在线资源
- 技术博客

2. **联系支持**
- 系统管理员
- 技术支持团队
- 社区论坛