<!-- ---
marp: true
author: wxf
size: 4:3
theme: gaia
--- -->

# 最佳实践指南

## 1. 系统管理最佳实践

### 1.1 系统维护

#### 1.1.1 日常维护任务

1. **系统状态检查**
   ```bash
   # 检查系统负载
   top
   htop

   # 检查磁盘使用
   df -h
   du -sh /data1/*

   # 检查GPU状态
   nvidia-smi
   ```

2. **日志监控**
   ```bash
   # 检查系统日志
   journalctl -f

   # 检查Docker日志
   docker logs user1-session

   # 检查Slurm日志
   tail -f /var/log/slurm/slurmctld.log
   ```

3. **性能监控**
   ```bash
   # 监控GPU使用
   watch -n 1 nvidia-smi

   # 监控容器资源
   docker stats

   # 监控系统资源
   vmstat 1
   ```

#### 1.1.2 定期维护任务

1. **每周任务**
   - 检查系统更新
   - 清理临时文件
   - 检查磁盘空间
   - 备份重要数据

2. **每月任务**
   - 系统安全更新
   - 性能优化
   - 日志轮转
   - 完整系统备份

3. **每季度任务**
   - 系统全面检查
   - 安全审计
   - 性能评估
   - 配置优化

### 1.2 资源管理

#### 1.2.1 GPU资源管理

```
[GPU资源管理]
    开始
      ↓
[监控使用] → [分析负载] → [优化分配]
      ↓
[设置限制] → [调整配额] → [平衡负载]
      ↓
[性能调优] → [参数优化] → [监控效果]
      ↓
    完成
```

1. **GPU使用监控**
   ```bash
   # 实时监控
   watch -n 1 nvidia-smi

   # 历史记录
   nvidia-smi --query-gpu=timestamp,utilization.gpu,memory.used --format=csv
   ```

2. **资源限制设置**
   ```bash
   # 容器GPU限制
   --gpus '"device=0,capabilities=compute,utility"'

   # 内存限制
   --memory=64g
   ```

3. **性能优化**
   ```bash
   # CUDA性能调优
   export CUDA_DEVICE_ORDER=PCI_BUS_ID
   export CUDA_VISIBLE_DEVICES=0
   ```

#### 1.2.2 存储资源管理

1. **存储监控**
   ```bash
   # 检查存储使用
   df -h
   du -sh /data1/*

   # 检查用户配额
   quota -s
   ```

2. **数据清理**
   ```bash
   # 清理临时文件
   find /data1 -name "*.tmp" -delete

   # 清理日志
   find /data1 -name "*.log" -mtime +30 -delete
   ```

3. **备份策略**
   ```bash
   # 增量备份
   rsync -av --delete /data1/ /backup/data1/

   # 快照备份
   lvcreate -s -n snap_data1 -L 10G /dev/vg_data1/lv_data1
   ```

### 1.3 安全管理

#### 1.3.1 访问控制

1. **用户权限管理**
   ```bash
   # 检查用户权限
   ls -l /data1/org/user*_data

   # 设置权限
   chmod 700 /data1/org/user1_data
   chown user1:user1 /data1/org/user1_data
   ```

2. **容器安全**
   ```bash
   # 检查容器配置
   docker inspect user1-session

   # 更新安全选项
   --security-opt no-new-privileges
   --cap-drop=ALL
   ```

3. **网络访问控制**
   ```bash
   # 限制网络访问
   --network=bridge
   --dns=8.8.8.8
   ```

#### 1.3.2 安全审计

1. **日志审计**
   ```bash
   # 系统日志
   journalctl -f

   # Docker日志
   docker logs user1-session

   # 安全日志
   tail -f /var/log/auth.log
   ```

2. **访问审计**
   ```bash
   # 检查用户登录
   last

   # 检查文件访问
   auditctl -w /data1/org/user1_data -p wa -k user1_data_access
   ```

