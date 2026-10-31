<#
.SYNOPSIS
    生成一份针对局域网或 Tailscale 优化过的 Windows 远程桌面 (.rdp) 配置文件。

.DESCRIPTION
    Mode Lan        同网段直连：connection type=6 (LAN)，保留完整视觉效果。
    Mode Tailscale  异网段跨连：connection type=7 (自动)，关闭壁纸/主题/动画等以节省带宽。

.PARAMETER Name
    生成的 .rdp 文件名（不含扩展名）。

.PARAMETER Address
    目标地址：局域网 IP，或 Tailscale IP / MagicDNS 名称。

.PARAMETER Mode
    Lan 或 Tailscale，默认 Lan。

.PARAMETER Username
    可选。预填用户名；留空则连接时提示输入。

.PARAMETER Width / Height
    可选。指定远程会话分辨率；留空则跟随本机原生分辨率。

.PARAMETER Bpp
    色深，默认 32。

.EXAMPLE
    .\New-RdpProfile.ps1 -Name "OfficePC" -Address "192.168.1.50" -Mode Lan

.EXAMPLE
    .\New-RdpProfile.ps1 -Name "HomePC" -Address "100.64.0.1" -Mode Tailscale

.EXAMPLE
    .\New-RdpProfile.ps1 -Name "Lab" -Address "10.0.0.8" -Mode Lan -Width 1920 -Height 1080
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Name,

    [Parameter(Mandatory = $true)]
    [string]$Address,

    [ValidateSet('Lan', 'Tailscale')]
    [string]$Mode = 'Lan',

    [string]$Username = '',

    [int]$Width = 0,

    [int]$Height = 0,

    [ValidateSet(8, 15, 16, 24, 32)]
    [int]$Bpp = 32,

    [string]$OutDir = '.'
)

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add("full address:s:$Address")
if ($Username) { $lines.Add("username:s:$Username") }
$lines.Add('prompt for credentials:i:1')
$lines.Add('administrative session:i:0')
$lines.Add('audiomode:i:1')
$lines.Add('redirectclipboard:i:1')
$lines.Add('screen mode id:i:2')

if ($Width -gt 0 -and $Height -gt 0) {
    $lines.Add("desktopwidth:i:$Width")
    $lines.Add("desktopheight:i:$Height")
}

$lines.Add('networkautodetect:i:1')
$lines.Add('bandwidthautodetect:i:1')

if ($Mode -eq 'Lan') {
    # 局域网带宽充足：LAN 档位，保留完整视觉效果
    $lines.Add('connection type:i:6')
}
else {
    # 跨网段：自动档位，关闭视觉效果以省带宽
    $lines.Add('connection type:i:7')
}

$lines.Add("session bpp:i:$Bpp")
$lines.Add('compression:i:1')
$lines.Add('bitmapcachepersistenable:i:1')
$lines.Add('redirectprinters:i:0')
$lines.Add('redirectdrives:i:0')

if ($Mode -eq 'Tailscale') {
    $lines.Add('disable wallpaper:i:1')
    $lines.Add('disable themes:i:1')
    $lines.Add('disable menu anims:i:1')
    $lines.Add('disable font smoothing:i:1')
    $lines.Add('disable full window drag:i:1')
    $lines.Add('allow desktop composition:i:0')
}

if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

$path = Join-Path $OutDir "$Name.rdp"
$content = ($lines -join "`r`n") + "`r`n"

# .rdp 内容为纯 ASCII 时写 ASCII；含中文用户名时写 UTF-16LE（mstsc 原生支持）
if ($content -match '^[\x00-\x7F]*$') {
    Set-Content -Path $path -Value $content -Encoding ASCII -NoNewline
}
else {
    Set-Content -Path $path -Value $content -Encoding Unicode -NoNewline
}

Write-Host "已生成: $path"
Write-Host "模式: $Mode | 目标: $Address | 色深: $Bpp-bit"
