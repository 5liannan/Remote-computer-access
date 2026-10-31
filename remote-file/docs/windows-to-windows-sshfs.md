# Windows-to-Windows 远程文件访问通用指南

本文将“在电脑 1 上像本地磁盘一样直接修改电脑 2 文件”的方案整理为通用流程。所有示例使用占位符：

| 占位符 | 含义 | 示例 |
| --- | --- | --- |
| `REMOTE_USER` | 电脑 2 上的 Windows 用户名 | `alice` |
| `REMOTE_HOST` | 电脑 2 的地址 | `192.168.1.20` 或 `100.x.x.x` |
| `REMOTE_PORT` | SSH 端口，默认 22 | `22` |
| `REMOTE_PATH` | 远程路径 | `Documents` 或 `RemoteC` |
| `X:` | 电脑 1 上的挂载盘符 | `X:` |

请把这些占位符替换为自己的值。不要把真实 IP、账户或密钥提交到公开仓库。

## 1. 方案总览

```text
电脑 1（客户端）
  挂载盘符 X:
    │
    │  SSH / SFTP 加密通道
    │  同网段：局域网 IP
    │  异网段：Tailscale IP
    ▼
电脑 2（服务端）
  OpenSSH Server
  目标目录
```

| 组件 | 安装位置 | 作用 |
| --- | --- | --- |
| OpenSSH Server | 电脑 2 | 提供 SSH/SFTP 文件访问 |
| WinFsp | 电脑 1 | Windows 文件系统代理 |
| SSHFS-Win | 电脑 1 | 把 SFTP 远程目录映射为 Windows 盘符 |
| Tailscale | 两台电脑（可选） | 异网段加密组网，保持地址稳定 |

这套方案是**远程直连编辑**，不是同步：

- 电脑 2 必须开机并可访问；
- 电脑 1 不自动保留完整副本；
- 保存文件时直接写入电脑 2；
- 网络中断时正在编辑的文件可能无法保存，重要文件应先备份。

## 2. 网络准备

### 2.1 同网段

1. 两台电脑连接同一个路由器或交换机。
2. 在电脑 2 上执行 `ipconfig`，记录 IPv4 地址，例如 `192.168.1.20`。
3. 在电脑 1 上测试：

```powershell
Test-NetConnection REMOTE_HOST -Port 22
```

`TcpTestSucceeded` 为 `True` 表示网络可达。

### 2.2 异网段 / 地址经常变化

推荐两台电脑都安装 [Tailscale](https://tailscale.com/) 并登录同一账号：

```powershell
tailscale status
tailscale ip -4
```

记录电脑 2 的 `100.x.x.x` 地址。后续无论两台电脑处于同网段还是异网段，都优先使用这个地址，避免来回修改配置。

不要把 SSH 22 端口直接映射到公网。

## 3. 服务端配置：电脑 2

### 3.1 使用脚本

在管理员 PowerShell 中执行：

```powershell
.\remote-file\scripts\Enable-OpenSSHServer.ps1
```

### 3.2 手动执行

等价命令如下：

```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

if (!(Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" `
        -DisplayName "OpenSSH Server (sshd)" `
        -Enabled True -Direction Inbound -Protocol TCP `
        -Action Allow -LocalPort 22
}

