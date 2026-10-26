# 🔍 Diagnóstico de Ambiente - Git AI Hooks
# A raiz do hub e descoberta a partir da pasta diagnostics/ (funciona em qualquer drive)
$BaseDir = Split-Path -Parent $PSScriptRoot
. (Join-Path $BaseDir "lib\PathService.ps1")
. (Join-Path $BaseDir "lib\ConfigService.ps1")
. (Join-Path $BaseDir "lib\AIService.ps1")

Write-Host "--- Iniciando Validação Técnica ---" -ForegroundColor Cyan
Write-Host "Raiz do hub: $BaseDir" -ForegroundColor Gray

# 1. Teste de Configuração
$provider = Get-AppConfig "PROVIDER"
$promptFile = Get-AppConfig "PROMPT_FILE"
Write-Host "Configuração atual: Provider=$provider, Prompt=$promptFile"

# 2. Teste de Conectividade IA
Write-Host "Testando conexão com motor de IA ($provider)..." -ForegroundColor Yellow
try {
    $testPrompt = "Diga apenas 'OK' se estiver me ouvindo."
    $response = Get-AISuggestion -prompt $testPrompt -provider $provider
    if ($response -match "OK") {
        Write-Host "Conexão IA: SUCESSO" -ForegroundColor Green
    }
    else {
        Write-Host "IA respondeu, mas não o esperado: $response" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "ERRO de Conexão IA: $($_.Exception.Message)" -ForegroundColor Red
}

# 3. Verificação de Arquivos Críticos
$files = @(
    "actions\GenerateCommitMsg.ps1",
    "prompts\commit-msg.txt",
    "prompts\commit-msg-senior.txt",
    "lib\GitService.ps1",
    "lib\SecretFilter.ps1",
    "lib\CommitFormat.ps1",
    "config\settings.txt"
)

foreach ($f in $files) {
    $p = Join-Path $BaseDir $f
    if (Test-Path $p) {
        Write-Host "Arquivo OK: $f" -ForegroundColor Gray
    }
    else {
        Write-Host "ARQUIVO FALTANDO: $f" -ForegroundColor Red
    }
}

Write-Host "--- Validação Concluída ---" -ForegroundColor Cyan
