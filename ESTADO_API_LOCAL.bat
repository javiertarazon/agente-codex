@echo off
setlocal
cd /d "%~dp0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tools\api_local.ps1" -Action status -Model "openai/gpt-5.3-codex"

echo.
pause
