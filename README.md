# Agente Codex v1.1

Repositorio limpio del sistema **Agente Codex**.

Incluye:
- `.codex-agent/` scripts, tareas y bitácora del agente.
- `.github/copilot-instructions.md`.
- `.codex-agent/global/model_instructions_global.md` para comportamiento global.
- `.codex-agent/global/init_workspace_codex_agent.sh` para inicializar carpetas nuevas.

No incluye archivos ni componentes del bot trader.

## Activacion global en Codex

1. Copiar instrucciones globales:
```bash
cp .codex-agent/global/model_instructions_global.md /home/javie/.codex/model_instructions_global.md
```

2. Definir en `~/.codex/config.toml`:
```toml
model_instructions_file = "/home/javie/.codex/model_instructions_global.md"
```

3. Preparar base global reutilizable:
```bash
mkdir -p /home/javie/.codex/agent-global
cp .codex-agent/start_chrome_cdp.ps1 /home/javie/.codex/agent-global/
cp .codex-agent/chrome_cdp.ps1 /home/javie/.codex/agent-global/
cp .codex-agent/global/init_workspace_codex_agent.sh /home/javie/.codex/agent-global/
chmod +x /home/javie/.codex/agent-global/init_workspace_codex_agent.sh
```

4. Inicializar cualquier carpeta nueva:
```bash
/home/javie/.codex/agent-global/init_workspace_codex_agent.sh <ruta_workspace>
```


## Registro de tareas y retoma

Para continuar exactamente donde se quedó el agente:

- Estado rápido: `.codex-agent/RESUME.md`
- Ledger de tareas: `.codex-agent/tasks.yaml`
- Auditoría de acciones: `.codex-agent/audit-log.jsonl`

Comando de retoma:
```bash
cd "/mnt/d/javie/agente codex/proyecto agente codex"
```

## Uso de tu cuenta GitHub/Copilot vía API local

Se incluye un proxy local:

- `tools/github_models_proxy.py`

Arranque (recomendado, en tmux):
```bash
cd "/mnt/d/javie/agente codex/proyecto agente codex"
GITHUB_TOKEN="<tu_token_github>" ./tools/start_api_tmux.sh
```

Ver estado / logs:
```bash
./tools/status_api_tmux.sh
```

Probar endpoint:
```bash
./tools/test_api_local.sh "Hola, dame un plan de refactor"
```

Detener:
```bash
./tools/stop_api_tmux.sh
```

Arranque manual (sin tmux):
```bash
export GITHUB_TOKEN="<tu_token_github>"
python3 tools/github_models_proxy.py
```


### Windows PowerShell (un solo script)

```powershell
Set-Location "D:\javie\agente codex\proyecto agente codex"

# iniciar (token automático: parametro -> GITHUB_TOKEN -> gh auth token)
.\tools\api_local.ps1 -Action start

# estado
.\tools\api_local.ps1 -Action status

# probar
.\tools\api_local.ps1 -Action test -Prompt "hola"

# detener
.\tools\api_local.ps1 -Action stop
```


### Doble clic (.bat)

En la raíz del repo tienes:

- `INICIAR_API_LOCAL.bat`
- `LOGIN_GITHUB_CLI.bat`
- `ESTADO_API_LOCAL.bat`
- `PROBAR_API_LOCAL.bat`
- `DETENER_API_LOCAL.bat`

Uso recomendado:
1. (Opcional, 1 sola vez) Doble clic en `LOGIN_GITHUB_CLI.bat` para iniciar sesión de GitHub CLI.
2. Doble clic en `INICIAR_API_LOCAL.bat` (toma token automático).
3. Doble clic en `PROBAR_API_LOCAL.bat`.
4. Doble clic en `DETENER_API_LOCAL.bat` cuando termines.


> Si no detecta token automático, ejecuta una vez: `gh auth login`


Nota: también se incluyen versiones `.cmd` de los lanzadores por compatibilidad Windows (`INICIAR_API_LOCAL.cmd`, etc.).
