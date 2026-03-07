# 🤖 Git AI Hooks - Setup Completo (0 a 100%)
# Este script prepara seu ambiente para usar mensagens de commit geradas por IA.

# Determina o BaseDir dinamicamente (Diretorio pai do script de setup)
$BaseDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Definition)
Set-Location $BaseDir

Write-Host "--- Iniciando Setup do Git AI Hooks ---" -ForegroundColor Cyan

# 1. Validação de Pré-requisitos
Write-Host "[1/4] Verificando pré-requisitos..." -ForegroundColor Yellow

if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "Git não encontrado. Por favor, instale o Git."
    exit 1
}

if (!(Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "AVISO: Node.js não encontrado. Necessário para alguns serviços de IA." -ForegroundColor DarkYellow
}

# 2. Instalação de CLIs de IA
Write-Host "[2/4] Configurando Motores de IA..." -ForegroundColor Yellow
$setupGemini = Join-Path $BaseDir "setup\Instalar-GeminiCLI.bat"
if (Test-Path $setupGemini) {
    Write-Host "Instalando Gemini CLI..."
    Start-Process cmd -ArgumentList "/c `"$setupGemini`"" -Wait
}

# 3. Configuração Inicial do settings.txt
Write-Host "[3/4] Validando configurações..." -ForegroundColor Yellow
$configPath = Join-Path $BaseDir "config\settings.txt"
if (!(Test-Path $configPath)) {
    $defaultConfig = @"
PROVIDER=Gemini
LANGUAGE=PT-BR
PROMPT_FILE=commit-msg.txt
INCLUDE_UNTRACKED=TRUE
INCLUDE_UNSTAGED=TRUE
CLEAR_LOG=True
LOG_PATH=C:\LOG-GitHooks\debug.log
"@
    Set-Content -Path $configPath -Value $defaultConfig
    Write-Host "Configuração inicial criada em $configPath"
}

# 4. Instalação do Native Git Hook
Write-Host "[4/4] Instalando Git Hook Nativo (prepare-commit-msg)..." -ForegroundColor Yellow

# Pergunta ao usuário o caminho do repositório ou busca o atual
$repoRoot = git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Repositório Git não detectado no diretório atual." -ForegroundColor Gray
    $repoPath = Read-Host "Insira o caminho completo do repositório Git onde deseja instalar o Hook"
}
else {
    $repoPath = $repoRoot
}

if (Test-Path "$repoPath\.git") {
    $hookSource = Join-Path $BaseDir "hooks\prepare-commit-msg"
    $hookDest = "$repoPath\.git\hooks\prepare-commit-msg"
    
    Copy-Item $hookSource $hookDest -Force
    Write-Host "Hook instalado com sucesso em $hookDest" -ForegroundColor Green
}
else {
    Write-Error "Caminho inválido ou não é um repositório Git: $repoPath"
}

Write-Host "`n--- Setup Concluído com Sucesso! ---" -ForegroundColor Cyan
Write-Host "Para TortoiseGit: Configure o 'Start Commit Hook' apontando para:"
Write-Host "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$BaseDir\actions\GenerateCommitMsg.ps1`"" -ForegroundColor Green
