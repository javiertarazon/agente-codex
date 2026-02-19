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
