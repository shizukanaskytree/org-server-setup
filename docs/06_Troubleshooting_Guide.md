<!-- ---
marp: true
author: wxf
size: 4:3
theme: gaia
--- -->

# 故障排除指南

## 1. 常见问题分类

### 1.1 问题分类概览

```
[问题分类]
    开始
      ↓
[系统问题] → [硬件/软件/网络]
      ↓
[容器问题] → [启动/运行/权限]
      ↓
[GPU问题] → [驱动/访问/性能]
      ↓
[数据问题] → [存储/权限/备份]
      ↓
[用户问题] → [登录/权限/环境]
      ↓
    完成
```

### 1.2 问题严重程度

1. **严重问题（需要立即处理）**
   - 系统崩溃
   - 数据丢失
   - 安全漏洞
   - 服务中断

2. **重要问题（需要尽快处理）**
   - 性能下降
   - 资源耗尽
   - 功能异常
   - 错误日志

3. **一般问题（可以计划处理）**
   - 配置问题
   - 使用问题
   - 优化问题
   - 建议改进

## 2. 系统问题

### 2.1 硬件问题

#### 2.1.1 GPU问题

1. **GPU无法识别**
   ```bash
   # 检查GPU状态
   nvidia-smi

   # 检查驱动状态
   systemctl status nvidia-persistenced

   # 检查PCI设备
   lspci | grep NVIDIA
   ```

2. **GPU温度过高**
   ```bash
   # 检查温度
   nvidia-smi -q -d temperature

   # 检查风扇
   nvidia-smi -q -d fan

   # 检查电源
   nvidia-smi -q -d power
   ```

3. **GPU内存问题**
   ```bash
   # 检查内存使用
   nvidia-smi --query-gpu=memory.used,memory.total --format=csv

   # 检查内存错误
   nvidia-smi -q -d memory
   ```

#### 2.1.2 存储问题

1. **磁盘空间不足**
   ```bash
   # 检查磁盘使用
   df -h

   # 检查大文件
   find /data1 -type f -size +100M

   # 清理临时文件
   find /tmp -type f -mtime +7 -delete
   ```

2. **磁盘性能问题**
   ```bash
   # 检查IO状态
   iostat -x 1

   # 检查磁盘健康
   smartctl -a /dev/sda

   # 检查文件系统
   fsck /dev/sda1
   ```

3. **存储权限问题**
   ```bash
   # 检查权限
   ls -l /data1/org/user*_data

   # 修复权限
   chmod 700 /data1/org/user1_data
   chown user1:user1 /data1/org/user1_data
   ```

### 2.2 软件问题

#### 2.2.1 系统服务问题

1. **Docker服务问题**
   ```bash
   # 检查服务状态
   systemctl status docker

   # 检查日志
   journalctl -u docker

   # 重启服务
   systemctl restart docker
   ```

2. **Slurm服务问题**
   ```bash
   # 检查服务状态
   systemctl status slurmctld

   # 检查日志
   tail -f /var/log/slurm/slurmctld.log

   # 重启服务
   systemctl restart slurmctld
   ```

3. **网络服务问题**
   ```bash
   # 检查网络
   ip a
   ping 8.8.8.8

   # 检查DNS
   nslookup google.com

   # 检查防火墙
   ufw status
   ```

#### 2.2.2 系统配置问题

1. **系统参数问题**
   ```bash
   # 检查系统参数
   sysctl -a | grep net.core

   # 修改系统参数
   sysctl -w net.core.somaxconn=65535

   # 永久修改
   echo "net.core.somaxconn=65535" >> /etc/sysctl.conf
   ```

2. **文件系统问题**
   ```bash
   # 检查挂载
   mount | grep data1

   # 检查文件系统
   tune2fs -l /dev/sda1

   # 修复文件系统
   fsck /dev/sda1
   ```

