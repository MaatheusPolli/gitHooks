@echo off
title Instalador Gemini CLI - Git AI Hooks
setlocal

echo ======================================================
echo   INSTALADOR AUTOMATIZADO: GEMINI CLI + AMBIENTE
echo ======================================================
echo.

:: 1. Verificar se o Node.js esta instalado
node -v >nul 2>&1
if %errorlevel% neq 0 (
    echo [INFO] Node.js nao encontrado.
    echo [INFO] Tentando instalacao automatica via Windows Winget...
    winget install -e --id OpenJS.NodeJS
    if %errorlevel% neq 0 (
        echo [ERRO] Nao foi possivel instalar o Node.js automaticamente.
        echo [!] Por favor, instale manualmente em: https://nodejs.org/
        echo [!] Apos instalar, execute este arquivo novamente.
        pause
        exit /b
    )
    echo [SUCESSO] Node.js instalado! 
    echo [AVISO] Voce precisa REINICIAR este terminal ou o Windows para o 'npm' funcionar.
    echo [AVISO] Apos reiniciar, execute este instalador novamente para concluir.
    pause
    exit /b
) else (
    echo [OK] Node.js detectado: 
    node -v
)

:: 2. Instalar o Gemini CLI globalmente
echo.
echo [INFO] Instalando @google/gemini-cli via npm...
call npm install -g @google/gemini-cli
if %errorlevel% neq 0 (
    echo [ERRO] Falha ao instalar o pacote gemini-cli.
    echo [!] Verifique sua conexao com a internet ou permissoes de Administrador.
    pause
    exit /b
)
echo [OK] Gemini CLI instalado com sucesso!

:: 3. Instrucoes de Credenciais
echo.
echo ======================================================
echo   PASSO FINAL: CONFIGURAR CREDENCIAIS
echo ======================================================
echo Para que a IA funcione, voce precisa de uma API KEY:
echo.
echo 1. Acesse: https://aistudio.google.com/app/apikey (Gratuito)
echo 2. Crie uma "API Key in new project".
echo 3. Volte aqui no terminal e digite o comando:
echo.
echo    gemini login
echo.
echo 4. Cole sua chave quando solicitado.
echo ======================================================
echo.
echo [PRONTO] Ambiente configurado. Voce ja pode usar os Hooks!
pause