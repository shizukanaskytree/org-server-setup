---
marp: true
theme: default
paginate: true
header: 'INSIDE_DOCKER环境变量详解'
footer: 'Marp Presentation - INSIDE_DOCKER Environment Variable'
---

[父文件：login_prompt_explanation.md](../login_prompt_explanation.md)

# INSIDE_DOCKER环境变量详解

## 父文件中要深入讲解的内容

```bash
if [ -z "$INSIDE_DOCKER" ]; then
    echo "You are on the host. To enter your Docker container, run:"
    echo "docker exec -it ${docker_name} bash --login"
fi
```

- `$INSIDE_DOCKER`: 环境变量，用于判断是否在Docker容器内
- `-z`: 测试字符串长度是否为0
- 当变量为空时（在主机上）显示提示信息
- 当变量不为空时（在容器内）不显示任何提示

## 自定义环境变量的使用与配置

---

### 1. 什么是 $INSIDE_DOCKER？

```bash
if [ -z "$INSIDE_DOCKER" ]; then
    # 在宿主机上执行的代码
else
    # 在容器内执行的代码
fi
```

- 自定义环境变量，非 Linux 或 Docker 标准变量
- 用于判断当前环境是否在 Docker 容器内
- 开发者自行定义和设置

---

### 2. 为什么需要它？

- Linux 没有标准方式判断是否在容器内
- 需要一种可靠的方法区分运行环境
- 便于脚本根据环境执行不同操作

---

### 3. 如何设置 $INSIDE_DOCKER？

#### 方法一：Dockerfile 中设置
```dockerfile
ENV INSIDE_DOCKER=1
```

#### 方法二：启动命令中设置
```bash
docker run -e INSIDE_DOCKER=1 ...
```

#### 方法三：容器内脚本设置
```bash
export INSIDE_DOCKER=1
```

---

### 4. 变量特性总结

| 特性 | 说明 |
|------|------|
| 类型 | 自定义环境变量 |
| 标准性 | ❌ 非标准变量 |
| 设置者 | 开发者 |
| 作用 | 环境判断标志 |

---

### 5. 使用场景示例

```bash
# 在宿主机上显示提示信息
if [ -z "$INSIDE_DOCKER" ]; then
    echo "You are on the host. To enter your Docker container, run:"
    echo "docker exec -it ${docker_name} bash --login"
fi
```

---

### 6. 最佳实践建议

1. 在 Dockerfile 中设置更可靠
2. 使用 `-e` 参数启动容器时传入
3. 在容器内脚本中设置作为备选
4. 确保变量名统一，避免混淆

---

### 7. 注意事项

- 变量名区分大小写
- 确保在容器启动前设置
- 考虑变量的持久性
- 注意环境变量的作用域

---

### 8. 完整配置示例

```dockerfile
# Dockerfile
FROM base-image
ENV INSIDE_DOCKER=1
```

```bash
# 启动命令
docker run -e INSIDE_DOCKER=1 -d my-container
```

---

# 谢谢观看
## 如有问题，欢迎讨论