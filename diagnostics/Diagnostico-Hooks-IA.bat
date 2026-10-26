@echo off
title Diagnóstico de Hooks de IA - Joker1
SET SCRIPT_DIR=%~dp0
echo ======================================================
echo   VERIFICANDO AMBIENTE DE AUTOMACAO (GIT HOOKS IA)
echo ======================================================
echo.

:: Executa o PowerShell usando o caminho relativo ao .bat
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Test-AllProviders.ps1"

echo.
echo ======================================================
echo   Diagnostico Concluido. 
echo ======================================================
pause
