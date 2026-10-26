# Revisao automatica de codigo antes do push (non-blocking: sempre exit 0)
# Uso: .\PerformCodeReview.ps1 [-Base origin/main]
# Ativacao: CODE_REVIEW_ENABLED=TRUE em config/settings.txt (padrao FALSE, pois envia o diff a IA externa)
param(
    [string]$Base = ""
)

$BaseDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Definition)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
# UTF-8 sem BOM: com BOM o CLI recebe bytes extras no inicio do prompt
$OutputEncoding = New-Object System.Text.UTF8Encoding($false)

. (Join-Path $BaseDir "lib\PathService.ps1")
. (Join-Path $BaseDir "lib\ConfigService.ps1")
. (Join-Path $BaseDir "lib\LogService.ps1")
. (Join-Path $BaseDir "lib\GitService.ps1")
. (Join-Path $BaseDir "lib\SecretFilter.ps1")
. (Join-Path $BaseDir "lib\AIService.ps1")

try {
    if ((Get-AppConfig "CODE_REVIEW_ENABLED") -ine "TRUE") {
        Write-Host "Revisão automática desativada (CODE_REVIEW_ENABLED=FALSE)." -ForegroundColor Gray
        exit 0
    }

    Write-Log "--- INICIO CODE REVIEW ---"

    if ([string]::IsNullOrWhiteSpace($Base)) { $Base = Get-GitDefaultBase }
    if ([string]::IsNullOrWhiteSpace($Base)) {
        Write-Host "Revisão ignorada: nenhuma branch base encontrada (origin/main ou origin/master)." -ForegroundColor Yellow
        Write-Log "AVISO: branch base nao encontrada."
        exit 0
    }

    $maxChars = [int](Get-AppConfig "MAX_DIFF_CHARS")
    if ($maxChars -le 0) { $maxChars = 80000 }

    $diff = Get-GitReviewDiff -Base $Base -MaxChars $maxChars
    if ($null -eq $diff) {
        Write-Host "Revisão ignorada: não foi possível calcular o merge-base com $Base." -ForegroundColor Yellow
        exit 0
    }
    if ([string]::IsNullOrWhiteSpace($diff)) {
        Write-Host "Revisão: nenhuma alteração em relação a $Base." -ForegroundColor Gray
        exit 0
    }
    Write-Log "INFO: Diff de revisao capturado ($($diff.Length) caracteres) contra $Base."

    $aiProvider = Get-AppConfig "PROVIDER"
    $branch = Get-GitBranch
    $promptPath = Join-Path $BaseDir "prompts\code-review.txt"
    $template = Get-Content $promptPath -Raw -Encoding UTF8
    $fullPrompt = $template.Replace("{{DIFF}}", $diff).Replace("{{BRANCH}}", $branch).Replace("{{AI_CLI}}", "$aiProvider-CLI")

    Write-Host "--- Revisão automática de código ($aiProvider, base: $Base) ---" -ForegroundColor Cyan
    $review = Get-AISuggestion -prompt $fullPrompt -provider $aiProvider

    if ([string]::IsNullOrWhiteSpace($review)) {
        Write-Host "A IA não retornou revisão." -ForegroundColor Yellow
        Write-Log "AVISO: revisao vazia."
    }
    else {
        Write-Host $review
        Write-Log "SUCESSO: revisao exibida."
    }
}
catch {
    Write-Host "Revisão ignorada por erro: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Log "ERRO CODE REVIEW: $($_.Exception.Message)"
}

Write-Log "--- FIM CODE REVIEW ---"
exit 0
