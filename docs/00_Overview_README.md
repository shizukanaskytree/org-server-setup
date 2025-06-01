<!-- ---
marp: true
author: wxf
size: 4:3
theme: gaia
--- -->

# 多用户下 Docker 环境设置指南

## 项目概述

本项目提供了一个完整的解决方案，用于在多用户环境下设置和管理 Docker 容器化环境。它特别适用于需要 GPU 加速的深度学习开发环境，并集成了 Slurm 作业调度系统。

### 主要特性

- 基于 Docker 的多用户隔离环境
- GPU 设备分配和管理
- 用户数据持久化存储
- Slurm 作业调度集成
- 完整的用户权限管理
- 自动化环境配置

## 文档结构

本项目文档分为以下几个主要部分：

1. **[安装指南](01_Installation_Guide.md)**
   - 环境要求
   - 快速开始
   - 安装步骤
   - 验证安装
   - 常见问题修复

2. **[用户指南](02_User_Guide.md)**
   - 基本使用说明
   - 数据存储指南
   - 常用操作示例
   - 用户常见问题

3. **[管理员指南](03_Admin_Guide.md)**
   - 用户管理
   - 系统维护
   - 故障排除
   - 数据迁移

4. **[技术细节](04_Technical_Deep_Dive.md)**
   - 系统架构
   - 业务流程
   - 安全特性
   - 容器隔离
   - 脚本分析

5. **[最佳实践](05_General_Notes_And_Best_Practices.md)**
   - 注意事项
   - 维护建议
   - 安全建议

## 项目文件结构

```
slurm_docker_setup/
├── Dockerfile.base              # 基础环境 Dockerfile
├── Dockerfile.user.template     # 用户镜像模板
├── create_user_docker_shells.sh # 创建用户 Docker 环境
├── install.sh                   # 主安装脚本
├── migrate_to_org.sh           # 数据迁移脚本
├── remove_user_docker.sh       # 清理脚本
└── docs/                       # 文档目录
    ├── 00_Overview_README.md   # 项目总览
    ├── 01_Installation_Guide.md # 安装指南
    ├── 02_User_Guide.md        # 用户指南
    ├── 03_Admin_Guide.md       # 管理员指南
    ├── 04_Technical_Deep_Dive.md # 技术细节
    └── 05_General_Notes_And_Best_Practices.md # 最佳实践
```

## 快速开始

1. 克隆仓库：
```bash
git clone <repository-url>
cd slurm_docker_setup
```

2. 运行安装脚本：
```bash
sudo bash install.sh
```

3. 创建用户环境：
```bash
sudo bash create_user_docker_shells.sh
```

详细说明请参考[安装指南](01_Installation_Guide.md)。

## 系统要求

- Ubuntu 24.04 LTS
- CUDA 12.8
- Docker
- NVIDIA GPU 驱动
- NVIDIA Container Toolkit
- Slurm

## 贡献指南

欢迎提交 Issue 和 Pull Request 来帮助改进这个项目。

## 许可证

[添加许可证信息]