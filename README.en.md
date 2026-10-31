# Remote Computer Access · Windows Remote Access Toolkit

**English** | [简体中文](README.md)

A Windows-oriented remote access toolkit with two independent subprojects:

| Subproject | Access type | Typical use | Stack |
| --- | --- | --- | --- |
| [Remote Desktop Access](remote-desktop/README.md) | Operate the full remote desktop | Remote work, administration, GUI apps | Windows RDP + LAN / Tailscale |
| [Remote File Access](remote-file/README.md) | Edit remote files as if they were local drives | Documents, code, configuration files | OpenSSH/SFTP + SSHFS-Win + LAN / Tailscale |

## Network layer

Both subprojects support:

1. **Same-subnet LAN**: connect directly using the LAN IP.
2. **Cross-subnet access**: mesh both machines with [Tailscale](https://tailscale.com/) and use the stable `100.x.x.x` address.

Do not expose RDP port 3389 or SSH port 22 directly to the public internet.

## Repository layout

```text
.
├── remote-desktop/   # RDP profiles, scripts, and tuning docs
├── remote-file/      # SSHFS-based remote file access guide and scripts
├── README.md         # Chinese overview
├── README.en.md      # This file
└── LICENSE
```

## License

MIT
