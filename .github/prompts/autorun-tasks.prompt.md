---
mode: agent
description: >
  Ejecuta automáticamente la siguiente tarea pendiente en la cola de tareas
  de este workspace (tasks.yaml). Actúa como openclaw-local-agent con
  auto-ejecución según política de riesgo.
---

# Prompt: autorun-tasks

Lee `.codex-agent/tasks.yaml` y ejecuta la siguiente tarea con `status: in-progress` o la primera con `status: not-started`, siguiendo estas reglas:

## Pasos obligatorios

1. **Leer la cola**
   - Abrir `.codex-agent/tasks.yaml`.
   - Identificar tarea activa (`status: in-progress`) o primera pendiente (`status: not-started`).
   - Si no hay tareas pendientes, reportar al usuario y detener.

2. **Verificar riesgo**
   - `low` / `medium` → continuar directamente.
   - `high` con `requires_double_confirmation: true` → mostrar descripción de la tarea al usuario y pedir confirmación antes de proceder.

3. **Ejecutar la tarea**
   - Seguir los pasos definidos en el campo `steps` de la tarea.
   - Si la tarea no tiene pasos definidos, inferir los pasos necesarios a partir del `title`.
   - Actualizar `steps` con timestamps de progreso.

4. **Registrar en audit-log**
   - Por cada acción ejecutada, agregar una línea en `.codex-agent/audit-log.jsonl`:
     ```json
     {"timestamp":"<ISO8601>","task_id":"<id>","action":"<nombre>","command":"<cmd>","risk":"<nivel>","confirmation_stage":"single","result":"<completed|blocked>","notes":"<detalles>"}
     ```

5. **Cerrar la tarea**
   - Marcar `status: done` en `.codex-agent/tasks.yaml`.
   - Actualizar `.codex-agent/RESUME.md` con el último hito y el comando exacto para retomar.

6. **Reportar al usuario**
   - Mostrar resumen de lo ejecutado (tarea, pasos, resultado).
   - Si hay más tareas pendientes, preguntar si continuar o esperar.

## Uso típico
Escribe en el chat de Copilot:
```
/autorun-tasks
```
o simplemente:
```
Ejecuta la siguiente tarea pendiente.
```
