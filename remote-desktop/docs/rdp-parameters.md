# .rdp 参数说明

`.rdp` 是纯文本的 `键:类型:值` 格式，`i` 表示整数、`s` 表示字符串。下面只列本项目用到的参数，重点是容易踩坑的几项。

## 地址与身份

| 参数 | 示例 | 说明 |
| --- | --- | --- |
| `full address:s:` | `192.168.1.100` | 目标地址。可以是局域网 IP、Tailscale IP、MagicDNS 名称或域名 |
| `username:s:` | `Administrator` | 预填用户名。留空则连接时提示 |
| `prompt for credentials:i:1` | `1` | 每次连接都提示输入密码（不依赖已保存凭据） |
| `administrative session:i:0` | `0` | `1` 表示连接管理会话（等价于 `mstsc /admin`）。普通使用填 `0` |

## 网络与性能（重点）

| 参数 | 推荐值 | 说明 |
| --- | --- | --- |
| `networkautodetect:i:` | `1` | **1 = 自动探测网络质量**。填 `0` 会强制使用下面的手动档位 |
| `bandwidthautodetect:i:` | `1` | 允许按实际带宽自动调整 |
| `connection type:i:` | `6`（局域网）/ `7`（自动） | **最易踩坑的参数，见下表** |
| `session bpp:i:` | `32` | 色深。`16` 省一半带宽但会掉色阶 |
| `compression:i:1` | `1` | 开启压缩 |
| `bitmapcachepersistenable:i:1` | `1` | 位图缓存持久化，重复画面不再重传 |

### `connection type` 取值表（务必对照）

| 值 | 含义 |
| --- | --- |
| `1` | **Modem（56 kbps）** ← 误填会让画面慢到像卡死 |
| `2` | 低速宽带（256 kbps – 2 Mbps） |
| `3` | 卫星（2 – 16 Mbps，高延迟） |
| `4` | 高速宽带（2 – 10 Mbps） |
| `5` | WAN（≥10 Mbps，较高延迟） |
| `6` | **LAN（≥10 Mbps）** ← 同网段用这个 |
| `7` | **自动探测** ← 跨网段/不确定时用这个 |

> 真实案例：把 `connection type` 写成 `1` 并同时 `networkautodetect:i:0`，等于把会话锁死在 56 kbps，表现为“延迟极高”。网络其实完全正常，改回 `7` 立刻恢复。

## 显示效果

| 参数 | 说明 |
| --- | --- |
| `screen mode id:i:2` | `2` = 全屏；`1` = 窗口 |
| `use multimon:i:1` | `1` = 启用多显示器；`0` = 只用一个屏幕 |
| `selectedmonitors:s:0,1` | 只使用指定显示器。显示器 ID 用 `mstsc /l` 查看 |
| `desktopwidth:i:` / `desktopheight:i:` | 指定远程会话分辨率。**留空则跟随本机原生分辨率**；跨高延迟链路可降到 `1280×720` 减少每帧数据 |
| `disable wallpaper:i:1` | 关闭壁纸 |
| `disable themes:i:1` | 关闭主题（退回经典外观） |
| `disable menu anims:i:1` | 关闭菜单动画 |
| `disable font smoothing:i:1` | 关闭字体平滑（文字变锐利但省数据） |
| `disable full window drag:i:1` | 拖动窗口时只显示轮廓 |
| `allow desktop composition:i:0` | 关闭桌面合成 |
| `audiomode:i:` | `0` 远端播放；`1` 不播放；`2` 拉到本地播放。省带宽用 `1` |

## 重定向

| 参数 | 说明 |
| --- | --- |
| `redirectclipboard:i:1` | 共享剪贴板 |
| `redirectdrives:i:0` | 映射本地磁盘到远端。不需要就关掉，减少开销 |
| `redirectprinters:i:0` | 映射本地打印机。不需要就关掉 |

## 参数能做什么、不能做什么

- **能**：降低带宽占用、减少每帧数据量、改善高延迟下的刷新感、提升画质（色深/分辨率）。
- **不能**：降低网络往返延迟（RTT）。若 RTT 本身是 500 ms，任何参数都无法让按键“立刻”响应。

网络排查见 [latency-diagnosis.md](latency-diagnosis.md)。