3. **安全扫描**
   ```bash
   # 容器漏洞扫描
   docker scan user1-env

   # 系统漏洞扫描
   lynis audit system
   ```

## 2. 用户最佳实践

### 2.1 开发环境管理

#### 2.1.1 代码管理

1. **版本控制**
   ```bash
   # 初始化仓库
   git init

   # 添加远程仓库
   git remote add origin <repository_url>

   # 提交代码
   git add .
   git commit -m "Initial commit"
   git push -u origin main
   ```

2. **代码组织**
   ```
   [项目结构]
   project/
   ├── src/           # 源代码
   ├── tests/         # 测试文件
   ├── docs/          # 文档
   ├── data/          # 数据文件
   └── requirements.txt # 依赖
   ```

3. **依赖管理**
   ```bash
   # 创建虚拟环境
   python -m venv venv
   source venv/bin/activate

   # 安装依赖
   pip install -r requirements.txt

   # 导出依赖
   pip freeze > requirements.txt
   ```

#### 2.1.2 环境配置

1. **Python环境**
   ```bash
   # 检查Python版本
   python --version

   # 检查CUDA版本
   nvidia-smi

   # 检查PyTorch
   python -c "import torch; print(torch.__version__)"
   ```

2. **GPU配置**
   ```bash
   # 设置GPU设备
   export CUDA_VISIBLE_DEVICES=0

   # 检查GPU可用性
   python -c "import torch; print(torch.cuda.is_available())"
   ```

3. **性能优化**
   ```bash
   # 设置线程数
   export OMP_NUM_THREADS=4

   # 设置内存分配
   export PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512
   ```

### 2.2 数据管理

#### 2.2.1 数据组织

1. **目录结构**
   ```
   [数据目录结构]
   /workspace/data/
   ├── raw/           # 原始数据
   ├── processed/     # 处理后的数据
   ├── models/        # 模型文件
   └── results/       # 结果文件
   ```

2. **数据备份**
   ```bash
   # 创建备份
   tar -czf data_backup.tar.gz /workspace/data

   # 恢复备份
   tar -xzf data_backup.tar.gz -C /workspace/data
   ```

3. **数据清理**
   ```bash
   # 清理临时文件
   find /workspace/data -name "*.tmp" -delete

   # 清理旧数据
   find /workspace/data -type f -mtime +30 -delete
   ```

#### 2.2.2 性能优化

1. **数据加载优化**
   ```python
   # 使用数据加载器
   from torch.utils.data import DataLoader

   dataloader = DataLoader(
       dataset,
       batch_size=32,
       num_workers=4,
       pin_memory=True
   )
   ```

2. **内存管理**
   ```python
   # 清理GPU内存
   torch.cuda.empty_cache()

   # 使用混合精度训练
   from torch.cuda.amp import autocast

   with autocast():
       outputs = model(inputs)
   ```

3. **IO优化**
   ```python
   # 使用内存映射
   import numpy as np

   data = np.memmap('large_file.npy', dtype='float32', mode='r')
   ```

### 2.3 工作流程优化

#### 2.3.1 开发流程

1. **代码开发**
   ```bash
   # 创建开发分支
   git checkout -b feature/new-feature

   # 提交更改
   git add .
   git commit -m "Add new feature"

   # 合并到主分支
   git checkout main
   git merge feature/new-feature
   ```

2. **测试流程**
   ```bash
   # 运行单元测试
   python -m pytest tests/

   # 运行性能测试
   python -m pytest tests/performance/

   # 生成测试报告
   pytest --html=report.html
   ```

3. **部署流程**
   ```bash
   # 构建Docker镜像
   docker build -t my-model .

   # 运行容器
   docker run -it --gpus all my-model

   # 监控运行状态
   docker logs -f container_id
   ```

#### 2.3.2 资源使用

1. **GPU使用**
   ```python
   # 检查GPU使用
   import torch

   print(torch.cuda.memory_allocated())
   print(torch.cuda.memory_reserved())
   ```

