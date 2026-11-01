# 移动热点与双屏远程桌面

整理两类常见问题：

1. 用 Windows 移动热点做“同网段直连”时，`.rdp` 里的地址该填什么；
2. 远程桌面如何在本地双屏上扩展显示。

## 1. 移动热点下的同网段直连

Windows 移动热点通常会创建一个独立的 `192.168.137.0/24` 网段：

- 主机热点网卡一般是 `192.168.137.1`
- 连接到热点的远程机器会拿到 `192.168.137.x`
- `.rdp` 里的 `full address` 应填**远程机器**的 `192.168.137.x`
- 不要填主机当前 Wi-Fi 的 `10.x.x.x` 或旧局域网 IP

排查顺序：

```powershell
# 远程机器上查看当前 IP
ipconfig

# 主机上测试 RDP 端口
Test-NetConnection 192.168.137.x -Port 3389
```

如果 `Test-NetConnection` 失败，先确认：

- 远程机器是否连到了这个热点
- 远程桌面是否已开启
- 防火墙是否放行 3389
- `.rdp` 里的 IP 是否还是旧地址

热点重启后，远程机器的 IP 可能变化。如果经常换网络，建议改用 Tailscale 地址，避免反复修改 `.rdp`。

## 2. 双屏扩展显示

远程桌面支持把本地多个显示器作为独立屏幕使用。

在 `.rdp` 中加入：

```text
screen mode id:i:2
use multimon:i:1
```

含义：

- `screen mode id:i:2`：全屏
- `use multimon:i:1`：启用多显示器

只想使用其中两个屏幕时，再加：

```text
selectedmonitors:s:0,1
```

`0,1` 是显示器 ID，可用下面命令查看：

```powershell
mstsc /l
```

注意：

- `use multimon:i:1` 是推荐方式，远程系统会把每个本地显示器识别为独立屏幕；
- `span monitors:i:1` 会把多个屏幕合并成一个大屏，一般不推荐；
- 如果远程会话只显示在一个屏幕上，先检查 `.rdp` 里是否缺少 `use multimon:i:1`。
