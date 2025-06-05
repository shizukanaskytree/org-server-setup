#!/bin/bash
# entrypoint.sh (v3 - Robust Host Key Generation)

# 脚本任意一步出错则立即退出
set -e

echo "[Entrypoint] Starting container setup..."

# 不再使用 if 检查，而是直接、无条件地运行 ssh-keygen -A。
# 这个命令是幂等的，如果密钥已存在，它不会做任何事或报错。
# 这样做更简单，也更能保证密钥一定存在。
echo "[Entrypoint] Ensuring SSH host keys are present..."
ssh-keygen -A

echo "[Entrypoint] SSH host keys are ready."
echo "[Entrypoint] Starting SSH daemon..."

# 执行 Dockerfile 中定义的 CMD 命令 (即启动 sshd 服务)
# exec "$@" 会将当前进程替换为 "$@" 命令
exec "$@"