2. **内存使用**
   ```python
   # 监控内存使用
   import psutil

   process = psutil.Process()
   print(process.memory_info().rss)
   ```

3. **性能分析**
   ```python
   # 使用性能分析器
   import cProfile

   profiler = cProfile.Profile()
   profiler.enable()
   # 运行代码
   profiler.disable()
   profiler.print_stats()
   ```

## 3. 故障排除指南

### 3.1 常见问题

#### 3.1.1 容器问题

1. **容器无法启动**
   ```bash
   # 检查错误日志
   docker logs user1-session

   # 检查容器状态
   docker ps -a

   # 检查系统日志
   journalctl -f
   ```

2. **GPU访问问题**
   ```bash
   # 检查GPU状态
   nvidia-smi

   # 检查容器GPU配置
   docker inspect user1-session | grep -A 5 Devices

   # 检查NVIDIA驱动
   nvidia-smi -q
   ```

3. **权限问题**
   ```bash
   # 检查目录权限
   ls -l /data1/org/user1_data

   # 检查用户权限
   id user1

   # 检查容器用户
   docker exec user1-session id
   ```

#### 3.1.2 性能问题

1. **GPU性能问题**
   ```bash
   # 检查GPU使用
   nvidia-smi dmon

   # 检查温度
   nvidia-smi -q -d temperature

   # 检查电源状态
   nvidia-smi -q -d power
   ```

2. **内存问题**
   ```bash
   # 检查内存使用
   free -h

   # 检查交换空间
   swapon --show

   # 检查进程内存
   ps aux | grep python
   ```

3. **磁盘问题**
   ```bash
   # 检查磁盘使用
   df -h

   # 检查IO状态
   iostat -x 1

   # 检查文件系统
   fsck /dev/sda1
   ```

### 3.2 故障恢复

#### 3.2.1 数据恢复

1. **备份恢复**
   ```bash
   # 恢复数据
   tar -xzf backup.tar.gz -C /data1/org/user1_data

   # 检查权限
   chown -R user1:user1 /data1/org/user1_data
   chmod -R 700 /data1/org/user1_data
   ```

2. **容器恢复**
   ```bash
   # 停止容器
   docker stop user1-session

   # 删除容器
   docker rm user1-session

   # 重新创建容器
   docker run -itd --name user1-session ...
   ```

3. **配置恢复**
   ```bash
   # 恢复配置文件
   cp /backup/config/user1_config.json /etc/docker/

   # 重启服务
   systemctl restart docker
   ```

#### 3.2.2 系统恢复

1. **服务恢复**
   ```bash
   # 检查服务状态
   systemctl status docker
   systemctl status slurm

   # 重启服务
   systemctl restart docker
   systemctl restart slurm
   ```

2. **网络恢复**
   ```bash
   # 检查网络
   ip a
   ping 8.8.8.8

   # 重启网络
   systemctl restart networking
   ```

3. **安全恢复**
   ```bash
   # 检查安全状态
   lynis audit system

   # 更新系统
   apt update && apt upgrade

   # 检查防火墙
   ufw status
   ```

## 4. 性能优化指南

### 4.1 系统优化

#### 4.1.1 系统配置

1. **内核参数优化**
   ```bash
   # 编辑系统配置
   vim /etc/sysctl.conf

   # 添加优化参数
   net.core.somaxconn = 65535
   net.ipv4.tcp_max_syn_backlog = 65535
   vm.swappiness = 10
   ```

2. **文件系统优化**
   ```bash
   # 检查文件系统
   tune2fs -l /dev/sda1

   # 优化挂载选项
   defaults,noatime,nodiratime
   ```

3. **网络优化**
   ```bash
   # 优化网络参数
   net.core.rmem_max = 16777216
   net.core.wmem_max = 16777216
   net.ipv4.tcp_rmem = 4096 87380 16777216
   net.ipv4.tcp_wmem = 4096 87380 16777216
   ```

#### 4.1.2 资源优化

