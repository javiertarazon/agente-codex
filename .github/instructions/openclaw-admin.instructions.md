---
applyTo: "**"
---

# Instrucciones de privilegios administrador — openclaw-local-agent

## Alcance
Estas instrucciones aplican a **todos los archivos y operaciones** del workspace cuando el agente actúa en modo `openclaw-local-agent`.

## Privilegios habilitados

### SO y procesos
- Ejecutar comandos bash/PowerShell/cmd con salida completa.
- Matar, iniciar y reiniciar servicios del sistema.
- Leer y escribir en rutas del sistema (`/etc`, `HKLM\`, `C:\Windows\`, etc.) cuando sea necesario.
- Emitir `sudo`, `wsl -u root` o `Start-Process -Verb RunAs` para operaciones elevadas.

### Git
- `git add`, `commit`, `push`, `pull`, `reset` — sin pedir permiso adicional del usuario.
- Crear y eliminar ramas locales y remotas cuando el scope de la tarea lo requiera.
- Nunca forzar push a `main`/`master` sin confirmación explícita del usuario.

### Sistema de archivos
- Crear, mover, renombrar y eliminar archivos **dentro del workspace** sin confirmación.
- Para eliminación fuera del workspace: registrar como `high-risk` y solicitar confirmación.

### Automatización Windows (scripts disponibles en `.codex-agent/`)
| Script | Privilegio |
|--------|-----------|
| `windows_light_admin.ps1` | Gestión pagefile, servicios, Update |
| `boot_remediation_admin.ps1` | BCD, EFI, drivers, WinRE |
| `run_windows_light_elevated.ps1` | Elevador genérico |
| `start_chrome_cdp.ps1` | Lanzar Chrome con CDP |
| `chrome_cdp.ps1` | Control de tabs y JS |

### API local
- Iniciar/detener proxy `tools/github_models_proxy.py` vía tmux o PowerShell.
- Usar `gh auth token` como fuente de token automática.

## Restricciones de seguridad (nunca omitir)
1. Nunca modificar BCD, EFI ni drivers sin `requires_double_confirmation: true`.
2. Nunca eliminar backups en `D:\BootRescue` o `C:\BootRescue`.
3. Nunca revocar políticas de seguridad de Windows Update sin confirmación.
4. Nunca hacer commit de tokens o credenciales en texto plano.
5. Nunca publicar en git archivos fuera del scope `.codex-agent/` sin aprobación.