Get-Service sshd
```

`Status` 应为 `Running`。

### 3.3 用户与权限

- 使用 `whoami` 查看电脑 2 的用户名。
- 建议创建普通用户用于远程文件访问，避免长期使用 Administrator。
- 该用户需要对目标目录拥有读取和写入权限。
- 如果登录 Microsoft 账户，SSH 用户名可能与邮箱不同，以 `whoami` 输出为准。
- SSH 登录通常使用账户密码，而不是 Windows Hello PIN。

## 4. 客户端配置：电脑 1

### 4.1 安装客户端

使用脚本：

```powershell
.\remote-file\scripts\Install-SSHFSWinClient.ps1
```

或手动执行：

```powershell
winget install --id WinFsp.WinFsp -e
winget install --id SSHFS-Win.SSHFS-Win -e
```

相关项目：

- [WinFsp](https://github.com/winfsp/winfsp)
- [SSHFS-Win](https://github.com/winfsp/sshfs-win)

### 4.2 测试 SSH 登录

先确认基础连接可用：

```powershell
ssh REMOTE_USER@REMOTE_HOST
```

如果使用非默认端口：

```powershell
ssh REMOTE_USER@REMOTE_HOST -p REMOTE_PORT
```

能登录并看到电脑 2 的命令行后，输入 `exit` 退出。

## 5. SSHFS-Win 路径语法

SSHFS-Win 的 UNC 前缀决定路径基准和认证方式：

| 前缀 | 路径基准 | 认证方式 |
| --- | --- | --- |
| `\\sshfs\` | 远程用户目录 | 密码 |
| `\\sshfs.r\` | 远程根目录 | 密码 |
| `\\sshfs.k\` | 远程用户目录 | SSH 密钥 |
| `\\sshfs.kr\` | 远程根目录 | SSH 密钥 |

完整格式：

```text
\\sshfs[.r|.k|.kr]\REMOTE_USER@REMOTE_HOST[!REMOTE_PORT][\REMOTE_PATH]
```

注意：

- 自定义端口使用 `!REMOTE_PORT`，不是冒号。
- Windows UNC 路径中不能直接写 `C:`、`D:` 这类盘符。
- 密钥前缀默认使用 `%USERPROFILE%\.ssh\id_rsa`，且只支持无 passphrase 的密钥。

## 6. 密钥登录（可选）

密钥登录可避免在聊天、脚本或命令行中传递密码。更安全的选择是使用带 passphrase 的密钥并配合 SSH Agent 或 SSHFS-Win 的图形前端；但内置 `.k` / `.kr` UNC 前缀只支持无 passphrase 的默认 `id_rsa`。

### 6.1 电脑 1 生成密钥

```powershell
ssh-keygen -t rsa -b 3072 -f "$env:USERPROFILE\.ssh\id_rsa"
```

如需兼容 SSHFS-Win 内置密钥前缀，提示 passphrase 时直接回车留空。

### 6.2 把公钥加入电脑 2

在电脑 1 查看公钥：

```powershell
Get-Content "$env:USERPROFILE\.ssh\id_rsa.pub"
```

如果 `REMOTE_USER` 属于管理员组，把公钥追加到电脑 2 的：

```text
C:\ProgramData\ssh\administrators_authorized_keys
```

如果是普通用户，追加到该用户目录下的：

```text
%USERPROFILE%\.ssh\authorized_keys
```

管理员组文件需要收紧 ACL：

```powershell
icacls.exe "C:\ProgramData\ssh\administrators_authorized_keys" /inheritance:r /grant "*S-1-5-32-544:F" /grant "*S-1-5-18:F"
```

其中：

- `*S-1-5-32-544` 是 Administrators 组 SID；
- `*S-1-5-18` 是 SYSTEM SID；
- 使用 SID 可避免中文系统组名本地化带来的差异。

### 6.3 验证

```powershell
ssh -i "$env:USERPROFILE\.ssh\id_rsa" REMOTE_USER@REMOTE_HOST
```

能免密码登录即配置成功。

## 7. 挂载远程目录

### 7.1 使用脚本

```powershell
.\remote-file\scripts\Mount-RemotePath.ps1 `
    -DriveLetter X `
    -RemoteUser REMOTE_USER `
    -RemoteHost REMOTE_HOST `
    -Base Home `
    -RemotePath Documents `
    -Persistent