1. **CPU优化**
   ```bash
   # 设置CPU频率
   cpufreq-set -g performance

   # 设置进程优先级
   nice -n -20 command
   ```

2. **内存优化**
   ```bash
   # 设置内存限制
   --memory=64g
   --memory-swap=64g

   # 设置内存预留
   --memory-reservation=32g
   ```

3. **IO优化**
   ```bash
   # 设置IO优先级
   ionice -c 2 -n 0 command

   # 设置IO限制
   --device-read-bps=/dev/sda:50mb
   --device-write-bps=/dev/sda:50mb
   ```

### 4.2 应用优化

#### 4.2.1 Python优化

1. **代码优化**
   ```python
   # 使用向量化操作
   import numpy as np

   # 优化前
   for i in range(len(array)):
       result[i] = array[i] * 2

   # 优化后
   result = array * 2
   ```

2. **内存优化**
   ```python
   # 使用生成器
   def data_generator():
       for i in range(1000000):
           yield i

   # 使用内存映射
   import numpy as np
   data = np.memmap('large_file.npy', dtype='float32', mode='r')
   ```

3. **并行优化**
   ```python
   # 使用多进程
   from multiprocessing import Pool

   with Pool(4) as p:
       results = p.map(process_data, data_chunks)
   ```

#### 4.2.2 GPU优化

1. **CUDA优化**
   ```python
   # 使用CUDA流
   stream = torch.cuda.Stream()
   with torch.cuda.stream(stream):
       output = model(input)

   # 使用混合精度
   from torch.cuda.amp import autocast
   with autocast():
       output = model(input)
   ```

2. **内存优化**
   ```python
   # 清理GPU内存
   torch.cuda.empty_cache()

   # 使用梯度检查点
   from torch.utils.checkpoint import checkpoint
   output = checkpoint(model, input)
   ```

3. **性能优化**
   ```python
   # 使用数据预取
   dataloader = DataLoader(
       dataset,
       batch_size=32,
       num_workers=4,
       pin_memory=True
   )

   # 使用异步数据加载
   for data in dataloader:
       data = data.cuda(non_blocking=True)
   ```

### 4.3 监控与调优

#### 4.3.1 性能监控

1. **系统监控**
   ```bash
   # 监控系统资源
   top
   htop
   iotop

   # 监控网络
   iftop
   nethogs
   ```

2. **应用监控**
   ```python
   # 使用性能分析器
   import cProfile

   profiler = cProfile.Profile()
   profiler.enable()
   # 运行代码
   profiler.disable()
   profiler.print_stats()
   ```

3. **GPU监控**
   ```bash
   # 监控GPU使用
   nvidia-smi dmon

   # 监控GPU事件
   nvidia-smi --query-gpu=timestamp,utilization.gpu,memory.used --format=csv
   ```

#### 4.3.2 性能调优

1. **系统调优**
   ```bash
   # 调整系统参数
   sysctl -w net.core.somaxconn=65535
   sysctl -w vm.swappiness=10

   # 调整文件系统
   mount -o remount,noatime,nodiratime /
   ```

2. **应用调优**
   ```python
   # 优化数据加载
   dataloader = DataLoader(
       dataset,
       batch_size=32,
       num_workers=4,
       pin_memory=True,
       prefetch_factor=2
   )

   # 优化模型
   model = model.cuda()
   model = torch.nn.DataParallel(model)
   ```

3. **GPU调优**
   ```python
   # 设置CUDA设备
   torch.cuda.set_device(0)

   # 设置内存分配器
   torch.cuda.set_per_process_memory_fraction(0.8)

   # 设置缓存分配器
   torch.cuda.empty_cache()
   ```

## 5. 安全最佳实践

### 5.1 系统安全

#### 5.1.1 访问控制

1. **用户权限**
   ```bash
   # 检查用户权限
   ls -l /data1/org/user*_data

   # 设置权限
   chmod 700 /data1/org/user1_data
   chown user1:user1 /data1/org/user1_data
   ```

