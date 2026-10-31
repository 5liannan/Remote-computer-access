<#
.SYNOPSIS
    Install WinFsp and SSHFS-Win on the client computer.

.DESCRIPTION
    Uses winget to install the components required to mount remote SSH/SFTP
    directories as Windows drive letters.
#>
[CmdletBinding()]
param()

$packages = @(
    @{ Id = 'WinFsp.WinFsp'; Name = 'WinFsp' },
    @{ Id = 'SSHFS-Win.SSHFS-Win'; Name = 'SSHFS-Win' }
)

foreach ($package in $packages) {
    Write-Host "Installing $($package.Name)..."

    winget install --id $package.Id -e --silent `
        --accept-package-agreements `
        --accept-source-agreements `
        --disable-interactivity

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install $($package.Name). winget exit code: $LASTEXITCODE"
    }
}

Write-Host 'WinFsp and SSHFS-Win are installed.'
