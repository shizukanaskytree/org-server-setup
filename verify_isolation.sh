#!/bin/bash

# 验证容器隔离配置
echo "=== 验证容器隔离配置 ==="

# 1. 检查用户命名空间
echo "1. 检查用户命名空间"
for i in {1..4}; do
    echo "检查 user$i 容器:"
    if docker ps -a | grep -q "user${i}-session"; then
        CONTAINER_ID=$(docker inspect -f '{{.Id}}' user${i}-session)
        echo "容器 ID: $CONTAINER_ID"
        echo "用户映射:"
        cat /proc/$(docker inspect -f '{{.State.Pid}}' user${i}-session)/uid_map
    else
        echo "容器不存在"
    fi
done

# 2. 测试文件系统隔离
echo "2. 测试文件系统隔离"
for i in {1..4}; do
    echo "测试 user$i 容器文件系统隔离:"
    docker exec -it user${i}-session bash -c "touch /etc/test-file 2>&1 || echo '文件系统隔离正常'"
done

# 3. 测试 GPU 隔离
echo "3. 测试 GPU 隔离"
for i in {1..4}; do
    echo "测试 user$i 容器 GPU 访问:"
    docker exec -it user${i}-session bash -c "nvidia-smi"
done

# 4. 测试用户权限
echo "4. 测试用户权限"
for i in {1..4}; do
    echo "测试 user$i 容器用户权限:"
    docker exec -it user${i}-session bash -c "whoami && id"
done

# 5. 测试容器间隔离
echo "5. 测试容器间隔离"
for i in {1..4}; do
    for j in {1..4}; do
        if [ $i -ne $j ]; then
            echo "测试 user$i 访问 user$j 的数据:"
            docker exec -it user${i}-session bash -c "ls -l /workspace/data/../user${j}_data 2>&1 || echo '容器间隔离正常'"
        fi
    done
done

echo "=== 验证完成 ==="