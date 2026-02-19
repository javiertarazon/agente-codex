[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot 'windows_light_elevated_entry.ps1'
if (-not (Test-Path $scriptPath)) {
    throw "Script not found: $scriptPath"
}

$p = Start-Process -FilePath 'powershell.exe' -Verb RunAs -Wait -PassThru -ArgumentList @(
    '-NoProfile',
    '-ExecutionPolicy',
    'Bypass',
    '-File',
    $scriptPath
)

Write-Output ("ELEVATED_EXIT_CODE={0}" -f $p.ExitCode)
exit $p.ExitCode
