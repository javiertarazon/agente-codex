[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$main = Join-Path $root 'windows_light_admin.ps1'
$statusDir = if (Test-Path 'D:\') { 'D:\BootRescue' } else { 'C:\BootRescue' }
$statusFile = Join-Path $statusDir 'windows_light_last_status.txt'

if (-not (Test-Path $main)) {
    "FAILED $(Get-Date -Format o) - main script missing: $main" | Set-Content -Path $statusFile -Encoding UTF8
    exit 2
}

try {
    & $main
    "SUCCESS $(Get-Date -Format o)" | Set-Content -Path $statusFile -Encoding UTF8
    exit 0
}
catch {
    $msg = $_ | Out-String
    "FAILED $(Get-Date -Format o)`r`n$msg" | Set-Content -Path $statusFile -Encoding UTF8
    exit 1
}
