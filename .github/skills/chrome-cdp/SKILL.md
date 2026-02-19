# SKILL: chrome-cdp

## Dominio
Automatización de Google Chrome vía Chrome DevTools Protocol (CDP). Lanzar Chrome con depuración remota, controlar tabs, ejecutar JavaScript, navegar, hacer clic y escribir texto en páginas web.

---

## Scripts disponibles (en `.codex-agent/`)

| Script | Propósito |
|--------|-----------|
| `start_chrome_cdp.ps1` | Lanzar Chrome con `--remote-debugging-port` |
| `chrome_cdp.ps1` | Controlar Chrome: tabs, JS, eventos |

---

## Lanzar Chrome con CDP

```powershell
# Puerto por defecto: 9222
.\.codex-agent\start_chrome_cdp.ps1

# Puerto y URL personalizados
.\.codex-agent\start_chrome_cdp.ps1 -Port 9222 -Url "https://github.com"
```

**Perfil de usuario para CDP:** `D:\BootRescue\chrome-codex-profile`
(fallback: `C:\BootRescue\chrome-codex-profile`)

**Respuesta de éxito:**
```json
{"status":"ok","browser":"Chrome/...","protocol":"1.3","debug_port":9222}
```

---

## Acciones disponibles (`chrome_cdp.ps1`)

### Listar tabs abiertos
```powershell
.\.codex-agent\chrome_cdp.ps1 -Action tabs
```

### Obtener título del tab activo
```powershell
.\.codex-agent\chrome_cdp.ps1 -Action title -TabMatch "GitHub"
```

### Ejecutar JavaScript
```powershell
.\.codex-agent\chrome_cdp.ps1 -Action eval `
  -TabMatch "github.com" `
  -Expression "document.title"
```

### Navegar a una URL
```powershell
.\.codex-agent\chrome_cdp.ps1 -Action navigate `
  -TabMatch "GitHub" `
  -Url "https://github.com/javiertarazon/agente-codex"
```

### Hacer clic en elemento
```powershell
.\.codex-agent\chrome_cdp.ps1 -Action click `
  -TabMatch "GitHub" `
  -Selector "#submit-button"
```

### Escribir texto en campo
```powershell
.\.codex-agent\chrome_cdp.ps1 -Action type `
  -TabMatch "GitHub" `
  -Selector "input[name='q']" `
  -Text "openclaw agent"
```

---

## Parámetros comunes

| Parámetro | Tipo | Default | Descripción |
|-----------|------|---------|-------------|
| `-Action` | string | `tabs` | Acción a ejecutar |
| `-Port` | int | `9222` | Puerto CDP de Chrome |
| `-TabMatch` | string | — | Regex para filtrar tab por título o URL |
| `-Expression` | string | — | Código JS para `-Action eval` |
| `-Selector` | string | — | Selector CSS para click/type |
| `-Text` | string | — | Texto para `-Action type` |
| `-Url` | string | — | URL para `-Action navigate` |

---

## Flujo típico de automatización

```powershell
# 1. Lanzar Chrome con CDP
.\.codex-agent\start_chrome_cdp.ps1 -Port 9222 -Url "https://example.com"

# 2. Verificar que Chrome está disponible
$tabs = .\.codex-agent\chrome_cdp.ps1 -Action tabs
$tabs | ConvertFrom-Json

# 3. Navegar y manipular
.\.codex-agent\chrome_cdp.ps1 -Action navigate -Url "https://target.com"
.\.codex-agent\chrome_cdp.ps1 -Action click -Selector "#login-btn"
.\.codex-agent\chrome_cdp.ps1 -Action type -Selector "#username" -Text "javie"

# 4. Extraer datos con JS
$result = .\.codex-agent\chrome_cdp.ps1 -Action eval `
  -Expression "JSON.stringify(Array.from(document.querySelectorAll('h1')).map(e=>e.textContent))"
```

---

## Diagnóstico

| Síntoma | Causa | Solución |
|---------|-------|----------|
| `Connection refused :9222` | Chrome no iniciado | Ejecutar `start_chrome_cdp.ps1` |
| `No page tabs found` | Solo tabs de extensiones | Abrir una URL normal en Chrome |
| `No tab matched pattern` | Regex sin coincidencia | Verificar con `-Action tabs` primero |
| Chrome no instalado | Path no encontrado | Verificar `C:\Program Files\Google\Chrome\Application\chrome.exe` |

---

## Política de riesgo
- Lanzar Chrome: `risk: low`
- Navegación y lectura de datos: `risk: low`
- Rellenar formularios / hacer clic: `risk: medium`
- Ejecutar JS arbitrario en páginas autenticadas: `risk: high`
