---
marp: true
theme: default
paginate: true
header: 'Docker容器登录提示配置详解'
footer: 'Marp Presentation - Login Prompt Configuration'
---

[父文件：install_marp.md](../install_marp.md)

# Docker容器登录提示配置详解

## 父文件中要深入讲解的内容

```bash
docker_name="${username}-container"
cat > "$user_home/.bash_profile" <<EOF
if [ -z "\$INSIDE_DOCKER" ]; then
    echo "You are on the host. To enter your Docker container, run:"
    echo "docker exec -it ${docker_name} bash --login"
fi
EOF
chown "$username":"$username" "$user_home/.bash_profile"
```

配置用户的登录提示信息：
- 创建 `.bash_profile` 文件
- 当用户在主机登录时，提示如何进入 Docker 容器

## `.bash_profile` 配置分析

---

### 1. 变量定义

```bash
docker_name="${username}-container"
```

- `${username}`: 使用当前循环中的用户名
- 变量命名规范：使用下划线分隔的小写字母
- 最终生成的容器名称格式：`user1-container`, `user2-container` 等

---

### 2. 文件创建语法

```bash
cat > "$user_home/.bash_profile" <<EOF
```

- `cat`: 用于读取和写入文件
- `>`: 重定向操作符，创建新文件或覆盖已存在的文件
- `<<EOF`: Here Document 语法，用于多行文本输入
- `$user_home`: 用户家目录的路径变量

---

### 3. 条件判断语句

```bash
if [ -z "\$INSIDE_DOCKER" ]; then
```

- `if`: 条件判断语句的开始
- `[ -z ]`: 测试字符串长度是否为0
- `\$INSIDE_DOCKER`: 环境变量，用于判断是否在Docker容器内
- `\$`: 转义符号，确保变量在写入文件时不被展开

[环境变量解释](marp-level-2/inside_docker_explanation.md)

---

### 4. 提示信息输出

```bash
    echo "You are on the host. To enter your Docker container, run:"
    echo "docker exec -it ${docker_name} bash --login"
```

- `echo`: 输出文本到标准输出
- 第一行：提示用户当前在主机上
- 第二行：显示进入容器的具体命令
- `${docker_name}`: 动态插入容器名称

---

### 5. 条件语句结束

```bash
fi
```

- `fi`: 结束if条件语句
- 与开头的`if`配对使用

---

### 6. Here Document结束

```bash
EOF
```

- `EOF`: 标记Here Document的结束
- 必须单独一行
- 前面不能有空格

---

### 7. 文件权限设置

```bash
chown "$username":"$username" "$user_home/.bash_profile"
```

- `chown`: 更改文件所有者和组, 这里使用了 "\$username":"\$username" 的格式，表示将文件的所有者和组都设置为同一个用户
    - 用户登录后，只能修改自己的 `.bash_profile` 文件
    - 其他用户无法修改或删除这个文件
- 格式：`chown 用户:组 文件`
- 确保文件属于正确的用户
- [chown命令详解](marp-level-2/chown_command_explanation.md)

---

### 8. 完整代码示例

```bash
docker_name="${username}-container"
cat > "$user_home/.bash_profile" <<EOF
if [ -z "\$INSIDE_DOCKER" ]; then
    echo "You are on the host. To enter your Docker container, run:"
    echo "docker exec -it ${docker_name} bash --login"
fi
EOF
chown "$username":"$username" "$user_home/.bash_profile"
```

---

### 9. 执行效果

当用户登录主机时：
1. 系统检查 `$INSIDE_DOCKER` 环境变量
2. 如果变量为空（在主机上）：
   - 显示提示信息
   - 显示进入容器的命令
3. 如果变量不为空（在容器内）：
   - 不显示任何提示

---

### 10. 安全考虑

- 文件权限：确保只有用户自己可以读写
- 变量转义：防止变量在写入时被展开
- 路径安全：使用变量而不是硬编码路径

---

# 谢谢观看
## 如有问题，欢迎讨论