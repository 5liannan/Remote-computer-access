# 延迟诊断方法论

远程桌面卡顿时，先回答一个问题：**是网络慢，还是配置错？** 按下面的顺序测，几分钟就能定位。

## 第 0 步：先看是不是配置问题

如果**以前同一个网络下很流畅，改过 `.rdp` 之后变卡**，优先怀疑参数。最常见的错误：

- `connection type:i:1`（Modem 56 kbps）
- 同时 `networkautodetect:i:0`

把这两个改成 `connection type:i:7` + `networkautodetect:i:1` 再试。参数说明见 [rdp-parameters.md](rdp-parameters.md)。

## 第 1 步：基础 RTT（ICMP）

```powershell
ping -n 10 <目标地址>
```

关注**平均值**和**最大值**（抖动），不只看单次。

| 平均 RTT | 结论 |
| --- | --- |
| 1–10 ms | 正常局域网，RDP 应非常跟手 |
| 20–80 ms | 可接受，轻微迟滞 |
| 100–200 ms | 明显迟滞，基本操作可用 |
| > 300 ms | 体验很差，交互明显滞后 |

> 注意：很多公网 IP 会屏蔽 ICMP，`ping` 超时**不代表端口不通**，需要下一步用 TCP 测。

## 第 2 步：RDP 端口是否可达（TCP 3389）

```powershell
Test-NetConnection -ComputerName <目标地址> -Port 3389
```

看 `TcpTestSucceeded`。`True` 才说明 RDP 服务可达。

## 第 3 步：Tailscale 场景专项排查

```powershell
tailscale status          # 看对端是 direct 还是 relay
tailscale ping <对端IP>    # 逐包看路径和延迟
tailscale netcheck        # 看 UDP 可达性、NAT 类型、DERP 延迟
```

### 关键判读

**`tailscale ping` 的输出**

```
pong from node (100.x.x.x) via DERP(hkg) in 1146ms      ← 走中转，慢
pong from node (100.x.x.x) via 203.0.113.5:62319 in 82ms ← 直连，快
```

- `via DERP(...)` = 走了中继服务器，延迟高且受中转节点位置影响。
- `via <IP>:<port>` = 点对点直连。

**`tailscale netcheck` 的输出**

```
UDP: true
MappingVariesByDestIP: true    ← 对称 NAT
Nearest DERP: Hong Kong
```

- `MappingVariesByDestIP: true` 即**对称 NAT**：UDP 打洞基本失败，只能走 DERP 中转。这是 P2P 无法直连的常见根因。
- 若两端都没有公网 IPv6，IPv6 直连也无法救场。

**`tailscale status` 的输出**

```
100.x.x.x  node  user@  windows  active; direct 203.0.113.5:62319, tx ... rx ...
```

`direct` 后跟公网地址 = 直连；`relay "xxx"` = 中转。

## 第 4 步：对照结论

| 现象 | 根因 | 对策 |
| --- | --- | --- |
| 局域网 ping 1–5 ms，但 RDP 卡 | 参数错误 | 查 `connection type`、色深、分辨率 |
| ping 100–200 ms，RDP 迟滞 | 无线/热点链路抖动 | 换有线或 5 GHz，减少干扰 |
| `tailscale ping` 显示 DERP 中转 1 s+ | 对称 NAT / UDP 被封 | 改用同一局域网，或换 TCP 类远控 |
| 公网直连仍 500 ms+ 且丢包 | 公网路径拥塞 / 运营商限速 | 无法靠参数解决，换网络或换工具 |
| `TcpTestSucceeded: False` | 端口不通 / 防火墙 | 检查目标机远程桌面开关与防火墙 |

## 一个重要事实

**RDP 参数无法降低网络 RTT。** 如果诊断显示链路本身 500 ms，那么降分辨率、降色深只能减少每帧数据量、让刷新稍快，按键和鼠标的往返延迟依旧存在。

想要真正跟手，只能从网络侧解决：

1. 两台机器接入**同一个局域网**（有线或同一 WiFi）；
2. 或使用对丢包更鲁棒的方案（如基于 TCP 443 的远控工具）；
3. 跨网段时，尽量让两端都具备可打洞的网络环境（非对称 NAT、公网 IPv6 等）。

## 附：本次真实案例数据

| 场景 | 实测 | 说明 |
| --- | --- | --- |
| 同一移动热点 | 平均 141 ms | 可用，但无线抖动大 |
| 同网段有线/同 WiFi | 1–10 ms | 理想 |
| Tailscale 公网直连（对称 NAT） | 500–800 ms，丢包 | 不可用 |
| Tailscale DERP 中转（香港） | ~1.1 s | 不可用 |

结论：跨公网 + 对称 NAT 的组合下，Tailscale 的直连并不等于低延迟；RDP 参数无法挽救。
