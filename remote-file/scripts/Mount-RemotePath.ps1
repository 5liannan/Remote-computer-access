<#
.SYNOPSIS
    Mount a remote SSHFS-Win path as a Windows drive letter.

.DESCRIPTION
    Builds the SSHFS-Win UNC path and maps it with net use.

.PARAMETER DriveLetter
    Local drive letter, for example X.

.PARAMETER RemoteUser
    User name on the remote computer.

.PARAMETER RemoteHost
    Remote computer address.

.PARAMETER Port
    Remote SSH port. Default is 22.

.PARAMETER RemotePath
    Optional path relative to the selected base.

.PARAMETER Base
    Home: remote user home directory.
    Root: remote filesystem root.

.PARAMETER Auth
    Password or Key. Key mode uses SSHFS-Win's .k/.kr prefixes.

.PARAMETER Persistent
    Try to restore the mapping at sign-in.

.EXAMPLE
    .\Mount-RemotePath.ps1 -DriveLetter X -RemoteUser alice -RemoteHost 100.64.0.1 -Base Home

.EXAMPLE
    .\Mount-RemotePath.ps1 -DriveLetter X -RemoteUser alice -RemoteHost 100.64.0.1 -Base Home -RemotePath RemoteC -Auth Key -Persistent
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[A-Za-z]$')]
    [string]$DriveLetter,

    [Parameter(Mandatory = $true)]
    [string]$RemoteUser,

    [Parameter(Mandatory = $true)]
    [string]$RemoteHost,

    [int]$Port = 22,

    [string]$RemotePath = '',

    [ValidateSet('Home', 'Root')]
    [string]$Base = 'Home',

    [ValidateSet('Password', 'Key')]
    [string]$Auth = 'Password',

    [switch]$Persistent
)

if ($RemotePath -match '^[A-Za-z]:') {
    throw 'Windows drive-letter paths such as C:\ cannot be used directly in SSHFS-Win UNC paths. Create a junction link such as RemoteC first.'
}

$prefix = switch ("$Base-$Auth") {
    'Home-Password' { 'sshfs' }
    'Root-Password' { 'sshfs.r' }
    'Home-Key' { 'sshfs.k' }
    'Root-Key' { 'sshfs.kr' }
    default { throw "Unsupported mode: $Base-$Auth" }
}

$hostPart = $RemoteHost
if ($Port -ne 22) {
    $hostPart = '{0}!{1}' -f $RemoteHost, $Port
}

$normalizedPath = $RemotePath.Trim('\', '/').Replace('/', '\')

$uncPath = '\\{0}\{1}@{2}' -f $prefix, $RemoteUser, $hostPart
if ($normalizedPath) {
    $uncPath = '{0}\{1}' -f $uncPath, $normalizedPath
}

$drive = '{0}:' -f $DriveLetter.ToUpperInvariant()
$netArguments = @('use', $drive, $uncPath)
if ($Persistent) {
    $netArguments += '/persistent:yes'
}

Write-Host "Mounting $uncPath as $drive"
& net @netArguments

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "Mounted $drive -> $uncPath"
