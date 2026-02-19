# SKILL: windows-admin

## Dominio
Administración elevada de Windows: servicios, pagefile, Windows Update, BCD, EFI, drivers AHCI, WinRE, registro del sistema y operaciones `RunAs`.

---

## Scripts disponibles (en `.codex-agent/`)

| Script | Propósito | Riesgo |
|--------|-----------|--------|
| `windows_light_admin.ps1` | Optimizar SO: pagefile, servicios bloat, bloqueo de WU | `high` |
| `boot_remediation_admin.ps1` | Reparar BCD, drivers AHCI, respaldar EFI, habilitar WinRE | `high` |
| `run_windows_light_elevated.ps1` | Elevador genérico → llama a `windows_light_elevated_entry.ps1` | `high` |
| `windows_light_elevated_entry.ps1` | Entry point elevado que ejecuta `windows_light_admin.ps1` | `high` |

---

## Flujo de ejecución elevada

### Desde PowerShell (Windows)
```powershell
# Optimización de SO
Start-Process powershell.exe -Verb RunAs -Wait -ArgumentList `
  "-NoProfile -ExecutionPolicy Bypass -File `.codex-agent\windows_light_admin.ps1`"

# Remediación de boot
Start-Process powershell.exe -Verb RunAs -Wait -ArgumentList `
  "-NoProfile -ExecutionPolicy Bypass -File `.codex-agent\boot_remediation_admin.ps1`"
```

### Elevador wrapper
```powershell
# Desde directorio del workspace
powershell -ExecutionPolicy Bypass -File .codex-agent\run_windows_light_elevated.ps1
```

### Verificar ejecución exitosa
```powershell
# El script genera artefactos:
Test-Path ".codex-agent\windows_light_report.json"   # optimización
Test-Path "D:\BootRescue\win-light-*"                 # backup optimización
Test-Path "D:\BootRescue\boot-backup-*"               # backup boot
```

---

## Operaciones frecuentes

### Diagnóstico de servicios
```powershell
Get-Service wuauserv, bits, usosvc, WaaSMedicSvc, SysMain, DiagTrack |
  Select-Object Name, Status, StartType | Format-Table
```

### Estado de pagefile
```powershell
Get-CimInstance Win32_ComputerSystem | Select-Object AutomaticManagedPagefile
Get-CimInstance Win32_PageFileSetting | Select-Object Name, InitialSize, MaximumSize
```

### Diagnóstico de boot (requiere admin)
```powershell
bcdedit /enum firmware       # entradas EFI
bcdedit /enum all            # todas las entradas BCD
reagentc /info               # estado WinRE
```

### Driver de controladora SATA
```powershell
Get-PnpDevice -Class HDC | Select-Object FriendlyName, Status, DriverVersion
# El driver seguro es: "Standard SATA AHCI Controller" (mshdc.inf, Microsoft)
```

### Bloquear actualizaciones de drivers por WU
```powershell
# Verificar política actual
(Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -ErrorAction SilentlyContinue).ExcludeWUDriversInQualityUpdate
# Aplicar bloqueo (requiere admin)
Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" `
  -Name ExcludeWUDriversInQualityUpdate -Value 1 -Type DWord -Force
```

---

## Rutas de backup
- `D:\BootRescue\` → backups de boot, EFI, BCD, optimización
- `C:\BootRescue\` → fallback si D: no disponible
- **NUNCA eliminar** estos directorios.

---

## Política de riesgo
- Todas las operaciones de este skill son `risk: high`.
- Siempre registrar `requires_double_confirmation: true` en `.codex-agent/tasks.yaml`.
- Verificar existencia de artefacto de resultado tras ejecución elevada.
- Si el script falla silenciosamente (exit code ≠ 0 o sin artefactos), solicitar que el usuario ejecute manualmente desde PowerShell Administrador.