2. **容器安全**
   ```bash
   # 检查容器配置
   docker inspect user1-session

   # 更新安全选项
   --security-opt no-new-privileges
   --cap-drop=ALL
   ```

3. **网络安全**
   ```bash
   # 检查防火墙
   ufw status

   # 配置防火墙规则
   ufw allow from 192.168.1.0/24 to any port 22
   ```

#### 5.1.2 安全监控

1. **日志监控**
   ```bash
   # 系统日志
   journalctl -f

   # 安全日志
   tail -f /var/log/auth.log

   # 应用日志
   docker logs user1-session
   ```

2. **访问监控**
   ```bash
   # 检查用户登录
   last

   # 检查文件访问
   auditctl -w /data1/org/user1_data -p wa -k user1_data_access
   ```

3. **性能监控**
   ```bash
   # 监控系统资源
   top
   htop

   # 监控网络
   iftop
   nethogs
   ```

### 5.2 数据安全

#### 5.2.1 数据保护

1. **数据加密**
   ```bash
   # 加密数据
   gpg -c file.txt

   # 解密数据
   gpg -d file.txt.gpg
   ```

2. **数据备份**
   ```bash
   # 创建备份
   tar -czf data_backup.tar.gz /data1/org/user1_data

   # 恢复备份
   tar -xzf data_backup.tar.gz -C /data1/org/user1_data
   ```

3. **数据清理**
   ```bash
   # 安全删除
   shred -u file.txt

   # 清理临时文件
   find /data1 -name "*.tmp" -delete
   ```

#### 5.2.2 访问控制

1. **文件权限**
   ```bash
   # 设置权限
   chmod 700 /data1/org/user1_data
   chown user1:user1 /data1/org/user1_data

   # 检查权限
   ls -l /data1/org/user1_data
   ```

2. **目录权限**
   ```bash
   # 设置目录权限
   find /data1/org/user1_data -type d -exec chmod 700 {} \;

   # 设置文件权限
   find /data1/org/user1_data -type f -exec chmod 600 {} \;
   ```

3. **访问控制**
   ```bash
   # 设置ACL
   setfacl -m u:user1:rwx /data1/org/user1_data

   # 检查ACL
   getfacl /data1/org/user1_data
   ```

### 5.3 网络安全

#### 5.3.1 网络配置

1. **防火墙配置**
   ```bash
   # 检查防火墙
   ufw status

   # 配置规则
   ufw allow from 192.168.1.0/24 to any port 22
   ufw deny from any to any port 22
   ```

2. **网络隔离**
   ```bash
   # 配置网络
   docker network create --driver bridge isolated_network

   # 连接容器
   docker network connect isolated_network user1-session
   ```

3. **访问控制**
   ```bash
   # 限制网络访问
   --network=bridge
   --dns=8.8.8.8
   ```

#### 5.3.2 安全监控

1. **网络监控**
   ```bash
   # 监控网络流量
   iftop
   nethogs

   # 检查连接
   netstat -tuln
   ```

2. **安全扫描**
   ```bash
   # 扫描漏洞
   nmap -sV localhost

   # 检查端口
   netstat -tuln
   ```

3. **日志分析**
   ```bash
   # 分析网络日志
   tail -f /var/log/auth.log

   # 检查访问日志
   tail -f /var/log/nginx/access.log
   ```

## 6. 维护与更新

### 6.1 系统维护

#### 6.1.1 日常维护

1. **系统检查**
   ```bash
   # 检查系统状态
   top
   htop

   # 检查磁盘使用
   df -h
   du -sh /data1/*

   # 检查GPU状态
   nvidia-smi
   ```

2. **日志检查**
   ```bash
   # 检查系统日志
   journalctl -f

   # 检查Docker日志
   docker logs user1-session

   # 检查安全日志
   tail -f /var/log/auth.log
   ```

3. **性能检查**
   ```bash
   # 检查CPU使用
   mpstat 1

   # 检查内存使用
   free -h

   # 检查IO使用
   iostat -x 1
   ```

