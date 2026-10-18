# 🤖 Git AI Hooks - Setup Completo (instalar / desinstalar, idempotente)
# Uso: .\Install-All.ps1            -> instala (prepare-commit-msg e pre-push)
#      .\Install-All.ps1 -Uninstall -> remove os hooks deste repositorio
param([switch]$Uninstall)

# Determina o BaseDir dinamicamente (Diretorio pai do script de setup)
$BaseDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Definition)
Set-Location $BaseDir

# Marca usada para reconhecer um hook instalado por este projeto
$HookMarker = "Hook modular"
$Hooks = @("prepare-commit-msg", "pre-push")

# Repositorio alvo: o atual ou um informado pelo usuario
$repoRoot = git rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Repositório Git não detectado no diretório atual." -ForegroundColor Gray
    $repoPath = Read-Host "Insira o caminho completo do repositório Git onde deseja instalar o Hook"
}
else {
    $repoPath = $repoRoot
}

if (!(Test-Path "$repoPath\.git")) {
    Write-Error "Caminho inválido ou não é um repositório Git: $repoPath"
    exit 1
}

# ----- Desinstalacao -----
if ($Uninstall) {
    foreach ($hook in $Hooks) {
        $hookDest = Join-Path $repoPath ".git\hooks\$hook"
        if (!(Test-Path $hookDest)) { continue }
        if (-not (Select-String -Path $hookDest -Pattern $HookMarker -Quiet)) {
            Write-Warning "Hook $hook não foi instalado por este projeto. Não será removido."
            continue
        }
        Remove-Item $hookDest -Force
        Write-Host "Hook $hook removido de $hookDest" -ForegroundColor Green
    }
    exit 0
}

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

# 3. Configuração Inicial do settings.txt (a partir do modelo versionado)
Write-Host "[3/4] Validando configurações..." -ForegroundColor Yellow
$configPath = Join-Path $BaseDir "config\settings.txt"
$examplePath = Join-Path $BaseDir "config\settings.example.txt"
if (!(Test-Path $configPath)) {
    if (Test-Path $examplePath) {
        Copy-Item $examplePath $configPath
        Write-Host "Configuração inicial criada em $configPath"
    }
    else {
        Write-Host "AVISO: config\settings.example.txt não encontrado." -ForegroundColor DarkYellow
    }
}

# 4. Instalação dos Git Hooks (idempotente: sobrescreve apenas hooks deste projeto)
Write-Host "[4/4] Instalando Git Hooks (prepare-commit-msg e pre-push)..." -ForegroundColor Yellow

# Confere antes de gravar qualquer um, para nao instalar pela metade
foreach ($hook in $Hooks) {
    $hookDest = Join-Path $repoPath ".git\hooks\$hook"
    if ((Test-Path $hookDest) -and -not (Select-String -Path $hookDest -Pattern $HookMarker -Quiet)) {
        Write-Error "Já existe um hook $hook que não é deste projeto: $hookDest. Remova-o manualmente."
        exit 1
    }
}

foreach ($hook in $Hooks) {
    $hookDest = Join-Path $repoPath ".git\hooks\$hook"
    # O caminho do hub e gravado no hook (o hook copiado perde a referencia a sua pasta de origem)
    $hookContent = [System.IO.File]::ReadAllText((Join-Path $BaseDir "hooks\$hook"))
    $hookContent = $hookContent.Replace("__GITHOOKS_HOME__", ($BaseDir -replace '\\', '/'))
    $hookContent = $hookContent -replace "`r`n", "`n"
    [System.IO.File]::WriteAllText($hookDest, $hookContent, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host "Hook $hook instalado com sucesso em $hookDest" -ForegroundColor Green
}

Write-Host "`n--- Setup Concluído com Sucesso! ---" -ForegroundColor Cyan
Write-Host "Para TortoiseGit: Configure o 'Start Commit Hook' apontando para:"
Write-Host "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$BaseDir\actions\GenerateCommitMsg.ps1`"" -ForegroundColor Green
Write-Host "Revisão pre-push: defina CODE_REVIEW_ENABLED=TRUE em config\settings.txt para ativar." -ForegroundColor Gray