3. **系统日志问题**
   ```bash
   # 检查日志
   journalctl -f

   # 清理日志
   journalctl --vacuum-time=7d

   # 检查日志配置
   cat /etc/systemd/journald.conf
   ```

## 3. 容器问题

### 3.1 容器启动问题

#### 3.1.1 容器无法启动

1. **检查错误信息**
   ```bash
   # 检查容器日志
   docker logs user1-session

   # 检查系统日志
   journalctl -f

   # 检查Docker日志
   tail -f /var/log/docker.log
   ```

2. **检查配置**
   ```bash
   # 检查容器配置
   docker inspect user1-session

   # 检查镜像
   docker images

   # 检查网络
   docker network ls
   ```

3. **检查资源**
   ```bash
   # 检查系统资源
   free -h
   df -h

   # 检查GPU
   nvidia-smi

   # 检查进程
   ps aux | grep docker
   ```

#### 3.1.2 容器启动慢

1. **检查系统负载**
   ```bash
   # 检查CPU使用
   top

   # 检查IO使用
   iostat -x 1

   # 检查内存使用
   free -h
   ```

2. **检查Docker状态**
   ```bash
   # 检查Docker进程
   ps aux | grep docker

   # 检查Docker日志
   tail -f /var/log/docker.log

   # 检查Docker存储
   docker system df
   ```

3. **优化启动**
   ```bash
   # 清理未使用的容器
   docker container prune

   # 清理未使用的镜像
   docker image prune

   # 清理未使用的数据卷
   docker volume prune
   ```

### 3.2 容器运行问题

#### 3.2.1 容器性能问题

1. **检查资源使用**
   ```bash
   # 监控容器
   docker stats

   # 检查容器配置
   docker inspect user1-session

   # 检查系统资源
   top
   ```

2. **检查GPU使用**
   ```bash
   # 检查GPU状态
   nvidia-smi

   # 检查容器GPU配置
   docker inspect user1-session | grep -A 5 Devices

   # 检查GPU使用
   nvidia-smi dmon
   ```

3. **优化性能**
   ```bash
   # 限制资源使用
   --cpus=8
   --memory=64g

   # 优化IO
   --device-read-bps=/dev/sda:50mb
   --device-write-bps=/dev/sda:50mb
   ```

#### 3.2.2 容器网络问题

1. **检查网络配置**
   ```bash
   # 检查网络
   docker network ls

   # 检查容器网络
   docker inspect user1-session | grep -A 10 NetworkSettings

   # 检查DNS
   docker exec user1-session cat /etc/resolv.conf
   ```

2. **检查网络连接**
   ```bash
   # 测试网络
   docker exec user1-session ping 8.8.8.8

   # 检查端口
   docker exec user1-session netstat -tuln

   # 检查路由
   docker exec user1-session route -n
   ```

3. **修复网络**
   ```bash
   # 重启网络
   docker network disconnect bridge user1-session
   docker network connect bridge user1-session

   # 重启容器
   docker restart user1-session
   ```

### 3.3 容器权限问题

#### 3.3.1 用户权限问题

1. **检查用户权限**
   ```bash
   # 检查容器用户
   docker exec user1-session id

   # 检查主机用户
   id user1

   # 检查目录权限
   ls -l /data1/org/user1_data
   ```

2. **检查挂载权限**
   ```bash
   # 检查挂载点
   docker inspect user1-session | grep -A 10 Mounts

   # 检查目录权限
   ls -l /home/user1
   ls -l /data1/org/user1_data
   ```

3. **修复权限**
   ```bash
   # 修复目录权限
   chmod 700 /data1/org/user1_data
   chown user1:user1 /data1/org/user1_data

   # 修复文件权限
   find /data1/org/user1_data -type f -exec chmod 600 {} \;
   ```

#### 3.3.2 容器安全问题

