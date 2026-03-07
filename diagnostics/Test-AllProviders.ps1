Write-Host "--- Iniciando Diagnóstico de Provedores de IA (Modo Portável) ---" -ForegroundColor Cyan

# 1. Descobre a raiz do projeto (Hub de Hooks) baseado na pasta diagnostics/
$BaseDir = Split-Path -Parent $PSScriptRoot
$AiServicePath = Join-Path $BaseDir "lib\AIService.psm1"

# 2. Importa o Core dinamicamente
Import-Module $AiServicePath -Force

$providers = @("Gemini", "Claude", "Copilot")
$testPrompt = "Diga apenas a palavra 'OK' se você estiver funcionando."

foreach ($p in $providers) {
    Write-Host "Testando Provedor: $p..." -NoNewline -ForegroundColor White
    try {
        $result = Get-AISuggestion -prompt $testPrompt -provider $p
        if (![string]::IsNullOrWhiteSpace($result)) {
            Write-Host " [SUCESSO]" -ForegroundColor Green
            Write-Host " Resposta: $result" -ForegroundColor Gray
        } else {
            Write-Host " [AVISO] Resposta vazia." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host " [FALHA]" -ForegroundColor Red
        Write-Host " Erro: $($_.Exception.Message)" -ForegroundColor DarkGray
    }
}
Write-Host "--- Fim do Diagnóstico ---" -ForegroundColor Cyan
