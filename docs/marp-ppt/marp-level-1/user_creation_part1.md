---
marp: true
theme: default
paginate: true
header: '用户创建与配置详解 - 第一部分'
footer: 'Marp Presentation - 代码逐行解析'
---

[父文件：install_marp.md](../install_marp.md)

---

# 用户创建与配置详解

## 父文件中要深入讲解的内容

```bash
# 创建用户并配置
for i in {1..3}; do
    username="user${i}"
    user_home="/home/$username"

    # 用 -r 选项确保完全删除旧用户
    if id "$username" &>/dev/null; then
        userdel -r "$username" 2>/dev/null || true
    fi
```

---

开始循环创建3个用户 (`user1` 到 `user3`)：
- 定义用户名和家目录变量
- 检查用户是否已存在
- 如果存在，则使用 `-r` 选项彻底删除该用户及其家目录

---

## 第一部分：用户初始化与清理

---

### 代码概览

```bash
# 创建用户并配置
for i in {1..3}; do
    username="user${i}"
    user_home="/home/$username"

    # 用 -r 选项确保完全删除旧用户
    if id "$username" &>/dev/null; then
        userdel -r "$username" 2>/dev/null || true
    fi
```

```bash
for i in {1..3}; do # 1. 循环结构设计
```

- 使用 `for` 循环创建3个用户, `{1..3}` 表示循环范围从1到3
- 每次循环将创建 `user1`、`user2`、`user3`

---

### 2. 变量定义

```bash
username="user${i}"
user_home="/home/$username"
```

- `username` 变量：
  - 使用字符串拼接 `user${i}`
  - 生成 `user1`、`user2`、`user3`
- `user_home` 变量：
  - 定义用户家目录路径
  - 格式为 `/home/$username`

---

### 3. 用户存在性检查

```bash
if id "$username" &>/dev/null; then
```

- `id` 命令：检查用户是否存在
- `&>/dev/null`：重定向所有输出
  - `&>` 表示同时重定向标准输出和错误输出
  - `/dev/null` 是空设备，丢弃所有输出

---

### 4. 用户删除操作

```bash
userdel -r "$username" 2>/dev/null || true
```

- `userdel` 命令：删除用户
- `-r` 选项：
  - 删除用户的同时删除其家目录
  - 确保环境的纯净性
- `2>/dev/null`：忽略错误信息
- `|| true`：确保命令失败不影响脚本继续执行

---

### 代码执行流程

1. 循环开始
2. 定义用户名和家目录
3. 检查用户是否存在
4. 如果存在则删除
5. 继续下一次循环

---

### 安全性考虑

- 使用 `-r` 选项确保完全清理
- 错误输出重定向避免干扰
- 使用 `|| true` 保证脚本健壮性

---

### 最佳实践总结

1. 循环结构清晰
2. 变量命名规范
3. 错误处理完善
4. 安全性考虑周全

---

## 下一部分：用户创建与权限设置