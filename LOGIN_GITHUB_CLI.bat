@echo off
setlocal
cd /d "%~dp0"

echo ======================================
echo   Login GitHub CLI (1 sola vez)
echo ======================================

where gh >nul 2>nul
if errorlevel 1 goto :NO_GH

gh auth login
if errorlevel 1 goto :END

echo.
gh auth status
goto :END

:NO_GH
echo No se encontro gh.
echo Instala GitHub CLI desde: https://cli.github.com/
echo Luego ejecuta este archivo otra vez.

:END
echo.
pause
