@echo off
title Diagnóstico de Hooks de IA - Joker1
SET SCRIPT_DIR=%~dp0
echo ======================================================
echo   VERIFICANDO AMBIENTE DE AUTOMACAO (GIT HOOKS IA)
echo ======================================================
echo.

:: Executa o PowerShell usando o caminho relativo ao .bat
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Expression (Get-Content '%SCRIPT_DIR%Test-AllProviders.ps1' -Raw)"

echo.
echo ======================================================
echo   Diagnostico Concluido. 
echo ======================================================
pause