1. **检查安全配置**
   ```bash
   # 检查容器配置
   docker inspect user1-session

   # 检查安全选项
   docker inspect user1-session | grep -A 5 SecurityOpt

   # 检查能力
   docker inspect user1-session | grep -A 5 CapAdd
   ```

2. **检查访问控制**
   ```bash
   # 检查用户访问
   docker exec user1-session who

   # 检查文件访问
   auditctl -w /data1/org/user1_data -p wa -k user1_data_access

   # 检查进程
   docker exec user1-session ps aux
   ```

3. **修复安全问题**
   ```bash
   # 更新安全选项
   --security-opt no-new-privileges
   --cap-drop=ALL

   # 限制资源
   --memory=64g
   --cpus=8
   ```

## 4. GPU问题

### 4.1 GPU驱动问题

#### 4.1.1 驱动安装问题

1. **检查驱动状态**
   ```bash
   # 检查驱动
   nvidia-smi

   # 检查驱动版本
   nvidia-smi --query-gpu=driver_version --format=csv,noheader

   # 检查驱动服务
   systemctl status nvidia-persistenced
   ```

2. **检查驱动安装**
   ```bash
   # 检查安装包
   dpkg -l | grep nvidia

   # 检查驱动文件
   ls -l /usr/lib/nvidia*

   # 检查驱动配置
   cat /etc/nvidia-container-runtime/config.toml
   ```

3. **修复驱动问题**
   ```bash
   # 重新安装驱动
   apt-get install --reinstall nvidia-driver-535

   # 重启驱动服务
   systemctl restart nvidia-persistenced

   # 更新驱动
   apt-get update && apt-get upgrade nvidia-driver-535
   ```

#### 4.1.2 驱动配置问题

1. **检查驱动配置**
   ```bash
   # 检查配置文件
   cat /etc/nvidia-container-runtime/config.toml

   # 检查环境变量
   env | grep NVIDIA

   # 检查设备节点
   ls -l /dev/nvidia*
   ```

2. **检查CUDA配置**
   ```bash
   # 检查CUDA版本
   nvcc --version

   # 检查CUDA路径
   echo $CUDA_HOME

   # 检查CUDA库
   ldconfig -p | grep cuda
   ```

3. **修复配置问题**
   ```bash
   # 更新配置
   nvidia-container-cli info

   # 重启服务
   systemctl restart docker

   # 更新环境变量
   export CUDA_HOME=/usr/local/cuda
   export PATH=$CUDA_HOME/bin:$PATH
   ```

### 4.2 GPU访问问题

#### 4.2.1 容器GPU访问

1. **检查容器GPU配置**
   ```bash
   # 检查容器配置
   docker inspect user1-session | grep -A 5 Devices

   # 检查GPU设备
   docker exec user1-session ls -l /dev/nvidia*

   # 检查GPU环境变量
   docker exec user1-session env | grep NVIDIA
   ```

2. **检查GPU权限**
   ```bash
   # 检查设备权限
   ls -l /dev/nvidia*

   # 检查用户权限
   groups user1

   # 检查容器权限
   docker exec user1-session id
   ```

3. **修复访问问题**
   ```bash
   # 更新容器配置
   --gpus '"device=0"'

   # 添加用户到组
   usermod -aG video user1

   # 重启容器
   docker restart user1-session
   ```

#### 4.2.2 GPU性能问题

1. **检查GPU使用**
   ```bash
   # 监控GPU使用
   nvidia-smi dmon

   # 检查GPU状态
   nvidia-smi -q

   # 检查GPU事件
   nvidia-smi --query-gpu=timestamp,utilization.gpu,memory.used --format=csv
   ```

2. **检查GPU温度**
   ```bash
   # 检查温度
   nvidia-smi -q -d temperature

   # 检查风扇
   nvidia-smi -q -d fan

   # 检查电源
   nvidia-smi -q -d power
   ```