#### 6.1.2 定期维护

1. **每周维护**
   ```bash
   # 系统更新
   apt update && apt upgrade

   # 清理临时文件
   find /tmp -type f -mtime +7 -delete

   # 检查磁盘空间
   df -h
   ```

2. **每月维护**
   ```bash
   # 系统备份
   tar -czf system_backup.tar.gz /etc

   # 数据备份
   tar -czf data_backup.tar.gz /data1

   # 日志轮转
   logrotate -f /etc/logrotate.conf
   ```

3. **每季度维护**
   ```bash
   # 系统检查
   lynis audit system

   # 安全更新
   apt update && apt upgrade

   # 性能优化
   sysctl -p
   ```

### 6.2 更新管理

#### 6.2.1 系统更新

1. **更新检查**
   ```bash
   # 检查更新
   apt update

   # 查看可更新包
   apt list --upgradable

   # 更新系统
   apt upgrade
   ```

2. **安全更新**
   ```bash
   # 安装安全更新
   apt install --only-upgrade -y $(apt list --upgradable | grep security)

   # 检查安全漏洞
   lynis audit system
   ```

3. **依赖更新**
   ```bash
   # 更新Python包
   pip install --upgrade -r requirements.txt

   # 更新Docker镜像
   docker pull nvidia/cuda:12.8.0-base-ubuntu24.04
   ```

#### 6.2.2 配置更新

1. **系统配置**
   ```bash
   # 更新系统配置
   sysctl -p

   # 更新服务配置
   systemctl daemon-reload

   # 重启服务
   systemctl restart docker
   ```

2. **应用配置**
   ```bash
   # 更新Docker配置
   docker-compose up -d

   # 更新Slurm配置
   scontrol reconfigure
   ```

3. **用户配置**
   ```bash
   # 更新用户环境
   docker build -t user1-env .

   # 更新容器
   docker stop user1-session
   docker rm user1-session
   docker run -itd --name user1-session ...
   ```

### 6.3 备份与恢复

#### 6.3.1 备份策略

1. **系统备份**
   ```bash
   # 备份系统配置
   tar -czf system_config.tar.gz /etc

   # 备份用户数据
   tar -czf user_data.tar.gz /data1

   # 备份Docker镜像
   docker save -o docker_images.tar $(docker images -q)
   ```

2. **增量备份**
   ```bash
   # 创建增量备份
   rsync -av --delete /data1/ /backup/data1/

   # 创建快照
   lvcreate -s -n snap_data1 -L 10G /dev/vg_data1/lv_data1
   ```

3. **自动备份**
   ```bash
   # 创建备份脚本
   vim /usr/local/bin/backup.sh

   # 设置定时任务
   crontab -e
   0 2 * * * /usr/local/bin/backup.sh
   ```

#### 6.3.2 恢复策略

1. **系统恢复**
   ```bash
   # 恢复系统配置
   tar -xzf system_config.tar.gz -C /

   # 恢复用户数据
   tar -xzf user_data.tar.gz -C /data1

   # 恢复Docker镜像
   docker load -i docker_images.tar
   ```

2. **数据恢复**
   ```bash
   # 恢复数据
   rsync -av /backup/data1/ /data1/

   # 恢复快照
   lvconvert --merge /dev/vg_data1/snap_data1
   ```

3. **应用恢复**
   ```bash
   # 恢复Docker容器
   docker-compose up -d

   # 恢复Slurm配置
   scontrol reconfigure
   ```

## 7. 监控与告警

### 7.1 系统监控

#### 7.1.1 资源监控

1. **CPU监控**
   ```bash
   # 监控CPU使用
   top
   htop
   mpstat 1

   # 检查负载
   uptime
   ```

2. **内存监控**
   ```bash
   # 监控内存使用
   free -h
   vmstat 1

   # 检查交换空间
   swapon --show
   ```

