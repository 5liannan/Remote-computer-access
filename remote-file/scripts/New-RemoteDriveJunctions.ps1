<#
.SYNOPSIS
    Create junction links for remote drive letters under the current user profile.

.DESCRIPTION
    SSHFS-Win UNC paths cannot contain Windows drive-letter syntax such as C:.
    This script creates junction links named RemoteC, RemoteD, etc. under the
    specified base path. The client can then mount these links as drive letters.

.EXAMPLE
    .\New-RemoteDriveJunctions.ps1 -DriveLetters C,D,E
#>
[CmdletBinding()]
param(
    [ValidateSet('C', 'D', 'E', 'F', 'G', 'H')]
    [string[]]$DriveLetters = @('C', 'D', 'E'),

    [string]$BasePath = $env:USERPROFILE
)

if (-not (Test-Path -LiteralPath $BasePath)) {
    throw "Base path does not exist: $BasePath"
}

foreach ($drive in $DriveLetters) {
    $target = '{0}:\' -f $drive
    $linkName = 'Remote' + $drive
    $linkPath = Join-Path $BasePath $linkName

    if (-not (Test-Path -LiteralPath $target)) {
        Write-Warning "Drive not found, skipped: $target"
        continue
    }

    if (Test-Path -LiteralPath $linkPath) {
        Write-Warning "Link already exists, skipped: $linkPath"
        continue
    }

    New-Item -ItemType Junction -Path $linkPath -Target $target | Out-Null
    Write-Host "Created: $linkPath -> $target"
}