3. **优化GPU性能**
   ```bash
   # 设置GPU频率
   nvidia-smi -ac 5001,1590

   # 设置电源模式
   nvidia-smi -pm 1

   # 设置计算模式
   nvidia-smi -c EXCLUSIVE_PROCESS
   ```

### 4.3 GPU应用问题

#### 4.3.1 PyTorch GPU问题

1. **检查PyTorch配置**
   ```python
   # 检查CUDA可用性
   import torch
   print(torch.cuda.is_available())

   # 检查CUDA版本
   print(torch.version.cuda)

   # 检查GPU数量
   print(torch.cuda.device_count())
   ```

2. **检查GPU内存**
   ```python
   # 检查内存使用
   print(torch.cuda.memory_allocated())
   print(torch.cuda.memory_reserved())

   # 清理内存
   torch.cuda.empty_cache()

   # 设置内存分配器
   torch.cuda.set_per_process_memory_fraction(0.8)
   ```

3. **优化GPU使用**
   ```python
   # 使用混合精度
   from torch.cuda.amp import autocast
   with autocast():
       output = model(input)

   # 使用数据并行
   model = torch.nn.DataParallel(model)

   # 使用梯度检查点
   from torch.utils.checkpoint import checkpoint
   output = checkpoint(model, input)
   ```

#### 4.3.2 其他GPU应用问题

1. **检查CUDA应用**
   ```bash
   # 检查CUDA版本
   nvcc --version

   # 检查CUDA路径
   echo $CUDA_HOME

   # 检查CUDA库
   ldconfig -p | grep cuda
   ```

2. **检查GPU应用**
   ```bash
   # 检查GPU进程
   nvidia-smi

   # 检查GPU使用
   nvidia-smi dmon

   # 检查GPU事件
   nvidia-smi --query-gpu=timestamp,utilization.gpu,memory.used --format=csv
   ```

3. **优化应用性能**
   ```bash
   # 设置GPU频率
   nvidia-smi -ac 5001,1590

   # 设置电源模式
   nvidia-smi -pm 1

   # 设置计算模式
   nvidia-smi -c EXCLUSIVE_PROCESS
   ```

## 5. 数据问题

### 5.1 存储问题

#### 5.1.1 磁盘空间问题

1. **检查磁盘空间**
   ```bash
   # 检查使用情况
   df -h

   # 检查大文件
   find /data1 -type f -size +100M

   # 检查目录大小
   du -sh /data1/*
   ```

2. **清理空间**
   ```bash
   # 清理临时文件
   find /tmp -type f -mtime +7 -delete

   # 清理日志
   find /var/log -type f -mtime +30 -delete

   # 清理缓存
   docker system prune -a
   ```

3. **管理空间**
   ```bash
   # 设置配额
   quota -s

   # 检查使用情况
   repquota -a

   # 设置限制
   edquota -u user1
   ```

#### 5.1.2 存储性能问题

1. **检查IO性能**
   ```bash
   # 检查IO状态
   iostat -x 1

   # 检查磁盘使用
   iotop

   # 检查文件系统
   tune2fs -l /dev/sda1
   ```

2. **优化性能**
   ```bash
   # 优化挂载选项
   mount -o remount,noatime,nodiratime /

   # 优化IO调度
   echo deadline > /sys/block/sda/queue/scheduler

   # 优化预读
   echo 4096 > /sys/block/sda/queue/read_ahead_kb
   ```

3. **监控性能**
   ```bash
   # 监控IO
   iostat -x 1

   # 监控磁盘
   iotop

   # 监控文件系统
   df -h
   ```

### 5.2 数据权限问题

#### 5.2.1 文件权限问题

1. **检查文件权限**
   ```bash
   # 检查权限
   ls -l /data1/org/user1_data

   # 检查所有者
   ls -l /data1/org/user1_data

   # 检查ACL
   getfacl /data1/org/user1_data
   ```

