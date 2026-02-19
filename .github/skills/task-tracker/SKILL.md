# SKILL: task-tracker

## Dominio
Gestión completa de la cola de tareas del workspace. Crear, actualizar, cerrar tareas en `.codex-agent/tasks.yaml` y registrar cada acción en `.codex-agent/audit-log.jsonl`. Mantener `.codex-agent/RESUME.md` actualizado para reanudación de sesión.

---

## Archivos del plano de control

| Archivo | Propósito |
|---------|-----------|
| `.codex-agent/tasks.yaml` | Cola de tareas con estado, riesgo y pasos |
| `.codex-agent/audit-log.jsonl` | Registro inmutable de cada acción ejecutada |
| `.codex-agent/RESUME.md` | Punto de reanudación para nueva sesión |
| `.codex-agent/agent-config.yaml` | Política de auto-ejecución y sub-agentes |

---

## Estructura de una tarea

```json
{
  "id": "task-YYYYMMDD-HHMMSS000",
  "title": "Descripción clara de la tarea",
  "status": "not-started | in-progress | done | blocked",
  "scope": "workspace | host | multiagent",
  "risk": "low | medium | high",
  "requires_double_confirmation": false,
  "created_at": "2026-02-19T00:00:00-04:00",
  "steps": [
    {
      "timestamp": "2026-02-19T00:00:00-04:00",
      "text": "descripción del hito"
    }
  ]
}
```

---

## Generar un ID de tarea

```bash
# Bash/WSL
echo "task-$(date +%Y%m%d-%H%M%S%3N)"

# PowerShell
"task-$(Get-Date -Format 'yyyyMMdd-HHmmssffff')"
```

---

## Flujo obligatorio en cada operación

### 1. Crear tarea
Antes de CUALQUIER cambio → agregar nueva entrada en `tasks.yaml` con `status: in-progress`.

### 2. Actualizar pasos
En cada hito significativo → agregar un objeto al array `steps` con timestamp ISO 8601.

### 3. Registrar en audit-log
```json
{
  "timestamp": "2026-02-19T00:00:00-04:00",
  "task_id": "task-20260219-000000000",
  "action": "nombre-descriptivo",
  "command": "comando o descripción de lo ejecutado",
  "risk": "low",
  "confirmation_stage": "single",
  "result": "completed",
  "notes": "detalles adicionales relevantes"
}
```

### 4. Cerrar tarea
Marcar `status: done` y actualizar `RESUME.md`.

---

## Política de auto-ejecución

| Risk | `requires_double_confirmation` | Acción |
|------|-------------------------------|--------|
| `low` | false | Ejecutar directamente |
| `medium` | false | Ejecutar, notificar al completar |
| `high` | true | Mostrar al usuario, pedir confirmación ÚNICA, luego ejecutar |

---

## Retoma de sesión

Al iniciar una nueva sesión:
```
1. Leer .codex-agent/RESUME.md
2. Filtrar tasks.yaml donde status == "in-progress"
3. Continuar desde el último step registrado
4. Si no hay in-progress, reportar al usuario
```

---

## Prompt de cola de tareas

Disponible en `.github/prompts/autorun-tasks.prompt.md`.

Uso en Copilot Chat:
```
/autorun-tasks
```
o bien:
```
Ejecuta la siguiente tarea pendiente.
```

---

## Comandos útiles de diagnóstico

```bash
# Ver tareas pendientes (bash/jq)
jq '.tasks[] | select(.status != "done")' .codex-agent/tasks.yaml

# Ver última línea del audit-log
tail -1 .codex-agent/audit-log.jsonl | python3 -m json.tool

# Contar tareas por estado
jq '.tasks | group_by(.status) | map({estado: .[0].status, total: length})' .codex-agent/tasks.yaml
```

```powershell
# Ver tareas no completadas (PowerShell)
$t = Get-Content .codex-agent\tasks.yaml | ConvertFrom-Json
$t.tasks | Where-Object { $_.status -ne "done" } | Format-Table id, title, status, risk
```

---

## Política de riesgo
- Crear/actualizar tareas: `risk: low`
- Cerrar tareas: `risk: low`
- Eliminar entradas del audit-log: **prohibido**
- Modificar `status` de tareas completadas: `risk: medium`, requiere justificación en `notes`
