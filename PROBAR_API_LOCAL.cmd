@echo off
setlocal
cd /d "%~dp0"

set "PROMPT=%*"
if "%PROMPT%"=="" set "PROMPT=hola"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tools\api_local.ps1" -Action test -Prompt "%PROMPT%" -Model "openai/gpt-5.3-codex"

echo.
pause
