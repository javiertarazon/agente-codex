[CmdletBinding()]
param(
    [string]$IntelInfName = "oem6.inf",
    [switch]$SkipDriverRollback,
    [switch]$SkipBcdRebuild
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
    Write-Host "[BOOT-FIX] $Message"
}

Assert-Admin

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupRoot = if (Test-Path "D:\") { "D:\BootRescue" } else { "C:\BootRescue" }
$backupDir = Join-Path $backupRoot "boot-backup-$timestamp"
$espDrive = "S:"
$systemWindows = "C:\Windows"

New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
Write-Log "Backup folder: $backupDir"

# Collect baseline data for future forensics.
Get-CimInstance Win32_PnPSignedDriver |
    Where-Object { $_.DeviceClass -in @("HDC", "SCSIAdapter") } |
    Select-Object DeviceName, DeviceID, DriverVersion, DriverDate, InfName, DriverProviderName |
    Out-File -Encoding UTF8 (Join-Path $backupDir "storage-drivers-before.txt")

try {
    Enable-ComputerRestore -Drive "C:\" -ErrorAction Stop
    Checkpoint-Computer -Description "PreBootFix-$timestamp" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
    Write-Log "System restore point created."
}
catch {
    Write-Log "Restore point not created: $($_.Exception.Message)"
}

# Backup BCD store.
Write-Log "Exporting BCD..."
bcdedit /export (Join-Path $backupDir "BCD.bak")
bcdedit /enum all > (Join-Path $backupDir "bcd-enum-before.txt")

# Backup EFI partition contents.
Write-Log "Backing up EFI partition..."
mountvol $espDrive /S | Out-Null
robocopy "$espDrive\EFI" (Join-Path $backupDir "EFI") /E /R:2 /W:1 /NFL /NDL /NP | Out-Null
mountvol $espDrive /D | Out-Null

# Ensure WinRE is enabled and collect state.
reagentc /info > (Join-Path $backupDir "reagent-before.txt")
try {
    reagentc /enable | Out-Null
}
catch {
    Write-Log "reagentc /enable returned: $($_.Exception.Message)"
}
reagentc /info > (Join-Path $backupDir "reagent-after.txt")

# Reduce recurrence risk: block driver updates through Windows Update quality updates.
Write-Log "Setting ExcludeWUDriversInQualityUpdate=1..."
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" `
    /v ExcludeWUDriversInQualityUpdate /t REG_DWORD /d 1 /f | Out-Null

if (-not $SkipDriverRollback) {
    Write-Log "Attempting rollback from Intel storage driver ($IntelInfName)..."
    pnputil /enum-devices /class HDC > (Join-Path $backupDir "hdc-before.txt")

    # Remove Intel HDC package so Windows can fall back to inbox AHCI.
    try {
        pnputil /delete-driver $IntelInfName /uninstall /force | Out-Null
        Write-Log "Deleted driver package $IntelInfName."
    }
    catch {
        Write-Log "Could not delete ${IntelInfName}: $($_.Exception.Message)"
    }

    if (Test-Path "$env:windir\INF\storahci.inf") {
        try {
            pnputil /add-driver "$env:windir\INF\storahci.inf" /install | Out-Null
            Write-Log "Installed storahci.inf."
        }
        catch {
            Write-Log "storahci install failed: $($_.Exception.Message)"
        }
    }

    pnputil /scan-devices | Out-Null
    pnputil /enum-devices /class HDC > (Join-Path $backupDir "hdc-after.txt")
}
else {
    Write-Log "Driver rollback skipped by switch."
}

if (-not $SkipBcdRebuild) {
    Write-Log "Rebuilding EFI boot files with bcdboot..."
    mountvol $espDrive /S | Out-Null
    bcdboot $systemWindows /s $espDrive /f UEFI | Out-Null
    bcdedit /enum firmware > (Join-Path $backupDir "bcd-firmware-after.txt")
    mountvol $espDrive /D | Out-Null
}
else {
    Write-Log "BCD rebuild skipped by switch."
}

# Create an offline repair helper for WinRE CMD.
$repairCmd = @'
@echo off
echo === BOOT REPAIR (UEFI) ===
diskpart /s "%~dp0mount-esp.txt"
bcdboot C:\Windows /s S: /f UEFI
bootrec /scanos
bootrec /rebuildbcd
echo Completed. Review output for errors.
pause
'@

$diskpartScript = @'
select disk 0
list part
select part 4
assign letter=S
exit
'@

Set-Content -Encoding ASCII -Path (Join-Path $backupDir "repair_boot_from_winre.cmd") -Value $repairCmd
Set-Content -Encoding ASCII -Path (Join-Path $backupDir "mount-esp.txt") -Value $diskpartScript

Write-Log "Done. Backup and remediation artifacts are in: $backupDir"
Write-Log "Recommended next step: restart the machine."