```

参数说明：

| 参数 | 说明 |
| --- | --- |
| `-DriveLetter` | 本地盘符，例如 `X` |
| `-RemoteUser` | 电脑 2 用户名 |
| `-RemoteHost` | 电脑 2 地址 |
| `-Port` | SSH 端口，默认 22 |
| `-Base` | `Home` 用户目录，或 `Root` 远程根目录 |
| `-RemotePath` | 相对路径，可为空 |
| `-Auth` | `Password` 或 `Key` |
| `-Persistent` | 登录时尝试自动恢复 |

### 7.2 手动挂载用户目录

```powershell
net use X: \\sshfs\REMOTE_USER@REMOTE_HOST /persistent:yes
```

### 7.3 手动挂载指定目录

例如远程用户目录下的 `Documents`：

```powershell
net use X: \\sshfs\REMOTE_USER@REMOTE_HOST\Documents /persistent:yes
```

### 7.4 使用密钥挂载

```powershell
net use X: \\sshfs.k\REMOTE_USER@REMOTE_HOST /persistent:yes
net use X: \\sshfs.kr\REMOTE_USER@REMOTE_HOST /persistent:yes
```

### 7.5 非默认端口

```powershell
net use X: \\sshfs\REMOTE_USER@REMOTE_HOST!REMOTE_PORT /persistent:yes
```

### 7.6 验证是否真的写入远程

```powershell
Set-Content -Path X:\remote-write-test.txt -Value "created from client"
ssh REMOTE_USER@REMOTE_HOST "type remote-write-test.txt"
```

如果 SSH 会话能读到同样内容，说明修改直接发生在电脑 2。

### 7.7 断开挂载

```powershell
net use X: /delete
```

## 8. 挂载整个磁盘

Windows OpenSSH 的 SFTP 根目录通常可以看到类似 `/C:`、`/D:`、`/E:` 的入口，但 Windows UNC 路径不能直接包含冒号。通用做法是在电脑 2 的用户目录创建目录链接，再挂载这些链接。

### 8.1 在电脑 2 创建磁盘入口

使用脚本：

```powershell
.\remote-file\scripts\New-RemoteDriveJunctions.ps1 -DriveLetters C,D,E
```

等价手动命令：

```powershell
New-Item -ItemType Junction -Path "$env:USERPROFILE\RemoteC" -Target "C:\"
New-Item -ItemType Junction -Path "$env:USERPROFILE\RemoteD" -Target "D:\"
New-Item -ItemType Junction -Path "$env:USERPROFILE\RemoteE" -Target "E:\"
```

这些链接只是入口，不复制文件，也不改变磁盘内容。

### 8.2 在电脑 1 分别挂载

```powershell
net use X: \\sshfs.k\REMOTE_USER@REMOTE_HOST\RemoteC /persistent:yes
net use Y: \\sshfs.k\REMOTE_USER@REMOTE_HOST\RemoteD /persistent:yes
net use Z: \\sshfs.k\REMOTE_USER@REMOTE_HOST\RemoteE /persistent:yes
```

如使用密码认证，把 `sshfs.k` 改为 `sshfs`。

### 8.3 修改显示名称

资源管理器中选中网络驱动器后按 `F2` 可直接重命名。也可以写入注册表：

```text
HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\<UNC路径编码>
```

其中 `_LabelFromReg` 字符串值就是显示名称。一般直接在资源管理器重命名更简单。

## 9. 重启后的恢复

`/persistent:yes` 会让 Windows 尝试在登录时恢复映射。如果网络或 Tailscale 尚未就绪，盘符可能暂时不可用。可重新执行：

```powershell
net use X: \\sshfs\REMOTE_USER@REMOTE_HOST /persistent:yes
```

也可以把挂载命令保存为登录脚本或计划任务，但注意：

- 不要把密码写入脚本；
- 密钥文件应设置严格权限；
- 计划任务应等待网络就绪并重试。

## 10. 常见问题排查

### 10.1 端口不可达

```powershell
Test-NetConnection REMOTE_HOST -Port 22
```

检查：

- 电脑 2 的 `sshd` 服务是否运行；
- 防火墙是否放行 22 端口；
- Tailscale 是否在线；
- 是否使用了正确的地址和端口。

### 10.2 SSH 能登录，挂载失败

检查 UNC 前缀和路径：

- 用户目录用 `sshfs` 或 `sshfs.k`；
- 根路径用 `sshfs.r` 或 `sshfs.kr`；
- 自定义端口写成 `!端口`；
- 不要在 UNC 路径里直接写 `C:`。

### 10.3 密钥登录失败

常见原因：

- 私钥路径不是 `%USERPROFILE%\.ssh\id_rsa`；
- 私钥设置了 passphrase，而内置 `.k` / `.kr` 前缀不支持；
- `authorized_keys` 或 `administrators_authorized_keys` 权限过宽；
- 公钥内容被截断或换行破坏。

### 10.4 文件只读或无法写入

检查电脑 2 上该用户对目标目录的 NTFS 权限。系统目录、其他用户目录可能默认拒绝写入。

### 10.5 性能较慢

SSHFS 适合文档和普通代码编辑。以下情况可能变慢：

- 网络延迟高或丢包；
- 一次遍历大量小文件；
- IDE 在挂载盘上建立索引；
- 远程磁盘本身速度慢。

大型代码仓库可考虑 VS Code Remote SSH；需要离线同步可考虑 Syncthing。

## 11. 安全建议

- 不要把 SSH 22 端口暴露到公网，跨网段使用 Tailscale。
- 优先使用普通用户，避免长期使用 Administrator。
- 不要把私钥、公网地址、账户密码提交到仓库。
- 修改系统盘前先备份；误删 `Windows`、`Program Files` 等目录可能导致远程电脑无法启动。
- 网络不稳定时，先复制到本地编辑，确认网络稳定后再保存回远程。

## 12. 相关替代方案

| 方案 | 特点 | 适合场景 |
| --- | --- | --- |
| SSHFS-Win | 直接读写远程文件 | 本项目主方案 |
| Windows SMB | 局域网简单，但不适合公网 | 同一局域网 |
| Syncthing | 双端各存一份，自动同步 | 需要离线编辑 |
| VS Code Remote SSH | 直接在远程环境开发 | 代码开发 |
| RDP 磁盘重定向 | 远程桌面会话内访问本地盘 | 临时使用 |

## 13. 参考

- [SSHFS-Win](https://github.com/winfsp/sshfs-win)
- [WinFsp](https://github.com/winfsp/winfsp)
- [PowerShell/Win32-OpenSSH](https://github.com/PowerShell/Win32-OpenSSH)
- [Microsoft OpenSSH for Windows](https://learn.microsoft.com/windows-server/administration/openssh/openssh_install_firstuse)
- [Tailscale](https://tailscale.com/)
- [Syncthing](https://github.com/syncthing/syncthing)