2. **修复权限**
   ```bash
   # 设置权限
   chmod 700 /data1/org/user1_data

   # 设置所有者
   chown user1:user1 /data1/org/user1_data

   # 设置ACL
   setfacl -m u:user1:rwx /data1/org/user1_data
   ```

3. **检查继承**
   ```bash
   # 设置目录权限
   find /data1/org/user1_data -type d -exec chmod 700 {} \;

   # 设置文件权限
   find /data1/org/user1_data -type f -exec chmod 600 {} \;

   # 设置所有者
   find /data1/org/user1_data -exec chown user1:user1 {} \;
   ```

#### 5.2.2 访问控制问题

1. **检查访问控制**
   ```bash
   # 检查用户权限
   id user1

   # 检查组权限
   groups user1

   # 检查SELinux
   getenforce
   ```

2. **修复访问控制**
   ```bash
   # 添加用户到组
   usermod -aG video user1

   # 设置SELinux
   setenforce 0

   # 设置ACL
   setfacl -m u:user1:rwx /data1/org/user1_data
   ```

3. **监控访问**
   ```bash
   # 监控文件访问
   auditctl -w /data1/org/user1_data -p wa -k user1_data_access

   # 检查审计日志
   ausearch -k user1_data_access

   # 生成报告
   aureport --auth
   ```

### 5.3 数据备份问题

#### 5.3.1 备份问题

1. **检查备份**
   ```bash
   # 检查备份文件
   ls -l /backup/data1/

   # 检查备份大小
   du -sh /backup/data1/

   # 检查备份时间
   find /backup/data1/ -type f -mtime -1
   ```

2. **修复备份**
   ```bash
   # 创建备份
   tar -czf /backup/data1/backup_$(date +%Y%m%d).tar.gz /data1

   # 验证备份
   tar -tvf /backup/data1/backup_$(date +%Y%m%d).tar.gz

   # 清理旧备份
   find /backup/data1/ -type f -mtime +7 -delete
   ```

3. **管理备份**
   ```bash
   # 设置备份计划
   crontab -e
   0 2 * * * /usr/local/bin/backup.sh

   # 检查备份日志
   tail -f /var/log/backup.log

   # 监控备份空间
   df -h /backup
   ```

#### 5.3.2 恢复问题

1. **检查恢复**
   ```bash
   # 检查备份文件
   ls -l /backup/data1/

   # 检查备份内容
   tar -tvf /backup/data1/backup_20240101.tar.gz

   # 检查恢复目标
   df -h /data1
   ```

2. **执行恢复**
   ```bash
   # 停止服务
   systemctl stop docker

   # 恢复数据
   tar -xzf /backup/data1/backup_20240101.tar.gz -C /

   # 修复权限
   chown -R user1:user1 /data1/org/user1_data
   chmod -R 700 /data1/org/user1_data
   ```

3. **验证恢复**
   ```bash
   # 检查文件
   ls -l /data1/org/user1_data

   # 检查权限
   getfacl /data1/org/user1_data

   # 启动服务
   systemctl start docker
   ```

## 6. 用户问题

### 6.1 登录问题

#### 6.1.1 SSH登录问题

1. **检查SSH服务**
   ```bash
   # 检查服务状态
   systemctl status sshd

   # 检查日志
   tail -f /var/log/auth.log

   # 检查配置
   cat /etc/ssh/sshd_config
   ```

2. **检查用户配置**
   ```bash
   # 检查用户
   id user1

   # 检查shell
   cat /etc/passwd | grep user1

   # 检查权限
   ls -l /home/user1
   ```

3. **修复登录问题**
   ```bash
   # 重置密码
   passwd user1

   # 修复权限
   chmod 700 /home/user1
   chown user1:user1 /home/user1

   # 重启服务
   systemctl restart sshd
   ```

#### 6.1.2 容器登录问题

1. **检查容器状态**
   ```bash
   # 检查容器
   docker ps -a

   # 检查日志
   docker logs user1-session

   # 检查配置
   docker inspect user1-session
   ```

