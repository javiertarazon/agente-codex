# SKILL: api-local

## Dominio
Gestión del proxy local de GitHub Models (`tools/github_models_proxy.py`) que expone los modelos de GitHub en `http://127.0.0.1:8787`. Incluye arranque, parada, estado, pruebas y configuración del modelo.

---

## Endpoint
```
http://127.0.0.1:8787/chat          POST — completions
http://127.0.0.1:8787/health        GET  — estado del servidor
```

## Modelo por defecto
```
openai/gpt-5.3-codex
```
Configurable con la variable `DEFAULT_MODEL` en `tools/github_models_proxy.py`.

---

## Scripts de operación

### Linux / WSL (tmux)
```bash
./tools/start_api_tmux.sh           # inicia sesión tmux "agente-codex-api"
./tools/status_api_tmux.sh          # verifica si la sesión está activa
./tools/test_api_local.sh "mensaje" # envía un mensaje de prueba
./tools/stop_api_tmux.sh            # mata la sesión tmux
```

### Windows (PowerShell)
```powershell
.\tools\api_local.ps1 start         # inicia el proxy
.\tools\api_local.ps1 status        # verifica estado
.\tools\api_local.ps1 test "msg"    # prueba con mensaje
.\tools\api_local.ps1 stop          # detiene el proxy
.\tools\api_local.ps1 restart       # reinicia
```

### Windows (doble clic)
```
INICIAR_API_LOCAL.bat / .cmd
ESTADO_API_LOCAL.bat  / .cmd
PROBAR_API_LOCAL.bat  / .cmd
DETENER_API_LOCAL.bat / .cmd
```

---

## Autenticación

### Automática (recomendada)
Requiere `gh` (GitHub CLI) autenticado:
```bash
gh auth login          # una sola vez
gh auth token          # verifica que devuelve token
```

### Manual
```bash
export GITHUB_TOKEN="ghp_..."          # Linux/WSL
$env:GITHUB_TOKEN = "ghp_..."          # PowerShell
```

### Login inicial GitHub CLI
```
LOGIN_GITHUB_CLI.bat / .cmd           # abre flujo de autenticación
```

---

## Formato de petición
```json
POST http://127.0.0.1:8787/chat
Content-Type: application/json

{
  "message": "explica este código",
  "model": "openai/gpt-5.3-codex"   // opcional, usa DEFAULT_MODEL si omite
}
```

## Formato de respuesta
```json
{
  "response": "...",
  "model": "openai/gpt-5.3-codex",
  "tokens_used": 123
}
```

---

## Diagnóstico de problemas

| Síntoma | Causa probable | Solución |
|---------|---------------|----------|
| `Connection refused` | Proxy no iniciado | `./tools/start_api_tmux.sh` |
| `401 Unauthorized` | Token inválido o ausente | `gh auth login` |
| `404 model not found` | Modelo no disponible en GitHub Models | Cambiar a `openai/gpt-4o` |
| Sesión tmux perdida | Sistema reiniciado | `./tools/start_api_tmux.sh` |

---

## Modelo alternativo recomendado
Si `gpt-5.3-codex` no está disponible:
```python
# en tools/github_models_proxy.py
DEFAULT_MODEL = "openai/gpt-4o"
```

---

## Política de riesgo
- Arranque/parada del proxy: `risk: low`
- Cambio de modelo por defecto: `risk: low`
- Exposición del token: `risk: high` — **nunca incluir en commits**
