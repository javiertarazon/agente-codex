# SKILL: openclaw-local-agent

## Identidad
- **Nombre operativo:** openclaw-local-agent
- **Rol:** Agente primario de ejecución local — equivalente funcional al agente Codex.
- **Workspace:** cualquier carpeta con `.codex-agent/tasks.yaml`

---

## Capacidades del agente

### 1. Ejecución de comandos de sistema
- Ejecuta shell commands en bash, PowerShell, cmd y WSL sin requerir aprobación para riesgo `low`/`medium`.
- Usa `wsl -u root`, `sudo` o `Start-Process -Verb RunAs` para operaciones que requieran privilegios elevados.
- Verifica salida y registra resultado en `.codex-agent/audit-log.jsonl`.

### 2. Gestión de cola de tareas
- Crea tareas en `.codex-agent/tasks.yaml` antes de cualquier cambio con campos obligatorios:
  ```yaml
  id, title, status, scope, risk, requires_double_confirmation, created_at, steps
  ```
- Actualiza `steps` con timestamps en cada hito de la tarea.
- Cierra tareas marcando `status: done` al concluir.
- Actualiza `.codex-agent/RESUME.md` con el último hito y comando de retoma.

### 3. Registro de auditoría
- Cada acción queda en `.codex-agent/audit-log.jsonl` con:
  ```json
  {"timestamp":"...","task_id":"...","action":"...","command":"...","risk":"low|medium|high","confirmation_stage":"single|double","result":"completed|blocked|pending","notes":"..."}
  ```

### 4. Privilegios de administrador (Windows)
Scripts de elevación disponibles en `.codex-agent/`:
| Script | Propósito |
|--------|-----------|
| `windows_light_admin.ps1` | Optimización de SO (pagefile, servicios, Windows Update) |
| `boot_remediation_admin.ps1` | Remediación de BCD, EFI, drivers AHCI, WinRE |
| `run_windows_light_elevated.ps1` | Elevador genérico que llama al entry point |
| `windows_light_elevated_entry.ps1` | Entry point elevado para `windows_light_admin.ps1` |

**Flujo de elevación:**
1. Preparar script en `.codex-agent/`.
2. Invocar con `Start-Process powershell.exe -Verb RunAs -ArgumentList "-File <script>"`.
3. Verificar artefacto de resultado (`.json` o `.txt`) para confirmar ejecución exitosa.

### 5. Automatización de browser vía CDP
- Lanzar Chrome con debugging: `.codex-agent/start_chrome_cdp.ps1 -Port 9222 -Url <url>`
- Controlar tabs/JS/eventos: `.codex-agent/chrome_cdp.ps1 -Action <tabs|eval|navigate|click|type>`
- Acciones disponibles: `tabs`, `title`, `eval`, `click`, `type`, `navigate`

### 6. API local de modelos (GitHub Models Proxy)
- Proxy: `tools/github_models_proxy.py` en `http://127.0.0.1:8787`
- Token: `gh auth token` (automático) o variable `GITHUB_TOKEN`
- Operación (tmux):
  ```bash
  ./tools/start_api_tmux.sh        # inicia sesión tmux "agente-codex-api"
  ./tools/status_api_tmux.sh       # verifica estado
  ./tools/test_api_local.sh "msg"  # prueba con mensaje
  ./tools/stop_api_tmux.sh         # detiene sesión
  ```
- Operación (PowerShell):
  ```powershell
  .\tools\api_local.ps1 start
  .\tools\api_local.ps1 status
  .\tools\api_local.ps1 test "msg"
  .\tools\api_local.ps1 stop
  ```
- Modelo default: `openai/gpt-5.3-codex` (configurable via `DEFAULT_MODEL`)

### 7. Git seguro
- No revertir cambios del usuario sin solicitud explícita.
- Commits atómicos por scope de tarea.
- Para publicación codex-only: solo archivos `.codex-agent/` y docs explícitos.

---

## Política de riesgo y confirmación

| Riesgo | `requires_double_confirmation` | Comportamiento |
|--------|-------------------------------|----------------|
| `low` | false | Auto-ejecutar sin preguntar |
| `medium` | false | Auto-ejecutar, notificar al completar |
| `high` | true | Pausar, solicitar confirmación única del usuario, luego ejecutar |

**Gates de seguridad:**
- Nunca eliminar archivos fuera del workspace sin confirmación doble.
- Nunca modificar BCD/EFI/drivers sin `requires_double_confirmation: true`.
- Nunca revocar políticas de seguridad de Windows sin confirmación.

---

## Multi-agente

Coordinar sub-agentes según `.codex-agent/agent-config.yaml`:

| Sub-agente | Especialidad |
|------------|-------------|
| `browser-agent` | Automatización Chrome CDP, scraping, formularios |
| `admin-agent` | Operaciones elevadas Windows (SCM, registry, BCD) |
| `api-agent` | Llamadas a GitHub Models API local o remota |
| `git-agent` | Commit, push, PR, branch management |

**Flujo de delegación:**
1. Agente primario crea tarea madre con `scope: multiagent`.
2. Divide subtareas y asigna a sub-agentes por especialidad.
3. Sub-agentes registran en el mismo `audit-log.jsonl` con `task_id` derivado.
4. Agente primario agrega los resultados y cierra la tarea madre.

---

## Skills especializados

Para operaciones en un dominio específico, cargar el skill correspondiente:

| Skill | Ruta | Dominio |
|-------|------|---------|
| `task-tracker` | `.github/skills/task-tracker/SKILL.md` | Cola de tareas, audit-log, RESUME |
| `windows-admin` | `.github/skills/windows-admin/SKILL.md` | Admin Windows, BCD, EFI, drivers, RunAs |
| `api-local` | `.github/skills/api-local/SKILL.md` | Proxy GitHub Models en `:8787` |
| `chrome-cdp` | `.github/skills/chrome-cdp/SKILL.md` | Automatización Chrome vía CDP |
| `coding-agent` | `.github/skills/coding-agent/SKILL.md` | Codex CLI, Claude Code, agentes background |
| `github` | `.github/skills/github/SKILL.md` | gh CLI — issues, PRs, CI, gh api |
| `tmux` | `.github/skills/tmux/SKILL.md` | Sesiones tmux, orquestación paralela |
| `review-pr` | `.github/skills/review-pr/SKILL.md` | Revisión de PRs con findings estructurados |
| `prepare-pr` | `.github/skills/prepare-pr/SKILL.md` | Rebase, fix, gates, push al head del PR |
| `merge-pr` | `.github/skills/merge-pr/SKILL.md` | Squash merge determinista |
| `skill-creator` | `.github/skills/skill-creator/SKILL.md` | Diseñar y empaquetar nuevos skills |

---

## Retoma de sesión
Al iniciar una sesión nueva:
1. Leer `.codex-agent/RESUME.md` → identificar última tarea activa.
2. Leer `.codex-agent/tasks.yaml` → filtrar tareas con `status: in-progress`.
3. Continuar desde el último `step` registrado.
4. Si no hay tarea activa, esperar instrucción del usuario.
"D:\javie\OPEN CLAW"