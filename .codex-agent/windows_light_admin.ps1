[CmdletBinding()]
param(
    [switch]$SkipServiceTuning,
    [switch]$SkipAppTuning,
    [switch]$SkipUpdateBlock
)

$ErrorActionPreference = "Stop"

function Assert-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "Run this script from an elevated PowerShell (Run as Administrator)."
    }
}

function Write-Log {
    param([string]$Message)
    Write-Host "[WIN-LIGHT] $Message"
}

function Invoke-Safe {
    param(
        [string]$Label,
        [scriptblock]$Action
    )

    try {
        & $Action
        Write-Log "${Label}: OK"
    }
    catch {
        Write-Log "${Label}: FAILED - $($_.Exception.Message)"
    }
}

function Disable-ServiceSafe {
    param([string]$Name)

    $svc = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if ($null -eq $svc) {
        Write-Log "Service $Name not found; skipped."
        return
    }

    Invoke-Safe "Stop service $Name" { Stop-Service -Name $Name -Force -ErrorAction Stop }
    Invoke-Safe "Disable service $Name" { Set-Service -Name $Name -StartupType Disabled -ErrorAction Stop }
}

Assert-Admin

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupRoot = if (Test-Path "D:\") { "D:\BootRescue" } else { "C:\BootRescue" }
$backupDir = Join-Path $backupRoot "win-light-$timestamp"
$reportPath = Join-Path $PSScriptRoot "windows_light_report.json"

New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
Write-Log "Backup folder: $backupDir"

# Baseline snapshots
Get-CimInstance Win32_OperatingSystem |
    Select-Object CSName, TotalVisibleMemorySize, FreePhysicalMemory |
    Out-File -Encoding UTF8 (Join-Path $backupDir "os-memory-before.txt")

Get-CimInstance Win32_ComputerSystem |
    Select-Object AutomaticManagedPagefile |
    Out-File -Encoding UTF8 (Join-Path $backupDir "pagefile-mode-before.txt")

Get-Service wuauserv, bits, usosvc, WaaSMedicSvc, SysMain, DiagTrack, dmwappushservice -ErrorAction SilentlyContinue |
    Select-Object Name, Status, StartType |
    Out-File -Encoding UTF8 (Join-Path $backupDir "services-before.txt")

cmd /c "reg export HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate \"$backupDir\\wu-policy-before.reg\" /y" | Out-Null

# 1) Virtual memory optimized: keep automatic system-managed pagefile.
Invoke-Safe "Enable AutomaticManagedPagefile" {
    $cs = Get-CimInstance Win32_ComputerSystem
    if (-not $cs.AutomaticManagedPagefile) {
        Set-CimInstance -InputObject $cs -Property @{ AutomaticManagedPagefile = $true } | Out-Null
    }
}

# 2) Reduce background pressure.
if (-not $SkipServiceTuning) {
    Write-Log "Applying service tuning..."
    $servicesToDisable = @(
        "SysMain",
        "DiagTrack",
        "dmwappushservice",
        "XblAuthManager",
        "XblGameSave",
        "XboxGipSvc",
        "XboxNetApiSvc"
    )

    foreach ($svcName in $servicesToDisable) {
        Disable-ServiceSafe -Name $svcName
    }
}
else {
    Write-Log "Service tuning skipped by switch."
}

if (-not $SkipAppTuning) {
    Write-Log "Applying startup/background app tuning..."

    Invoke-Safe "Disable background apps globally (current user)" {
        New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Force | Out-Null
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Type DWord -Value 1
    }

    $runKeys = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run"
    )

    $startupEntries = @("OneDrive", "Teams", "Microsoft Teams", "Skype", "Copilot")
    foreach ($key in $runKeys) {
        foreach ($entry in $startupEntries) {
            Invoke-Safe "Remove startup '$entry' from $key" {
                if (Get-ItemProperty -Path $key -Name $entry -ErrorAction SilentlyContinue) {
                    Remove-ItemProperty -Path $key -Name $entry -ErrorAction Stop
                }
            }
        }
    }
}
else {
    Write-Log "App tuning skipped by switch."
}

# 3) Block Windows updates (requested explicitly by user).
if (-not $SkipUpdateBlock) {
    Write-Log "Applying strong Windows Update block..."

    Invoke-Safe "Set update policy registry keys" {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Force | Out-Null
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force | Out-Null

        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "DoNotConnectToWindowsUpdateInternetLocations" -Type DWord -Value 1
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "DisableWindowsUpdateAccess" -Type DWord -Value 1
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Type DWord -Value 1
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -Type DWord -Value 1
    }

    $updateServices = @("wuauserv", "bits", "usosvc")
    foreach ($svcName in $updateServices) {
        Disable-ServiceSafe -Name $svcName
    }

    # WaaSMedicSvc can be protected on some builds; best effort with sc.exe.
    Invoke-Safe "Disable WaaSMedicSvc with sc.exe" {
        cmd /c "sc config WaaSMedicSvc start= disabled" | Out-Null
        cmd /c "sc stop WaaSMedicSvc" | Out-Null
    }

    $tasksToDisable = @(
        "\\Microsoft\\Windows\\WindowsUpdate\\Scheduled Start",
        "\\Microsoft\\Windows\\UpdateOrchestrator\\Schedule Scan",
        "\\Microsoft\\Windows\\UpdateOrchestrator\\USO_UxBroker_Display",
        "\\Microsoft\\Windows\\UpdateOrchestrator\\Maintenance Install"
    )

    foreach ($taskPath in $tasksToDisable) {
        Invoke-Safe "Disable scheduled task $taskPath" {
            cmd /c "schtasks /Change /TN \"$taskPath\" /Disable" | Out-Null
        }
    }
}
else {
    Write-Log "Update block skipped by switch."
}

# Save after-state and an undo helper.
Get-CimInstance Win32_ComputerSystem |
    Select-Object AutomaticManagedPagefile |
    Out-File -Encoding UTF8 (Join-Path $backupDir "pagefile-mode-after.txt")

Get-Service wuauserv, bits, usosvc, WaaSMedicSvc, SysMain, DiagTrack, dmwappushservice -ErrorAction SilentlyContinue |
    Select-Object Name, Status, StartType |
    Out-File -Encoding UTF8 (Join-Path $backupDir "services-after.txt")

$undo = @'
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Write-Host "[UNDO-WIN-LIGHT] Re-enabling core update services and removing update block policies..."

reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /f
sc config wuauserv start= demand
sc config bits start= delayed-auto
sc config usosvc start= demand
sc config WaaSMedicSvc start= demand

sc start wuauserv
sc start bits

Write-Host "[UNDO-WIN-LIGHT] Undo completed. A reboot is recommended."
'@

Set-Content -Path (Join-Path $backupDir "undo_windows_light.ps1") -Encoding ASCII -Value $undo

$report = [ordered]@{
    timestamp = (Get-Date).ToString("o")
    backup_dir = $backupDir
    automatic_managed_pagefile = (Get-CimInstance Win32_ComputerSystem).AutomaticManagedPagefile
    note = "Optimization applied. Reboot recommended."
}

$report | ConvertTo-Json | Set-Content -Path $reportPath -Encoding ASCII

Write-Log "Done. Backup and logs in: $backupDir"
Write-Log "Undo helper: $(Join-Path $backupDir 'undo_windows_light.ps1')"
Write-Log "Report: $reportPath"
Write-Log "Recommended next step: restart Windows."
