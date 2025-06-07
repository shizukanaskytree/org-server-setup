- Chat log with gemini: https://g.co/gemini/share/a9cc91210a48
    - https://gemini.google.com/app/99d1977b7e06c7d6
- Tutorial: https://g.co/gemini/share/b1f567207f62
    - https://gemini.google.com/app/59ed2dbc8501d002
- Docker in Docker, cleanup, and remove old ssh login key:
    - https://g.co/gemini/share/b69b53ec8087 | https://gemini.google.com/app/b410b19fd2927bcd


### How to install

```
sudo bash install.sh
```

### How to login

1.  **Go to your server (`wxf-R8280`)**.

2.  Run the `cat` command again. This command will print the correct, multi-line text content of the private key.
    ```bash
    sudo cat /home/user1/.ssh/id_ed25519
    ```

3.  The output will look something like this (this is just an example, yours will be different):
    ```
    -----BEGIN OPENSSH PRIVATE KEY-----
    b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
    QyNTUxOQAAACBo48G8zgSUuI5m8tmUa9uBbKi4VsjkvhXjD2mgIKUrdwAAAJg4BSDkOAUg
    5AAAAAtzc2gtZWQyNTUxOQAAACBo48G8zgSUuI5m8tmUa9uBbKi4VsjkvhXjD2mgIKUrdw
    AAAEAviqL01PsS5CE/ltE5I8JySspJMHh0+9WA87ez4cJYW2jjwbzOBJS4jmby2ZRr24Fs
    qLhWyOS+FeMPaaAgpSt3AAAAD3VzZXIxQHd4Zi1SODI4M.....==
    -----END OPENSSH PRIVATE KEY-----
    ```

4.  **On your Mac (`Woodys-MacBook-Pro`)**:
    * Open the file `~/.ssh/lab_user1_key` with a text editor.
    * **Delete all of its current content.**
    * **Paste the entire block** you just copied from the server, including the `-----BEGIN...` and `-----END...` lines.
    * Save the file.

5.  **Verify Permissions (on your Mac)**: Just to be safe, run this command one more time on your Mac to ensure the key file is not publicly readable.
    ```bash
    chmod 600 ~/.ssh/lab_user1_key
    ```

6.  **Connect!** Now, try the SSH command again from your Mac:
    ```bash
    ssh lab-user1
    ```

It should now connect successfully.

### 如何使用 (How to Use) Cleanup

1.  **保存脚本**: 将上面的代码保存为 `cleanup.sh` 文件。
2.  **授予执行权限**: 在终端中运行命令：
    ```bash
    chmod +x cleanup.sh
    ```
3.  **以 root 权限运行**:
    ```bash
    sudo ./cleanup.sh
    ```

脚本会分步执行，并打印出它正在做的操作。在删除包含用户数据的 `/data1/org/user_workspaces` 目录前，它会**停下来并请求你确认**，以防止意外删除重要数据。

### 3. 清理完成后

当 `cleanup.sh` 脚本成功运行完毕后，你的系统就回到了运行旧 `install.sh` 之前的干净状态。


### 从 known_hosts 文件中移除与 lab-user1 相关的旧密钥

在您的 MacBook Pro 的终端 中执行以下命令。这个命令会自动从 known_hosts 文件中移除与 lab-user1 相关的旧密钥。

```
ssh-keygen -R lab-user1
```
备用命令：如果 lab-user1 是一个别名，您也可以使用错误信息中提示的 IP 和端口来移除密钥，效果是相同的：

注意，因为有特殊字符，最好用引号括起来
```
ssh-keygen -R "[172.30.101.111]:2201"
```

现在，你可以安全地运行你修改后的新 `install.sh` 脚本来重新部署环境了。