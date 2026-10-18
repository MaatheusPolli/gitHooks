Write-Host "--- Iniciando Diagnóstico de Provedores de IA (Modo Portável) ---" -ForegroundColor Cyan

# 1. Descobre a raiz do projeto (Hub de Hooks) baseado na pasta diagnostics/
$BaseDir = Split-Path -Parent $PSScriptRoot

# 2. Importa o Core dinamicamente (AIService é um .ps1 com dot-source dos provedores)
. (Join-Path $BaseDir "lib\AIService.ps1")

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
