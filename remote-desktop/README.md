# 子项目一：远程桌面访问

一套开箱即用的 Windows 远程桌面（RDP）配置方案，覆盖两种最常见的连接场景：

| 场景 | 适用条件 | 方案 | 典型延迟 |
| --- | --- | --- | --- |
| **同网段直连** | 两台机器在同一局域网（同一路由器 / WiFi） | 直连局域网 IP | 1–10 ms |
| **异网段跨连** | 两台机器在不同网络（不同网段 / 异地） | 通过 Tailscale 组网 | 取决于公网质量 |

> **核心结论写在前面**：RDP 的延迟由网络 RTT 决定。参数只能优化画质与带宽占用，**压不下物理往返延迟**。先排查网络，再调参数。

## 快速开始

### 一、同网段直连

1. 确认两台机器在同一网段：各自 `ipconfig`，看 IPv4 前三段是否一致。
2. 目标机器开启远程桌面：`设置 → 系统 → 远程桌面 → 打开`。
3. 复制 `rdp/same-subnet-lan.rdp.example`，把 `full address` 改成目标机器的局域网 IP。
4. 双击连接。

### 二、异网段跨连（Tailscale）

1. 两台机器都安装 [Tailscale](https://tailscale.com/)，登录**同一个账号**。
2. `tailscale status` 确认两台都在列表里，记下对方的 `100.x.x.x` 地址。
3. 复制 `rdp/cross-subnet-tailscale.rdp.example`，把 `full address` 改成对方的 Tailscale IP 或 MagicDNS 名称。
4. 双击连接。

## 用脚本生成配置

在仓库根目录执行：

```powershell
# 同网段（局域网，满画质）
.\remote-desktop\scripts\New-RdpProfile.ps1 -Name "OfficePC" -Address "192.168.1.50" -Mode Lan

# 异网段（Tailscale，省带宽）
.\remote-desktop\scripts\New-RdpProfile.ps1 -Name "HomePC" -Address "100.64.0.1" -Mode Tailscale

# 指定分辨率与色深
.\remote-desktop\scripts\New-RdpProfile.ps1 -Name "Lab" -Address "10.0.0.8" -Mode Lan -Width 1920 -Height 1080 -Bpp 32
```

## 参数说明

完整说明见 [docs/rdp-parameters.md](docs/rdp-parameters.md)。

**最容易踩的坑**：`connection type:i:1` 并不代表“自动”，而是 **Modem（56 kbps）**。误设会把会话限速到 56k，画面慢到像卡死。正确取值见文档。

## 延迟排查

连接卡顿先别急着改参数。按 [docs/latency-diagnosis.md](docs/latency-diagnosis.md) 的顺序排查网络，可以快速区分：

- 是**链路本身慢**（RTT 高、丢包、走中转）—— 调参数无效；
- 还是**配置错了**（档位、色深、分辨率）—— 调参数立刻见效。

## 目录结构

```text
remote-desktop/
├── rdp/
│   ├── same-subnet-lan.rdp.example
│   └── cross-subnet-tailscale.rdp.example
├── scripts/
│   └── New-RdpProfile.ps1
└── docs/
    ├── rdp-parameters.md
    └── latency-diagnosis.md
```

## 安全提示

- 不要把 RDP 的 3389 端口直接暴露到公网；跨网段优先用 Tailscale 这类加密组网。
- `rdp` 模板默认不保存密码（`prompt for credentials:i:1`），密码交给 Windows 凭据管理器。

## License

MIT
