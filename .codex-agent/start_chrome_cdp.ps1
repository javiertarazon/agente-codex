[CmdletBinding()]
param(
    [int]$Port = 9222,
    [string]$Url = "https://github.com"
)

$ErrorActionPreference = "Stop"

$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if (-not (Test-Path $chrome)) {
    throw "Chrome not found at: $chrome"
}

$profileDir = "D:\BootRescue\chrome-codex-profile"
if (-not (Test-Path "D:\")) {
    $profileDir = "C:\BootRescue\chrome-codex-profile"
}

New-Item -ItemType Directory -Force -Path $profileDir | Out-Null

Start-Process -FilePath $chrome -ArgumentList @(
    "--remote-debugging-port=$Port",
    "--user-data-dir=$profileDir",
    $Url
) | Out-Null

Start-Sleep -Milliseconds 700

$ver = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/json/version" -ErrorAction Stop
[ordered]@{
    status = "ok"
    browser = $ver.Browser
    protocol = $ver."Protocol-Version"
    debug_port = $Port
} | ConvertTo-Json -Compress
