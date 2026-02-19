param(
    [ValidateSet("start", "status", "test", "stop", "restart")]
    [string]$Action = "status",
    [string]$Token,
    [string]$Model = "openai/gpt-5.3-codex",
    [string]$Host = "127.0.0.1",
    [int]$Port = 8787,
    [string]$Prompt = "hola"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoDir = Split-Path -Parent $scriptDir
$proxyScript = Join-Path $scriptDir "github_models_proxy.py"
$stateDir = Join-Path $repoDir ".codex-agent"
$pidFile = Join-Path $stateDir "api-local-proxy.pid"

if (-not (Test-Path $proxyScript)) {
    throw "No existe el proxy: $proxyScript"
}
if (-not (Test-Path $stateDir)) {
    New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
}

function Get-ProxyProcess {
    if (-not (Test-Path $pidFile)) { return $null }
    $pid = (Get-Content $pidFile -Raw).Trim()
    if ([string]::IsNullOrWhiteSpace($pid)) { return $null }
    try {
        return (Get-Process -Id ([int]$pid) -ErrorAction Stop)
    } catch {
        return $null
    }
}

function Resolve-GitHubToken {
    param([string]$ProvidedToken)

    if (-not [string]::IsNullOrWhiteSpace($ProvidedToken)) {
        return $ProvidedToken.Trim()
    }

    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_TOKEN)) {
        return $env:GITHUB_TOKEN.Trim()
    }

    $gh = Get-Command gh -ErrorAction SilentlyContinue
    if ($gh) {
        try {
            $ghToken = (& gh auth token 2>$null)
            if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($ghToken)) {
                return $ghToken.Trim()
            }
        } catch {
            # continue
        }
    }

    return $null
}

function Test-ProxyEndpoint {
    param([switch]$Silent)
    try {
        $payload = @{ prompt = "ping" } | ConvertTo-Json -Compress
        $null = Invoke-RestMethod -Uri "http://$Host`:$Port/chat" -Method POST -ContentType "application/json" -Body $payload -TimeoutSec 15
        return $true
    } catch {
        if (-not $Silent) {
            Write-Host "Endpoint no responde o devolvió error: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        return $false
    }
}

switch ($Action) {
    "start" {
        $running = Get-ProxyProcess
        if ($running) {
            Write-Host "Ya está corriendo (PID=$($running.Id))." -ForegroundColor Yellow
            Write-Host "URL: http://$Host`:$Port/chat"
            exit 0
        }

        $Token = Resolve-GitHubToken -ProvidedToken $Token
        if ([string]::IsNullOrWhiteSpace($Token)) {
            throw @"
No pude obtener token automáticamente.
Opciones:
1) Inicia sesión con GitHub CLI (recomendado, 1 sola vez): gh auth login
2) Define en PowerShell: `$env:GITHUB_TOKEN="tu_token"
3) Pásalo directo: .\tools\api_local.ps1 -Action start -Token "tu_token"
"@
        }

        $env:GITHUB_TOKEN = $Token
        $env:MODEL = $Model
        $env:HOST = $Host
        $env:PORT = "$Port"

        $proc = Start-Process -FilePath "python" -ArgumentList "`"$proxyScript`"" -WorkingDirectory $repoDir -WindowStyle Hidden -PassThru
        Start-Sleep -Seconds 1

        if ($proc.HasExited) {
            throw "El proceso del proxy terminó al iniciar (ExitCode=$($proc.ExitCode))."
        }

        Set-Content -Path $pidFile -Value $proc.Id -Encoding ascii

        Write-Host "OK: API iniciada (PID=$($proc.Id))" -ForegroundColor Green
        Write-Host "URL: http://$Host`:$Port/chat"
        Write-Host "Modelo por defecto: $Model"
        Write-Host "Siguiente: .\tools\api_local.ps1 -Action test -Prompt \"hola\""
    }

    "status" {
        $running = Get-ProxyProcess
        if ($running) {
            Write-Host "RUNNING: PID=$($running.Id)" -ForegroundColor Green
            Write-Host "URL: http://$Host`:$Port/chat"
            $ok = Test-ProxyEndpoint -Silent
            if ($ok) { Write-Host "Endpoint: responde" -ForegroundColor Green }
            else { Write-Host "Endpoint: no responde o error (token/modelo/limites)." -ForegroundColor Yellow }
        } else {
            Write-Host "STOPPED" -ForegroundColor Yellow
        }
    }

    "test" {
        $payload = @{ prompt = $Prompt } | ConvertTo-Json -Compress
        $r = Invoke-RestMethod -Uri "http://$Host`:$Port/chat" -Method POST -ContentType "application/json" -Body $payload -TimeoutSec 60
        $r | ConvertTo-Json -Depth 12
    }

    "stop" {
        $running = Get-ProxyProcess
        if ($running) {
            Stop-Process -Id $running.Id -Force
            Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
            Write-Host "OK: API detenida (PID=$($running.Id))" -ForegroundColor Green
        } else {
            Write-Host "INFO: ya estaba detenida" -ForegroundColor Yellow
            Remove-Item $pidFile -Force -ErrorAction SilentlyContinue
        }
    }

    "restart" {
        & $MyInvocation.MyCommand.Path -Action stop -Host $Host -Port $Port | Out-Null
        & $MyInvocation.MyCommand.Path -Action start -Token $Token -Model $Model -Host $Host -Port $Port
    }
}