3. **磁盘监控**
   ```bash
   # 监控磁盘使用
   df -h
   du -sh /data1/*

   # 监控IO
   iostat -x 1
   ```

#### 7.1.2 应用监控

1. **Docker监控**
   ```bash
   # 监控容器
   docker stats

   # 检查容器状态
   docker ps -a

   # 检查容器日志
   docker logs user1-session
   ```

2. **GPU监控**
   ```bash
   # 监控GPU使用
   nvidia-smi
   nvidia-smi dmon

   # 检查GPU状态
   nvidia-smi -q
   ```

3. **Slurm监控**
   ```bash
   # 监控作业
   squeue

   # 检查节点状态
   sinfo

   # 检查作业状态
   sacct
   ```

### 7.2 告警配置

#### 7.2.1 系统告警

1. **资源告警**
   ```bash
   # 设置CPU告警
   if [ $(top -bn1 | grep "Cpu(s)" | awk '{print $2}') -gt 90 ]; then
       echo "CPU usage high" | mail -s "Alert" admin@example.com
   fi

   # 设置内存告警
   if [ $(free | grep Mem | awk '{print $3/$2 * 100.0}') -gt 90 ]; then
       echo "Memory usage high" | mail -s "Alert" admin@example.com
   fi
   ```

2. **磁盘告警**
   ```bash
   # 设置磁盘告警
   if [ $(df -h /data1 | awk 'NR==2 {print $5}' | sed 's/%//') -gt 90 ]; then
       echo "Disk usage high" | mail -s "Alert" admin@example.com
   fi
   ```

3. **GPU告警**
   ```bash
   # 设置GPU告警
   if [ $(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits) -gt 90 ]; then
       echo "GPU usage high" | mail -s "Alert" admin@example.com
   fi
   ```

#### 7.2.2 应用告警

1. **容器告警**
   ```bash
   # 检查容器状态
   if [ $(docker ps -q | wc -l) -lt 4 ]; then
       echo "Container down" | mail -s "Alert" admin@example.com
   fi
   ```

2. **服务告警**
   ```bash
   # 检查服务状态
   if ! systemctl is-active --quiet docker; then
       echo "Docker service down" | mail -s "Alert" admin@example.com
   fi
   ```

3. **性能告警**
   ```bash
   # 检查响应时间
   if [ $(curl -s -w "%{time_total}" -o /dev/null http://localhost) -gt 1 ]; then
       echo "Response time high" | mail -s "Alert" admin@example.com
   fi
   ```

### 7.3 日志管理

#### 7.3.1 日志收集

1. **系统日志**
   ```bash
   # 收集系统日志
   journalctl -f > /var/log/system.log

   # 收集安全日志
   tail -f /var/log/auth.log > /var/log/security.log
   ```

2. **应用日志**
   ```bash
   # 收集Docker日志
   docker logs user1-session > /var/log/docker.log

   # 收集Slurm日志
   tail -f /var/log/slurm/slurmctld.log > /var/log/slurm.log
   ```

3. **性能日志**
   ```bash
   # 收集性能日志
   sar -u 1 60 > /var/log/cpu.log
   sar -r 1 60 > /var/log/memory.log
   sar -d 1 60 > /var/log/disk.log
   ```

#### 7.3.2 日志分析

1. **日志过滤**
   ```bash
   # 过滤错误日志
   grep ERROR /var/log/system.log

   # 过滤警告日志
   grep WARNING /var/log/system.log
   ```

2. **日志统计**
   ```bash
   # 统计错误数量
   grep ERROR /var/log/system.log | wc -l

   # 统计警告数量
   grep WARNING /var/log/system.log | wc -l
   ```

3. **日志报告**
   ```bash
   # 生成日志报告
   echo "System Log Report" > report.txt
   echo "Errors: $(grep ERROR /var/log/system.log | wc -l)" >> report.txt
   echo "Warnings: $(grep WARNING /var/log/system.log | wc -l)" >> report.txt
   ```