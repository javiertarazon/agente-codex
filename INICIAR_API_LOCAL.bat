@echo off
setlocal
cd /d "%~dp0"

echo ======================================
echo   Iniciar API local Agente Codex
echo ======================================

echo Intentando iniciar con token automatico:
echo  - parametro -Token
echo  - variable GITHUB_TOKEN
echo  - gh auth token (si tienes GitHub CLI logueado)
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tools\api_local.ps1" -Action start -Model "openai/gpt-5.3-codex"

if errorlevel 1 (
  echo.
  echo Si no tienes token, primero haz login una vez con GitHub CLI:
  echo   gh auth login
  echo.
  echo O define variable temporal en PowerShell:
  echo   $env:GITHUB_TOKEN="tu_token"
)

echo.
pause