2. **检查用户配置**
   ```bash
   # 检查用户
   docker exec user1-session id

   # 检查shell
   docker exec user1-session cat /etc/passwd

   # 检查权限
   docker exec user1-session ls -l /workspace
   ```

3. **修复登录问题**
   ```bash
   # 重启容器
   docker restart user1-session

   # 修复权限
   docker exec user1-session chown -R user1:user1 /workspace

   # 检查登录
   docker exec -it user1-session bash
   ```

### 6.2 环境问题

#### 6.2.1 Python环境问题

1. **检查Python环境**
   ```bash
   # 检查Python版本
   python --version

   # 检查pip
   pip list

   # 检查虚拟环境
   ls -l /workspace/venv
   ```

2. **检查依赖**
   ```bash
   # 检查requirements.txt
   cat requirements.txt

   # 检查已安装包
   pip freeze

   # 检查冲突
   pip check
   ```

3. **修复环境**
   ```bash
   # 创建虚拟环境
   python -m venv venv
   source venv/bin/activate

   # 安装依赖
   pip install -r requirements.txt

   # 更新pip
   pip install --upgrade pip
   ```

#### 6.2.2 GPU环境问题

1. **检查GPU环境**
   ```python
   # 检查CUDA
   import torch
   print(torch.cuda.is_available())

   # 检查GPU
   print(torch.cuda.device_count())

   # 检查版本
   print(torch.version.cuda)
   ```

2. **检查配置**
   ```bash
   # 检查环境变量
   env | grep CUDA

   # 检查路径
   echo $CUDA_HOME

   # 检查库
   ldconfig -p | grep cuda
   ```

3. **修复环境**
   ```bash
   # 设置环境变量
   export CUDA_HOME=/usr/local/cuda
   export PATH=$CUDA_HOME/bin:$PATH

   # 更新库
   ldconfig

   # 检查GPU
   nvidia-smi
   ```

### 6.3 权限问题

#### 6.3.1 文件权限问题

1. **检查文件权限**
   ```bash
   # 检查权限
   ls -l /workspace

   # 检查所有者
   ls -l /workspace

   # 检查ACL
   getfacl /workspace
   ```

2. **修复权限**
   ```bash
   # 设置权限
   chmod 700 /workspace

   # 设置所有者
   chown user1:user1 /workspace

   # 设置ACL
   setfacl -m u:user1:rwx /workspace
   ```

3. **检查继承**
   ```bash
   # 设置目录权限
   find /workspace -type d -exec chmod 700 {} \;

   # 设置文件权限
   find /workspace -type f -exec chmod 600 {} \;

   # 设置所有者
   find /workspace -exec chown user1:user1 {} \;
   ```

#### 6.3.2 系统权限问题

1. **检查系统权限**
   ```bash
   # 检查用户
   id user1

   # 检查组
   groups user1

   # 检查sudo
   sudo -l -U user1
   ```

2. **修复权限**
   ```bash
   # 添加用户到组
   usermod -aG video user1

   # 设置sudo
   usermod -aG sudo user1

   # 设置权限
   chmod 700 /home/user1
   ```

3. **监控权限**
   ```bash
   # 监控文件访问
   auditctl -w /workspace -p wa -k workspace_access

   # 检查审计日志
   ausearch -k workspace_access

   # 生成报告
   aureport --auth
   ```

## 7. 故障恢复流程

### 7.1 系统恢复

#### 7.1.1 系统服务恢复

1. **检查服务状态**
   ```bash
   # 检查所有服务
   systemctl list-units --type=service --state=failed

   # 检查关键服务
   systemctl status docker
   systemctl status slurm
   systemctl status nvidia-persistenced
   ```

2. **重启服务**
   ```bash
   # 重启Docker
   systemctl restart docker

   # 重启Slurm
   systemctl restart slurmctld

   # 重启NVIDIA
   systemctl restart nvidia-persistenced
   ```

