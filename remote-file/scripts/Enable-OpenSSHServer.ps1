#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Enable Windows OpenSSH Server for remote file access.

.DESCRIPTION
    Installs the OpenSSH Server optional capability, starts sshd, sets it to
    start automatically, and creates the default firewall rule for TCP 22.
#>
[CmdletBinding()]
param()

$capabilityName = 'OpenSSH.Server~~~~0.0.1.0'

$capability = Get-WindowsCapability -Online -Name $capabilityName
if ($capability.State -ne 'Installed') {
    Add-WindowsCapability -Online -Name $capabilityName | Out-Null
}

$service = Get-Service -Name sshd -ErrorAction SilentlyContinue
if ($null -eq $service) {
    throw 'OpenSSH Server capability is installed, but the sshd service was not found.'
}

Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

if (-not (Get-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' `
        -DisplayName 'OpenSSH Server (sshd)' `
        -Enabled True `
        -Direction Inbound `
        -Protocol TCP `
        -Action Allow `
        -LocalPort 22 | Out-Null
}

Get-Service sshd
Write-Host 'OpenSSH Server is ready on TCP port 22.'
