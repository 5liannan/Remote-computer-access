# Remote Computer Access · Windows 远程电脑访问方案

**简体中文** | [English](README.en.md)

一套面向 Windows 的远程电脑访问方案，包含两个独立子项目：

| 子项目 | 访问方式 | 典型用途 | 技术方案 |
| --- | --- | --- | --- |
| [子项目一：远程桌面访问](remote-desktop/README.md) | 操作整个远程桌面 | 远程办公、远程运维、图形界面操作 | Windows RDP + 局域网 / Tailscale |
| [子项目二：远程文件访问](remote-file/README.md) | 像本地磁盘一样直接编辑远程文件 | 远程改文档、代码、配置文件 | OpenSSH/SFTP + SSHFS-Win + 局域网 / Tailscale |

## 两个子项目的区别

- **远程桌面访问**：你在本地看到并操作电脑 2 的整个桌面，适合需要运行远程程序、查看图形界面的场景。
- **远程文件访问**：电脑 2 的目录挂载为电脑 1 的盘符，打开、修改、保存都直接写入电脑 2，适合只需要处理文件、不希望占用远程桌面的场景。

## 共同网络层

两个子项目都支持：

1. **同网段直连**：两台电脑在同一局域网，直接使用局域网 IP。
2. **异网段跨连**：两台电脑在不同网络，通过 [Tailscale](https://tailscale.com/) 组网后使用 `100.x.x.x` 地址。

跨网段时不建议把 RDP 3389 或 SSH 22 端口直接暴露到公网，优先使用加密组网。

## 目录结构

```text
.
├── remote-desktop/          # 子项目一：远程桌面访问
│   ├── README.md
│   ├── rdp/                 # .rdp 模板
│   ├── scripts/             # 配置生成脚本
│   └── docs/                # 参数与延迟诊断文档
├── remote-file/             # 子项目二：远程文件访问
│   ├── README.md
│   ├── docs/                # 通用 SSHFS 配置指南
│   └── scripts/             # 服务端与客户端辅助脚本
├── README.md                # 总入口（本文件）
├── README.en.md             # English overview
└── LICENSE
```

## 快速选择

| 需求 | 推荐 |
| --- | --- |
| 想操作远程电脑的整个桌面 | [remote-desktop](remote-desktop/README.md) |
| 想在本地直接修改远程文件 | [remote-file](remote-file/README.md) |
| 两台电脑偶尔同网段、偶尔异网段 | 两个子项目都可搭配 Tailscale，保持地址不变 |
| 需要离线也能编辑，之后自动同步 | 本项目不适合，请考虑 Syncthing 等同步工具 |

## 安全提示

- 不要将 RDP 3389、SSH 22 等端口直接映射到公网。
- 跨网段访问优先使用 Tailscale 等加密组网。
- 远程文件访问建议使用普通用户，不建议长期使用 Administrator。
- 修改远程系统盘文件前先备份，误删系统文件可能导致远程电脑无法启动。

## License

MIT
