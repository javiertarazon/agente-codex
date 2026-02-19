@echo off
setlocal
cd /d "%~dp0"

echo ======================================
echo   Detener API local Agente Codex
echo ======================================

powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tools\api_local.ps1" -Action stop

echo.
pause
