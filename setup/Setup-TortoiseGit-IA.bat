@echo off
title Setup Basico - Git AI Hooks (TortoiseGit)
setlocal enabledelayedexpansion

echo ======================================================
echo   SETUP BASICO - GIT AI HOOKS (TORTOISEGIT)
 echo ======================================================
echo.

:: 1. Verificar se o Node.js esta instalado
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo [1/3] Instalando Node.js via winget...
    winget install -e --id OpenJS.NodeJS --accept-package-agreements --accept-source-agreements
    if %errorlevel% neq 0 (
        echo [ERRO] Falha ao instalar Node.js. Instale manualmente em nodejs.org
        pause
        exit /b
    )
    echo [OK] Node.js instalado. Reinicie este script.
    pause
    exit /b
) else (
    echo [OK] Node.js detectado.
)

:: 2. Instalar o Gemini CLI
echo [2/3] Instalando @google/gemini-cli...
call npm install -g @google/gemini-cli
if %errorlevel% neq 0 (
    echo [ERRO] Falha ao instalar gemini-cli. Verifique permissoes.
    pause
    exit /b
)
echo [OK] Gemini CLI instalado.

:: 3. Determinar caminhos relativos
pushd "%~dp0.."
set "PROJECT_ROOT=%CD%"
popd

:: 3. Criar arquivo de settings padrao se nao existir
if not exist "%PROJECT_ROOT%\config\settings.txt" (
    echo [3/3] Criando settings.txt padrao...
    (
        echo PROVIDER=Gemini
        echo LANGUAGE=PT-BR
        echo PROMPT_FILE=commit-msg.txt
        echo INCLUDE_UNTRACKED=TRUE
        echo INCLUDE_UNSTAGED=TRUE
        echo CLEAR_LOG=True
        echo LOG_PATH=C:\LOG-GitHooks\debug.log
    ) > "%PROJECT_ROOT%\config\settings.txt"
) else (
    echo [OK] Arquivo de configuracao detectado.
)

echo.
echo ======================================================
echo   PROXIMOS PASSOS OBRIGATORIOS
echo ======================================================
echo.
echo 1. Autenticar na IA:
echo    Digite no terminal: gemini login
echo    (Pegue sua chave em https://aistudio.google.com/app/apikey)
echo.
echo 2. Configurar o TortoiseGit:
echo    Acesse: Settings -^> Hook Scripts -^> Add...
echo    Hook Type: Start Commit Hook
echo    Command Line:
echo    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PROJECT_ROOT%\actions\GenerateCommitMsg.ps1"
echo.
echo ======================================================
echo [FIM] Setup basico concluido!
pause
