# 子项目二：远程文件访问

让电脑 1 把电脑 2 的目录挂载成本地盘符。你在电脑 1 打开、修改、保存文件时，**实际写入的是电脑 2**，不需要先下载再上传，也不会自动保留一份本地副本。

```text
电脑 1
  Z: 盘
   │
   │  SSH / SFTP 加密通道
   │  同网段：局域网 IP
   │  异网段：Tailscale IP
   ▼
电脑 2
  目标目录
```

## 适用场景

| 场景 | 是否适合 |
| --- | --- |
| 在电脑 1 上直接修改电脑 2 的文档、代码、配置 | 适合 |
| 两台电脑偶尔同网段、偶尔异网段 | 适合，用 Tailscale 保持地址不变 |
| 需要操作远程电脑整个桌面 | 不适合，请使用 [远程桌面访问](../remote-desktop/README.md) |
| 断网后仍要继续编辑，之后再同步 | 不适合，请考虑 Syncthing 等同步工具 |

## 技术方案

- 服务端：Windows OpenSSH Server
- 客户端：WinFsp + SSHFS-Win
- 网络层：局域网直连，或 Tailscale 加密组网
- 认证方式：密码，或 SSH 密钥

## 快速开始

详细步骤见 [docs/windows-to-windows-sshfs.md](docs/windows-to-windows-sshfs.md)。

1. 电脑 2 开启 OpenSSH Server：

   ```powershell
   .\remote-file\scripts\Enable-OpenSSHServer.ps1
   ```

2. 电脑 1 安装 SSHFS-Win 客户端：

   ```powershell
   .\remote-file\scripts\Install-SSHFSWinClient.ps1
   ```

3. 电脑 1 测试 SSH 连接：

   ```powershell
   ssh REMOTE_USER@REMOTE_HOST
   ```

4. 电脑 1 挂载远程用户目录：

   ```powershell
   .\remote-file\scripts\Mount-RemotePath.ps1 -DriveLetter Z -RemoteUser REMOTE_USER -RemoteHost REMOTE_HOST -Base Home
   ```

5. 打开 `Z:\`，直接编辑远程文件。

## 挂载整个磁盘

Windows 的 UNC 路径不能直接包含 `C:` 这类盘符。若要分别挂载远程 C/D/E 盘，推荐在电脑 2 的用户目录下创建目录链接：

```powershell
.\remote-file\scripts\New-RemoteDriveJunctions.ps1 -DriveLetters C,D,E
```

然后在电脑 1 分别挂载：

```powershell
.\remote-file\scripts\Mount-RemotePath.ps1 -DriveLetter X -RemoteUser REMOTE_USER -RemoteHost REMOTE_HOST -Base Home -RemotePath RemoteC
.\remote-file\scripts\Mount-RemotePath.ps1 -DriveLetter Y -RemoteUser REMOTE_USER -RemoteHost REMOTE_HOST -Base Home -RemotePath RemoteD
.\remote-file\scripts\Mount-RemotePath.ps1 -DriveLetter Z -RemoteUser REMOTE_USER -RemoteHost REMOTE_HOST -Base Home -RemotePath RemoteE
```

## 目录结构

```text
remote-file/
├── README.md
├── docs/
│   └── windows-to-windows-sshfs.md
└── scripts/
    ├── Enable-OpenSSHServer.ps1
    ├── New-RemoteDriveJunctions.ps1
    ├── Install-SSHFSWinClient.ps1
    └── Mount-RemotePath.ps1
```

## 安全提示

- 不要把 SSH 22 端口直接暴露到公网；跨网段优先使用 Tailscale。
- 尽量使用普通用户，不要长期使用 Administrator。
- 修改远程系统盘文件前先备份，误删系统文件可能导致远程电脑无法启动。
- SSHFS-Win 内置密钥挂载方式只支持无 passphrase 的默认 `id_rsa`；更安全的做法见详细文档。

## License

MIT
