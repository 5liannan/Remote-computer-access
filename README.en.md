# Remote Desktop Connection · RDP Profiles for LAN and Cross-Network Access

**English** | [简体中文](README.md)

A ready-to-use set of Windows Remote Desktop (RDP) profiles covering the two most common connection scenarios:

| Scenario | When it applies | Approach | Typical latency |
| --- | --- | --- | --- |
| **Same-subnet LAN** | Both machines on the same local network (one router / one Wi-Fi) | Connect to the LAN IP directly | 1–10 ms |
| **Cross-subnet** | Machines on different networks (different subnets / different sites) | Mesh them with Tailscale | Depends on the public path |

> **The one thing worth reading first**: RDP latency is decided by network RTT. Profile settings only tune image quality and bandwidth usage — **they cannot reduce physical round-trip time**. Diagnose the network first, then tune the profile.

## Quick Start

### 1. Same-subnet LAN

1. Confirm both machines are on the same subnet: run `ipconfig` on each and compare the first three octets of the IPv4 address.
2. Enable Remote Desktop on the target: `Settings → System → Remote Desktop → On`.
3. Copy `rdp/same-subnet-lan.rdp.example` and change `full address` to the target's LAN IP.
4. Double-click to connect.

### 2. Cross-subnet (Tailscale)

1. Install [Tailscale](https://tailscale.com/) on both machines and sign in with **the same account**.
2. Run `tailscale status` to confirm both nodes are listed, and note the peer's `100.x.x.x` address.
3. Copy `rdp/cross-subnet-tailscale.rdp.example` and change `full address` to the peer's Tailscale IP or MagicDNS name.
4. Double-click to connect.

## Generating Profiles with the Script

Prefer not to edit files by hand? Use `scripts/New-RdpProfile.ps1`:

```powershell
# Same subnet (LAN, full image quality)
.\scripts\New-RdpProfile.ps1 -Name "OfficePC" -Address "192.168.1.50" -Mode Lan

# Cross subnet (Tailscale, bandwidth-conscious)
.\scripts\New-RdpProfile.ps1 -Name "HomePC" -Address "100.64.0.1" -Mode Tailscale

# Custom resolution and color depth
.\scripts\New-RdpProfile.ps1 -Name "Lab" -Address "10.0.0.8" -Mode Lan -Width 1920 -Height 1080 -Bpp 32
```

## Parameter Reference

Full details in [docs/rdp-parameters.md](docs/rdp-parameters.md) (Chinese).

**The most common trap**: `connection type:i:1` does **not** mean "automatic" — it means **Modem (56 kbps)**. Setting it by mistake caps the session at 56 kbps and the screen updates crawl, which feels like "extremely high latency". See the docs for the full value table.

| Value | Meaning |
| --- | --- |
| `1` | Modem (56 kbps) |
| `4` | High-speed broadband (2–10 Mbps) |
| `6` | LAN (≥10 Mbps) — use for same-subnet |
| `7` | Automatic detection — use when unsure / cross-subnet |

## Latency Diagnosis

Before touching parameters, work through [docs/latency-diagnosis.md](docs/latency-diagnosis.md) (Chinese). It separates the two very different causes quickly:

- **The link is genuinely slow** (high RTT, packet loss, relayed path) — tuning parameters will not help;
- **The profile is misconfigured** (connection type, color depth, resolution) — tuning parameters helps immediately.

## Repository Layout

```
.
├── rdp/
│   ├── same-subnet-lan.rdp.example          # Same-subnet template
│   └── cross-subnet-tailscale.rdp.example   # Cross-subnet (Tailscale) template
├── scripts/
│   └── New-RdpProfile.ps1                   # Profile generator
├── docs/
│   ├── rdp-parameters.md                    # Parameter-by-parameter reference
│   └── latency-diagnosis.md                 # Diagnosis methodology
├── README.md                                # Chinese README
├── README.en.md                             # This file
└── LICENSE
```

## Security Notes

- Never expose RDP port 3389 directly to the public internet; prefer an encrypted mesh such as Tailscale for cross-network access.
- The templates do not store passwords (`prompt for credentials:i:1`); let Windows Credential Manager handle them.

## License

MIT