3. **验证服务**
   ```bash
   # 检查Docker
   docker ps

   # 检查Slurm
   sinfo

   # 检查GPU
   nvidia-smi
   ```

#### 7.1.2 系统配置恢复

1. **检查配置**
   ```bash
   # 检查系统配置
   sysctl -a

   # 检查服务配置
   cat /etc/docker/daemon.json
   cat /etc/slurm/slurm.conf

   # 检查用户配置
   cat /etc/passwd
   ```

2. **恢复配置**
   ```bash
   # 恢复系统配置
   sysctl -p

   # 恢复服务配置
   systemctl daemon-reload

   # 恢复用户配置
   usermod -s /bin/bash user1
   ```

3. **验证配置**
   ```bash
   # 检查系统
   sysctl -a

   # 检查服务
   systemctl status docker

   # 检查用户
   id user1
   ```

### 7.2 数据恢复

#### 7.2.1 文件系统恢复

1. **检查文件系统**
   ```bash
   # 检查挂载
   mount | grep data1

   # 检查文件系统
   tune2fs -l /dev/sda1

   # 检查错误
   dmesg | grep -i error
   ```

2. **修复文件系统**
   ```bash
   # 卸载文件系统
   umount /data1

   # 检查文件系统
   fsck /dev/sda1

   # 重新挂载
   mount /data1
   ```

3. **验证文件系统**
   ```bash
   # 检查挂载
   mount | grep data1

   # 检查权限
   ls -l /data1

   # 检查空间
   df -h /data1
   ```

#### 7.2.2 数据恢复

1. **检查备份**
   ```bash
   # 检查备份文件
   ls -l /backup/data1/

   # 检查备份大小
   du -sh /backup/data1/

   # 检查备份时间
   find /backup/data1/ -type f -mtime -1
   ```

2. **恢复数据**
   ```bash
   # 停止服务
   systemctl stop docker

   # 恢复数据
   tar -xzf /backup/data1/backup_20240101.tar.gz -C /

   # 修复权限
   chown -R user1:user1 /data1/org/user1_data
   chmod -R 700 /data1/org/user1_data
   ```

3. **验证数据**
   ```bash
   # 检查文件
   ls -l /data1/org/user1_data

   # 检查权限
   getfacl /data1/org/user1_data

   # 启动服务
   systemctl start docker
   ```

### 7.3 应用恢复

#### 7.3.1 容器恢复

1. **检查容器**
   ```bash
   # 检查容器状态
   docker ps -a

   # 检查容器配置
   docker inspect user1-session

   # 检查容器日志
   docker logs user1-session
   ```

2. **恢复容器**
   ```bash
   # 停止容器
   docker stop user1-session

   # 删除容器
   docker rm user1-session

   # 重新创建容器
   docker run -itd --name user1-session ...
   ```

3. **验证容器**
   ```bash
   # 检查容器状态
   docker ps

   # 检查容器日志
   docker logs user1-session

   # 测试容器
   docker exec -it user1-session bash
   ```

#### 7.3.2 应用恢复

1. **检查应用**
   ```bash
   # 检查Python环境
   python --version
   pip list

   # 检查GPU环境
   nvidia-smi
   python -c "import torch; print(torch.cuda.is_available())"

   # 检查数据
   ls -l /workspace/data
   ```

2. **恢复应用**
   ```bash
   # 创建虚拟环境
   python -m venv venv
   source venv/bin/activate

   # 安装依赖
   pip install -r requirements.txt

   # 设置环境变量
   export CUDA_HOME=/usr/local/cuda
   export PATH=$CUDA_HOME/bin:$PATH
   ```

3. **验证应用**
   ```bash
   # 测试Python
   python -c "print('Hello, World!')"

   # 测试GPU
   python -c "import torch; print(torch.cuda.is_available())"

   # 测试数据
   ls -l /workspace/data
   ```